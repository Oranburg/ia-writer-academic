// render.swift — headless render test for an .iatemplate bundle.
//
// Loads the bundle's own document.html from inside the bundle (so every
// relative path is resolved exactly as iA Writer resolves it), injects an
// HTML fragment the way iA Writer's Template.js does (innerHTML on
// [data-document], class list on <html>, then an "ia-writer-change"
// event), and writes:
//
//   <out>/screen-light.png, screen-dark.png   Preview approximations
//   <out>/document.pdf                         WebKit print of the body,
//                                              top/bottom margins from
//                                              IATemplateHeaderHeight/
//                                              IATemplateFooterHeight
//   <out>/composed.pdf                         title page + body pages with
//                                              header.html and footer.html
//                                              drawn into their bands
//   <out>/page-N.png                           first pages of composed.pdf
//   <out>/report.txt                           fonts, JS results, geometry
//
// This imitates iA Writer; it is not iA Writer. iA's compositing of the
// header, footer and title pages is not public, so composed.pdf is a
// model of it, not a proof.
//
// Usage:
//   SDKROOT=<matching SDK> swift tools/render.swift <bundle> <fragment.html> <outdir> [paperW paperH]
//   (paper size in points; default 612 792 = US Letter)

import Cocoa
import PDFKit
import WebKit

let args = CommandLine.arguments
guard args.count >= 4 else {
    FileHandle.standardError.write("usage: render.swift <bundle> <fragment.html> <outdir> [paperW paperH]\n".data(using: .utf8)!)
    exit(2)
}
let bundle = URL(fileURLWithPath: args[1])
let fragment = try! String(contentsOf: URL(fileURLWithPath: args[2]), encoding: .utf8)
let outDir = URL(fileURLWithPath: args[3])
let paper = NSSize(width: args.count > 5 ? Double(args[4])! : 612, height: args.count > 5 ? Double(args[5])! : 792)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let res = bundle.appendingPathComponent("Contents/Resources")
let info = NSDictionary(contentsOf: bundle.appendingPathComponent("Contents/Info.plist")) as! [String: Any]
let headerH = CGFloat((info["IATemplateHeaderHeight"] as? NSNumber)?.doubleValue ?? 0)
let footerH = CGFloat((info["IATemplateFooterHeight"] as? NSNumber)?.doubleValue ?? 0)
let titleUsesBands = (info["IATemplateTitleUsesHeaderAndFooterHeight"] as? NSNumber)?.boolValue ?? true
func page(_ key: String) -> URL? {
    guard let n = info[key] as? String else { return nil }
    return res.appendingPathComponent(n + ".html")
}

// Document identity for the running head, foot and title page. iA Writer
// takes these from the document; the harness takes them from the
// environment so a real document renders with its own title and date.
let env = ProcessInfo.processInfo.environment
let docTitle  = env["DOC_TITLE"]  ?? "A Synthetic Test Article"
let docAuthor = env["DOC_AUTHOR"] ?? "Test Author"
let docDate   = env["DOC_DATE"]   ?? "September 2026"

var report = ""
func log(_ s: String) { report += s + "\n"; print(s) }
let pxPerPt: CGFloat = 96.0 / 72.0

func jsString(_ s: String) -> String {
    let data = try! JSONSerialization.data(withJSONObject: [s], options: [])
    let arr = String(data: data, encoding: .utf8)!
    return String(arr.dropFirst().dropLast())
}

final class Loader: NSObject, WKNavigationDelegate {
    var cont: CheckedContinuation<Void, Never>?
    func webView(_ w: WKWebView, didFinish n: WKNavigation!) { cont?.resume(); cont = nil }
    func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { log("LOAD FAIL \(e)"); cont?.resume(); cont = nil }
    func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { log("LOAD FAIL \(e)"); cont?.resume(); cont = nil }
}

@MainActor
final class Page {
    let web: WKWebView
    let window: NSWindow
    let loader = Loader()
    init(width: CGFloat, height: CGFloat) {
        let cfg = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        ucc.addUserScript(WKUserScript(source: """
            window.__errors = [];
            window.addEventListener('error', function(e){ window.__errors.push(String(e.message)); });
            """, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        cfg.userContentController = ucc
        web = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height), configuration: cfg)
        window = NSWindow(contentRect: NSRect(x: -10000, y: 0, width: width, height: height),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = web
        web.navigationDelegate = loader
    }
    func load(_ url: URL) async {
        await withCheckedContinuation { c in
            loader.cont = c
            web.loadFileURL(url, allowingReadAccessTo: res)
        }
        _ = try? await web.evaluateJavaScript("document.fonts ? document.fonts.ready.then(()=>true) : true")
    }
    @discardableResult
    func js(_ s: String) async -> Any? {
        do { return try await web.evaluateJavaScript(s) } catch { log("JS ERROR \(error)"); return nil }
    }
    // What iA Writer's Template.js does
    func fill(classes: [String], data: [String: String]) async {
        var s = "document.documentElement.className = \(jsString(classes.joined(separator: " ")));\n"
        for (k, v) in data {
            s += """
            document.querySelectorAll('[data-\(k)]').forEach(function(el){
              el.innerHTML = \(jsString(v));
              el.dispatchEvent(new Event('ia-writer-change'));
            });\n
            """
        }
        await js(s + "true")
        try? await Task.sleep(nanoseconds: 150_000_000)
    }
    func snapshot(_ url: URL, height: CGFloat) async {
        let h = await js("document.documentElement.scrollHeight") as? Double ?? Double(height)
        web.setFrameSize(NSSize(width: web.frame.width, height: min(CGFloat(h), height)))
        let cfg = WKSnapshotConfiguration()
        if let img = try? await web.takeSnapshot(configuration: cfg),
           let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
        }
    }
    func pdfOfView() async -> PDFDocument? {
        let cfg = WKPDFConfiguration()
        cfg.rect = web.bounds
        guard let data = try? await web.pdf(configuration: cfg) else { return nil }
        return PDFDocument(data: data)
    }
}

final class PrintDone: NSObject {
    var cont: CheckedContinuation<Void, Never>?
    @objc func done(_ op: NSPrintOperation, success: Bool, ctx: UnsafeMutableRawPointer?) { cont?.resume(); cont = nil }
}

@MainActor
func run() async {
    log("bundle: \(bundle.lastPathComponent)  paper: \(paper.width)x\(paper.height)pt  header: \(headerH)  footer: \(footerH)")
    let docURL = page("IATemplateDocumentFile")!

    // ---- Preview, light and dark
    let pv = Page(width: 900, height: 1200)
    await pv.load(docURL)
    for (name, classes) in [("screen-light", ["mac", "content-size-l"]), ("screen-dark", ["mac", "night-mode", "content-size-l"])] {
        await pv.fill(classes: classes, data: ["document": fragment, "title": "Sample"])
        await pv.js("document.documentElement.style.paddingTop='40px';document.documentElement.style.paddingBottom='40px';true")
        await pv.snapshot(outDir.appendingPathComponent("\(name).png"), height: 2400)
    }
    let diag = await pv.js("""
      (function(){
        var cs = function(sel, p){ var e=document.querySelector(sel); return e ? getComputedStyle(e)[p] : '-'; };
        var fonts = ['12pt "Crimson Text"','12pt "Oswald"','12pt "Roboto"','12pt "Roboto Mono"','12pt "Oranburg Hebrew Serif"'];
        return JSON.stringify({
          errors: window.__errors,
          bodyFont: cs('body','fontFamily'), bodySize: cs('body','fontSize'),
          h1Color: cs('body > h1','color'), htmlBg: cs('html','backgroundColor'),
          fontsAvailable: fonts.map(function(f){ return f + '=' + document.fonts.check(f, 'a\\u05D0'); }),
          citationsInlined: document.querySelectorAll('a.citation[data-oranburg-cite]').length,
          citations: document.querySelectorAll('a.citation').length,
          unnumbered: Array.from(document.querySelectorAll('.unnumbered')).map(function(h){return h.textContent;}),
          selfNumbered: document.querySelectorAll('.self-numbered').length,
          outlines: Array.from(document.querySelectorAll('[data-outline]')).slice(0,8).map(function(h){return h.getAttribute('data-outline')+' '+h.textContent.slice(0,20);}),
          boxes: document.querySelectorAll('.box-title').length,
          firstCitation: (document.querySelector('a.citation')||{}).textContent,
          hebrewDir: (function(){ var p=Array.from(document.querySelectorAll('p')).find(function(p){return /[\\u05D0-\\u05EA]/.test(p.textContent.charAt(0));}); return p ? getComputedStyle(p).unicodeBidi + ' ' + getComputedStyle(p).direction : 'none'; })(),
          stylesheets: Array.from(document.styleSheets).map(function(s){ try { return (s.href||'inline').split('/').pop()+':'+s.cssRules.length; } catch(e) { return 'ERR'; } })
        });
      })()
      """) as? String ?? "{}"
    log("diagnostics: \(diag)")

    // ---- Print the document the way a WebKit print operation does
    let pp = Page(width: paper.width, height: paper.height)
    await pp.load(docURL)
    await pp.fill(classes: ["mac"], data: ["document": fragment, "title": "Sample"])
    let docPDF = outDir.appendingPathComponent("document.pdf")
    let pi = NSPrintInfo()
    pi.paperSize = paper
    pi.topMargin = headerH; pi.bottomMargin = footerH; pi.leftMargin = 0; pi.rightMargin = 0
    pi.horizontalPagination = .fit
    pi.verticalPagination = .automatic
    pi.jobDisposition = .save
    pi.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = docPDF
    let op = pp.web.printOperation(with: pi)
    op.showsPrintPanel = false
    op.showsProgressPanel = false
    op.view?.frame = NSRect(origin: .zero, size: paper)
    let pd = PrintDone()
    await withCheckedContinuation { c in
        pd.cont = c
        op.runModal(for: pp.window, delegate: pd, didRun: #selector(PrintDone.done(_:success:ctx:)), contextInfo: nil)
    }
    guard let doc = PDFDocument(url: docPDF) else { log("NO PDF"); return }
    log("document.pdf pages: \(doc.pageCount)  page size: \(doc.page(at: 0)!.bounds(for: .mediaBox).size)")
    // text-block geometry from the first body paragraph and first footnote
    for marker in ["Marker sentence one", "Marker sentence three", "John Doe"] {
        for i in 0..<doc.pageCount {
            let p = doc.page(at: i)!
            let s = p.string ?? ""
            if let r = s.range(of: marker) {
                let idx = s.distance(from: s.startIndex, to: r.lowerBound)
                let b = p.characterBounds(at: idx)
                log(String(format: "marker '%@' page %d  left %.1fpt  top %.1fpt", marker, i + 1, b.minX, paper.height - b.maxY))
                break
            }
        }
    }
    var rightmost: CGFloat = 0
    if let p = doc.page(at: 0), let sel = p.selection(for: p.bounds(for: .mediaBox)) {
        for line in sel.selectionsByLine() { rightmost = max(rightmost, line.bounds(for: p).maxX) }
        log(String(format: "page 1 rightmost text %.1fpt (right margin %.1fpt)", rightmost, paper.width - rightmost))
    }

    // ---- Compose title + header/footer bands, as iA Writer presumably does
    let composedURL = outDir.appendingPathComponent("composed.pdf")
    var box = CGRect(origin: .zero, size: paper)
    let ctx = CGContext(composedURL as CFURL, mediaBox: &box, nil)!
    func draw(_ pdf: PDFDocument?, in rect: CGRect) {
        guard let pg = pdf?.page(at: 0)?.pageRef else { return }
        let src = pg.getBoxRect(.mediaBox)
        ctx.saveGState()
        ctx.translateBy(x: rect.minX, y: rect.minY)
        ctx.scaleBy(x: rect.width / src.width, y: rect.height / src.height)
        ctx.drawPDFPage(pg)
        ctx.restoreGState()
    }
    let total = doc.pageCount
    if let t = page("IATemplateTitleFile") {
        let top = titleUsesBands ? headerH : 0, bottom = titleUsesBands ? footerH : 0
        let tp = Page(width: paper.width * pxPerPt, height: (paper.height - top - bottom) * pxPerPt)
        await tp.load(t)
        await tp.fill(classes: ["mac"], data: ["title": docTitle, "author": docAuthor, "date": docDate, "page-count": "\(total)"])
        ctx.beginPDFPage(nil)
        draw(await tp.pdfOfView(), in: CGRect(x: 0, y: bottom, width: paper.width, height: paper.height - top - bottom))
        ctx.endPDFPage()
        let d = await tp.js("JSON.stringify({author: (document.querySelector('[data-author]')||{}).textContent, errors: window.__errors})") as? String
        log("title page: \(d ?? "-")")
    }
    let hp = Page(width: paper.width * pxPerPt, height: max(headerH, 1) * pxPerPt)
    let fp = Page(width: paper.width * pxPerPt, height: max(footerH, 1) * pxPerPt)
    if let h = page("IATemplateHeaderFile") { await hp.load(h) }
    if let f = page("IATemplateFooterFile") { await fp.load(f) }
    // Every page. This was min(total, 8), which silently dropped the end
    // of any real document: its notes, its sources, its last section.
    for i in 0..<total {
        ctx.beginPDFPage(nil)
        if let pg = doc.page(at: i)?.pageRef { ctx.drawPDFPage(pg) }
        let data = ["title": docTitle, "author": docAuthor, "date": docDate,
                    "page-number": "\(i + 1)", "page-count": "\(total)"]
        if page("IATemplateHeaderFile") != nil {
            await hp.fill(classes: ["mac"], data: data)
            draw(await hp.pdfOfView(), in: CGRect(x: 0, y: paper.height - headerH, width: paper.width, height: headerH))
        }
        if page("IATemplateFooterFile") != nil {
            await fp.fill(classes: ["mac"], data: data)
            draw(await fp.pdfOfView(), in: CGRect(x: 0, y: 0, width: paper.width, height: footerH))
        }
        ctx.endPDFPage()
    }
    ctx.closePDF()
    if let c = PDFDocument(url: composedURL) {
        for i in 0..<c.pageCount {  // every page; was capped at 9
            let img = c.page(at: i)!.thumbnail(of: NSSize(width: paper.width * 1.5, height: paper.height * 1.5), for: .mediaBox)
            if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: outDir.appendingPathComponent("page-\(i + 1).png"))
            }
        }
    }
    let hd = await hp.js("JSON.stringify({text: document.body ? document.body.innerText : '', errors: window.__errors})") as? String
    log("header page: \(hd ?? "-")")
    try? report.write(to: outDir.appendingPathComponent("report.txt"), atomically: true, encoding: .utf8)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
Task { @MainActor in
    await run()
    NSApp.terminate(nil)
}
app.run()

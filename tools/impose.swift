// impose.swift — give an exported book PDF its binding gutter.
//
//   swiftc -O -o impose tools/impose.swift
//   ./impose in.pdf out.pdf <shift-in-points> [--first-page-verso]
//
// WHY THIS EXISTS
//
// A bound book needs a wider margin on the spine side of every page,
// and the spine is on the left of a recto (odd) page and on the right
// of a verso (even) page. WebKit, which is what iA Writer prints
// through, has no notion of recto and verso: whatever left margin the
// CSS sets is the left margin of every page. A PDF exported straight
// out of iA Writer therefore has its gutter on the correct side of
// half its pages and the wrong side of the other half, which is why
// the book templates were not usable for print on demand.
//
// The fix is to export with the text block at its final width,
// centered, and then move the whole block sideways: right on recto
// pages, left on verso pages. The book templates set
//
//     --page-margin-left = --page-margin-right = (inside + outside) / 2
//
// so the shift each page needs is (inside - outside) / 2, and after the
// shift a recto page has the inside margin on its left and a verso page
// has the outside margin on its left. Nothing is scaled, resampled or
// re-flowed: each page is drawn once into a new PDF under a
// translation, so text stays text and the fonts stay embedded.
//
//   Trim        Inside   Outside  Symmetric  Shift
//   6 x 9       1.0in    0.625in  0.8125in   0.1875in = 13.5pt
//   5.5 x 8.5   0.75in   0.5in    0.625in    0.125in  =  9pt
//   7 x 10      1.125in  0.75in   0.9375in   0.1875in = 13.5pt
//
// Page 1 is a recto unless --first-page-verso is given.

import CoreGraphics
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(("impose: " + message + "\n").data(using: .utf8)!)
    exit(1)
}

let args = CommandLine.arguments
guard args.count >= 4 else {
    fail("usage: impose in.pdf out.pdf <shift-in-points> [--first-page-verso]")
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2])
guard let shift = Double(args[3]) else {
    fail("shift must be a number of points, got \(args[3])")
}
let firstPageIsVerso = args.contains("--first-page-verso")

guard let document = CGPDFDocument(inputURL as CFURL) else {
    fail("could not read \(inputURL.path)")
}
let pageCount = document.numberOfPages
guard pageCount > 0 else { fail("\(inputURL.path) has no pages") }

// The output context needs a default media box; each page then states
// its own, so a document with mixed page sizes survives.
guard let firstPage = document.page(at: 1) else { fail("could not read page 1") }
var defaultBox = firstPage.getBoxRect(.mediaBox)
guard let context = CGContext(outputURL as CFURL, mediaBox: &defaultBox, nil) else {
    fail("could not write \(outputURL.path)")
}

for number in 1...pageCount {
    guard let page = document.page(at: number) else {
        fail("could not read page \(number)")
    }
    let box = page.getBoxRect(.mediaBox)
    let pageInfo = [kCGPDFContextMediaBox as String: NSValue(rect: box)] as CFDictionary
    context.beginPDFPage(pageInfo)
    context.saveGState()

    // Recto pages move toward the right, verso pages toward the left,
    // so that the gutter always lands on the bound edge.
    let isRecto = firstPageIsVerso ? (number % 2 == 0) : (number % 2 == 1)
    context.translateBy(x: CGFloat(isRecto ? shift : -shift), y: 0)
    context.drawPDFPage(page)

    context.restoreGState()
    context.endPDFPage()
}

context.closePDF()

let side = firstPageIsVerso ? "verso" : "recto"
print("imposed \(pageCount) pages, shift \(shift)pt, page 1 is \(side) -> \(outputURL.path)")

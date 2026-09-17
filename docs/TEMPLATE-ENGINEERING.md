iA Writer Template Engineering Notes
=====================================

Technical reference for the Oranburg Academic template family. Documents how iA Writer's template system works, known limitations, workarounds, and decisions made during development.

Verified for **iA Writer 8.0.7 on macOS** on 2026-09-16 against three sources: iA's template documentation (<https://ia.net/writer/support/preview/custom-templates>, which mirrors <https://github.com/iainc/iA-Writer-Templates>, last changed January 2023), iA's templates page (<https://ia.net/writer/support/preview/templates>), and the app itself: the built-in templates in `iA Writer.app/Contents/Resources/Templates`, the `Template.js` that fills template pages (`Contents/Frameworks/Kit.framework/Resources/Template.js`), and the strings compiled into the Kit framework. Where this file says "the app", that is where the fact came from.



## How Templates Render

iA Writer templates are macOS/iOS bundles containing HTML and CSS. The template system uses WebKit to render markdown as HTML, styled by the template's CSS.

There are two rendering contexts:

**Preview (on screen):** The `document.html` file renders the markdown content. iA Writer adds a `.night-mode` class to the `<html>` element when dark mode is active. The preview respects all CSS including colors, fonts, and layout. Header and footer HTML files are NOT shown in preview.

**PDF/Print export:** All HTML files render. The `title.html` file (if present) renders as a separate first page. The `header.html` and `footer.html` files render at the top and bottom of every subsequent page, within the height specified by `IATemplateHeaderHeight` and `IATemplateFooterHeight` in `Info.plist` (max 400 CSS pixels each). The `document.html` file renders the body content between them.


## Title Pages

The title page is a completely separate HTML file (`title.html`) in the template bundle. It only appears in PDF/print export, never in preview.

Available data attributes for title pages:
- `data-title` -- document filename (without extension)
- `data-author` -- from iA Writer Preferences
- `data-date` -- current date (supports format strings like `data-date="MMMM d, yyyy"`)
- `data-page-count` -- total pages in the export

`data-page-number` is NOT available on title pages. This is intentional so page numbering stays consistent whether the title page is included or not.

The title page is toggled on/off in iA Writer Settings, Templates, Printing & PDF Export. Users must enable it for the title page to appear.


## Heading Distinction (Setext vs ATX)

iA Writer uses MultiMarkdown to convert markdown to HTML. Both Setext (`===` underline) and ATX (`#` prefix) headings produce identical `<h1>` tags in the HTML output. There is no class, attribute, or any other markup that distinguishes them.

To style the document title differently from section headings, use the CSS selector `body > h1:first-of-type`. This targets the first top-level H1 regardless of which markdown syntax produced it. This is what the Oranburg templates do (and oranburg.js also marks that heading `.doc-title`).

For a distinct title page in PDF export, use the `title.html` file (see above). The document title in `title.html` comes from the filename via `data-title`, not from the first heading in the markdown.


## The White Band Problem (Dark Mode PDF)

**Status:** Known iA Writer limitation. No workaround exists.

When exporting to PDF, iA Writer's renderer wraps each page in a white container. Template CSS cannot control this container's background color. An iA Writer developer confirmed this in GitHub issue #48 (January 2023):

> "Unfortunately, due to the way templates are rendered it's not currently possible to set a background color. We'll keep this feature in mind as we improve templates in iA Writer."

**Practical impact:** If your template has a dark background color, exported PDFs will show white bands around the content area (the page margins). The content area itself renders with the template's background, but the page surround is always white.

**Workaround:** Design PDF/print output for white backgrounds. Use `@media print` to force `background: transparent` and black text. Reserve dark mode styling for on-screen preview only, where it renders correctly. This is what the Oranburg templates do.


## iA Writer App-Level Settings That Affect Templates

iA Writer has built-in settings (Settings, Templates) that interact with -- and may conflict with -- custom templates:

| Setting | What it does | Potential conflict |
|:--|:--|:--|
| Center headings | Centers all headings in preview/export | May override template's `text-align` on headings |
| Number headings | Adds automatic numbering (1, 1.1, 1.1.1) | Conflicts with custom CSS counter numbering (e.g., LawReview's Bluebook I/A/1/i/a system) |
| Indent paragraphs | Adds first-line indent | May double-indent if template also sets `text-indent` |
| Title page (Printing & PDF) | Toggles title page in export | Must be enabled for `title.html` to render |
| Headers (Printing & PDF) | Toggles running headers | Must be enabled for `header.html` to render |
| Footers (Printing & PDF) | Toggles running footers | Must be enabled for `footer.html` to render |

**Recommendation for Oranburg templates:** Turn OFF "Number headings" and "Indent paragraphs" in iA Writer settings. The templates handle these in CSS. Turn ON "Title page," "Headers," and "Footers" for templates that include those HTML files.

The GitHub template explicitly does not support these default settings. Our LawReview template similarly implements its own numbering system.


## Page Size and Margins

iA Writer 8 does not read page geometry from CSS the way a browser does.

- **Paper size** comes from **File > Page Setup**. iA's PDF export sheet says so ("To change PDF layout, choose File → Page Setup"), and the app offers US Letter, A4, A5 and A3 plus any custom size macOS knows. For the book trims, create a custom paper size (Page Setup > Paper Size > Manage Custom Sizes) of 6 x 9 in, 5.5 x 8.5 in or 7 x 10 in with zero non-printable margins, and pick it before exporting. `@page { size }` is ignored by WebKit (tested: a WebKit print of `@page { size: 6in 9in }` still comes out on the Page Setup paper). The templates keep an `@page size` line only for Chromium-based renderers.
- **Top and bottom margins** are `IATemplateHeaderHeight` and `IATemplateFooterHeight` in `Info.plist`. The header and footer pages are drawn inside those bands. iA's own templates set no vertical margin in CSS. The Oranburg templates set the heights to the intended margins (72 = 1 in).
- **Left and right margins** are ours. iA's built-in templates set them with `body` padding under `@media print`. The Oranburg templates do the same through two variables, `--page-margin-left` and `--page-margin-right`, which `oranburg-common.css` applies to the document body and to the header, footer and title pages, so the running head lines up with the text block.
- `@page { margin }` is avoided. WebKit does honor it (tested), and it replaces the print margins the app sets, so it would fight the header and footer heights.

| Template | Paper (Page Setup) | Top / header | Bottom / footer | Left | Right |
|:--|:--|:--|:--|:--|:--|
| Screen | any | 72 | 72 | 1 in | 1 in |
| Draft | US Letter | 72 | 72 | 1 in | 1 in |
| Law Review | US Letter | 72 | 72 | 1.25 in | 1.25 in |
| Submission | US Letter | 72 | 72 | 1 in | 1 in |
| US Trade | 6 x 9 in | 45 (0.625 in) | 54 (0.75 in) | 1.0 in gutter | 0.625 in |
| Digest | 5.5 x 8.5 in | 36 (0.5 in) | 45 (0.625 in) | 0.75 in gutter | 0.5 in |
| Executive | 7 x 10 in | 54 (0.75 in) | 63 (0.875 in) | 1.125 in gutter | 0.75 in |

The plist heights are documented as "CSS points" on GitHub and "CSS pixels" on iA's support page. The templates treat them as points (1/72 in), which is how a WebKit print maps CSS units. Check one exported PDF with a ruler before sending a book to Lulu.

**Mirror margins:** WebKit cannot tell recto from verso, so the gutter is always on the left. For true mirror margins, use the pandoc-to-Word pipeline with reference documents that have mirror margins enabled.

## Page Break Limitations

`page-break-after: avoid` does not work in WebKit (known bug since 2005, iA Writer Templates issue #33). This means you cannot prevent a page break immediately after a heading using this property.

**Workaround (from FirIA and GitHub templates):** Use `page-break-inside: avoid` on headings combined with a `::after` pseudo-element that adds invisible height:

```css
h1, h2, h3 {
    page-break-inside: avoid;
}

h1::after, h2::after, h3::after {
    content: "";
    display: block;
    height: 50px;
    margin-bottom: -50px;
}
```

This makes the heading "taller" from the layout engine's perspective, so `page-break-inside: avoid` keeps the heading and the following content together.

The Oranburg templates implement this hack in `oranburg-common.css` with a 60pt reserve (about four lines of body text), and keep the `break-after: avoid` declarations in case WebKit fixes the bug. The render test confirms that a heading near the foot of a page moves to the next page.

`+++` on its own line becomes `<div class="page-break" style="page-break-before: always;">` (the app). The templates zero the top margin of whatever follows it.


## Shared Files and the Build Script

iA Writer copies a bundle when it installs it and resolves every stylesheet and script relative to the bundle's `Contents/Resources`. A bundle cannot reach `../../shared/`. So the shared files are written once in `shared/` and **copied into each bundle** by `tools/build.py`:

```
python3 tools/build.py            # sync shared/ into every bundle, then check
python3 tools/build.py --check    # check only (exit 1 on any problem)
python3 tools/build.py --bump minor   # raise every template's version
python3 tools/build.py --zip      # also write dist/*.iatemplate.zip
```

The script copies only the shared files a bundle actually references (following `@import`), stamps each copy with a "generated, do not edit" banner, and removes copies that are no longer referenced. The check fails on: an invalid plist (`plutil -lint`), a missing required key or version, a page file not named in `Info.plist`, an HTML page without a doctype or with unbalanced tags, a `data-*` attribute iA Writer does not fill, a `class` on `<html>` (the app overwrites it), a reference that leaves the bundle or does not exist, a bundle copy that has drifted from `shared/`, and a stray `.DS_Store`. **Edit `shared/`, run the script, commit both.**

| File | Contents | Used by |
|:--|:--|:--|
| `shared/oranburg-variables.css` | palette, font stacks (with Hebrew fallback faces), light/dark/print colors, sizes, page-margin variables | all |
| `shared/oranburg-common.css` | iA Writer markup: View > Font Size classes, print margins, page breaks, heading keep-with-next, footnotes, citations, `{{TOC}}`, highlights, math, content blocks, right-to-left text, header/footer/title page layout, Law of the Firm boxes | all |
| `shared/oranburg-book-base.css` | book typography | US Trade, Digest, Executive |
| `shared/oranburg.js` | footnote, citation, heading and box handling (below) | all |

Each template's `style.css` imports the shared files and adds only what is specific to its format.

## oranburg.js

iA Writer replaces the `innerHTML` of the `data-document` element and then dispatches `ia-writer-change` on that element (the app's `Template.js`; the event does not bubble). The script listens there and reruns after every update. Features are switched on by attributes on `<body>` in `document.html`:

- **Always:** normalizes a footnote reference into `<sup>`; marks the first H1 `.doc-title` and hides it from `{{TOC}}`; tags an H4 starting with 📜, 💡 or 📄 and the blockquote after it with `box-source`, `box-insight` or `box-transaction` (Law of the Firm convention, `LawOS/docs/writing/document-types/lotf-casebook.md`); fills an empty `data-author` on the title page with "Seth C. Oranburg".
- **`data-oranburg-citations="inline"`** (all templates): iA Writer renders a `[#CiteKey]` as a bracketed number, `[7]`, linked to a bibliography entry appended to the endnotes. Seth's convention puts each `[#CiteKey]` inside a footnote, so a printed note would read "*See* [7] at 11." The script replaces the number with the text of the `[#CiteKey]:` definition ("*See* Jane Roe, *An Invented Article*, 1 J. Nowhere 1 (2010) at 11.") and hides the now-duplicate entry. The definition's final period is dropped; the note supplies its own. A key with no definition is shown in red on screen.
- **`data-oranburg-outline="legal"`** (Law Review): marks Abstract, Contents, Introduction, Conclusion, Acknowledgments, Appendix and similar H1/H2 headings `.unnumbered`; marks a heading whose text already starts with a number ("I. Title") `.self-numbered` so CSS does not number it twice; computes I / A / 1 / i / a for each heading and writes it onto the matching `{{TOC}}` link. The numbering itself stays in CSS counters, so it still works if scripts are off.

Because the script changes the DOM, each `Info.plist` sets `IATemplateSupportsDiffHTML` to NO. The key is not in iA's documentation; it is read by the app (it appears in the Kit framework next to the documented keys), and `Template.js` either patches the body with diffHTML or replaces it outright depending on an option. Replacing outright is the safe choice for a template that edits its own DOM.

## Template Bundle Reference

Each `.iatemplate` bundle follows this structure:

```
Name.iatemplate/
    Contents/
        Info.plist              Required. Bundle metadata.
        Resources/
            document.html       Required. Wraps data-document body.
            style.css           Template styling; imports the shared files.
            oranburg-*.css      Copies of shared/ (generated by tools/build.py).
            oranburg.js         Copy of shared/oranburg.js (generated).
            title.html          Optional. Separate title page (PDF only).
            header.html         Optional. Running header (PDF only).
            footer.html         Optional. Running footer (PDF only).
            fonts/              Optional. Bundled font files.
```

**Info.plist required keys:**
- `CFBundleName` -- template name shown in iA Writer
- `CFBundleIdentifier` -- unique reverse-DNS identifier
- `IATemplateDocumentFile` -- HTML filename without extension

**Info.plist optional keys (documented):**
- `IATemplateTitleFile`, `IATemplateHeaderFile`, `IATemplateFooterFile` -- file names without `.html`
- `IATemplateHeaderHeight`, `IATemplateFooterHeight` -- number, at most 400; the top and bottom print margins
- `IATemplateTitleUsesHeaderAndFooterHeight` -- boolean, default YES; NO gives the title page the full sheet
- `IATemplateSuportsSmartTables` (sic) -- boolean, default YES
- `IATemplateSupportsMath` -- boolean, default YES (KaTeX)
- `IATemplateDescription`, `IATemplateAuthor`, `IATemplateAuthorURL` -- recommended

**Keys the app reads that iA does not document** (from the Kit framework): `IATemplateSupportsSmartTables` (correct spelling), `IATemplateSupportsDiffHTML`, `IATemplateSupportsHighlight`, `IATemplateUsesRevealJS`, `IATemplateWantsPDFGenerationDelay`. The Oranburg templates set only `IATemplateSupportsDiffHTML` = NO (see oranburg.js). There is no minimum-version key; the templates carry the standard `CFBundleShortVersionString` and `CFBundleVersion` (bump them with `tools/build.py --bump`) so a reinstall can be told apart. Reinstalling a template with the same `CFBundleIdentifier` prompts "Duplicate Template ... Replace".

**HTML data attributes:**
- `data-document` -- document body (on `<body>` element of document.html)
- `data-title` -- document filename
- `data-author` -- from iA Writer Preferences
- `data-date` -- current date (with optional format string)
- `data-page-number` -- current page (not available on title page)
- `data-page-count` -- total pages

**CSS environment classes** (the app replaces the whole `class` attribute of `<html>`, so never put your own class there; identify a page by `id`, as iA's own `<html id="title">` does):
- `.night-mode` -- dark mode is active (Settings > Templates > Invert colors can flip it)
- `.ios`, `.mac` -- platform
- `.content-size-4xs` ... `.content-size-10xl` -- View > Font Size in iA Writer 8 (xs, s, m, l, xl, 2xl, 3xl ...; iA's own templates map l to 18px). Older iOS builds used `xxl`, `xxxl` and `content-size-accessibility-*`. `oranburg-common.css` handles both, on screen only.
- `.center-headings`, `.indent-paragraphs`, `.number-headings` -- the Web Preview switches in Settings > Templates
- `.emphasis-italic`, `.emphasis-mark`, `.task-list-item-checked-fade`, `.task-list-item-checked-line-through` -- other app options

**HTML iA Writer 8 emits** (Markup.html in iA's repository and format strings in the app):
- footnote reference: `<sup><a href="#fn1" id="fnr1" title="see footnote" class="footnote">1</a></sup>`; some code paths emit the MultiMarkdown form `<a href="#fn:1" id="fnref:1" class="footnote">[1]</a>`, which oranburg.js normalizes
- notes: `<div class="footnotes"><hr /><ol><li id="fn1"><p>… <a class="reversefootnote">↩</a></p></li>…</ol></div>`. iA Writer's footnotes are endnotes.
- citation: `<a class="citation" href="#fn2" title="Jump to citation">[<span class="locator">p. 42</span>, 2]<span class="citekey" style="display:none">key</span></a>`, and `<li id="fn2" class="citation">` appended to the notes list. Undefined keys appear as `.externalcitation` or `.notcited`.
- `{{TOC}}`: `<div class="TOC">` with nested lists (the class is upper case; `.toc` does not match)
- `+++`: `<div class="page-break" style="page-break-before: always;"></div>`
- `==text==`: `<mark>`; math: `<span class="math">`, rendered by KaTeX with `data-display-math`
- content blocks: images as `<figure><img><figcaption>`, CSV as `<table>` (Smart Tables), Markdown files inline
- headings: plain `<h1>` in iA's sample; the app can also emit `<h1 id="...">`. Do not rely on ids.
- task lists: `<li class="task-list-item"><input type="checkbox" class="task-list-item-checkbox" disabled>`

**Settings > Templates** (the app's preferences pane): Web Preview has *Center headings*, *Indent paragraphs*, *Number headings* and *Invert colors*; Printing & PDF Export has *Title page*, *Headers* and *Footers*. Author name comes from Settings > Authors and fills `data-author`.


## Hebrew and Right-to-Left Text

`Conventions/hebrew-sources.md` in the iA Writer library lays Hebrew out in tiers and relies on Unicode bidi for direction. The templates support that without markup:

- Paragraphs, list items, headings, cells and captions use `unicode-bidi: plaintext`, so a paragraph whose first strong character is Hebrew runs right to left and an English paragraph with an inline Hebrew word stays left to right. An explicit `dir="rtl"` in HTML still wins.
- Crimson Text, Oswald and Roboto have no Hebrew. `oranburg-variables.css` defines two fallback faces limited by `unicode-range` to the Hebrew blocks and puts them first in the font stacks: *Oranburg Hebrew Serif* (SBL Hebrew or Taamey Frank if installed, else New Peninim MT or Times New Roman, both on macOS, both with nikud) and *Oranburg Hebrew Sans* (Arial Hebrew). Latin text is unaffected. Installing SBL Hebrew gives the best cantillation.

## Development and Debugging

**Reload template in preview:** Shift+Command+R (fully reloads CSS and HTML)

**Enable Web Inspector:** Run in Terminal:
```
defaults write pro.writer.mac WebKitDeveloperExtras -bool true
```
Then right-click in Preview and select "Inspect Element."

**Windows:** Ctrl+J enables the Chromium inspector.

**Vertical margins:** Avoid setting vertical margins/padding on the document page body. iA Writer adjusts `<html>` padding in Preview to match the Editor. Top and bottom margins for PDF are controlled by header/footer heights in Info.plist.

**Render test without iA Writer:** `tools/render_test.sh` converts `tests/fixtures/sample.md` into the HTML shapes iA Writer emits (`tools/ia_html.py`, via pandoc), loads each bundle's own `document.html` in WebKit, fills it the way `Template.js` does, and writes light and dark Preview snapshots, a WebKit print of the body with the plist margins, and a composed PDF with the title, header and footer pages drawn in (`tools/render.swift`). It is a model of iA Writer, not iA Writer; confirm in the app before trusting a detail. If `swiftc` reports that the SDK is newer than the compiler, run it with `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk`.

**Toolbar color:** iA Writer matches the Preview toolbar color to the template. Set `color` and `background-color` on the `<html>` element for this to work correctly.


## Known Gaps and Future Work

1. **Mirror margins in PDF:** not possible in WebKit. Book templates put the gutter on the left.
2. **Header/footer scale:** iA does not document the scale at which it renders `header.html` and `footer.html`. The templates assume the same CSS-inch-to-point mapping as the document. If an exported PDF shows the running head wider or narrower than the text block, adjust `--page-margin-left/right` for the header only.
3. **Font bundling:** the templates rely on locally installed Crimson Text, Oswald and Roboto (installed on this Mac through Homebrew). Roboto Mono and Courier Prime are optional; the stacks fall back to SF Mono/Menlo and Courier New. Bundling `.woff2` files under `Resources/fonts/` would make the bundles self-contained at the cost of size; the Google Fonts licence (OFL) allows it.
4. **Title-page metadata:** iA Writer passes only title (file name), author and date to template pages; YAML front matter does not reach them. The Law Review star note is therefore static text in `title.html`.
5. **Footnotes are endnotes** in iA Writer's own PDF. Page-bottom footnotes need the DOCX pipeline.

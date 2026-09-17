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
| Law Review | US Letter | 72 | 72 | 1.25 in | 1.25 in |
| Draft | US Letter | 72 | 72 | 1 in | 1 in |
| Double-Spaced | US Letter | 72 | 72 | 1 in | 1 in |
| Executive | 7 x 10 in | 54 (0.75 in) | 63 (0.875 in) | 0.9375 in | 0.9375 in |
| US Trade | 6 x 9 in | 45 (0.625 in) | 54 (0.75 in) | 0.8125 in | 0.8125 in |
| Digest | 5.5 x 8.5 in | 36 (0.5 in) | 45 (0.625 in) | 0.625 in | 0.625 in |

The three book templates carry a symmetric side margin, half of inside plus
outside, and `tools/make_book.sh` supplies the gutter after the export. See
"Mirror margins" below.

The plist heights are documented as "CSS points" on GitHub and "CSS pixels" on iA's support page. The templates treat them as points (1/72 in), which is how a WebKit print maps CSS units. Check one exported PDF with a ruler before sending a book to Lulu.

**Mirror margins:** WebKit has no notion of recto and verso, so whatever left
margin the CSS sets is the left margin of every page. Rather than ship books
with the gutter on the wrong side of every even page, the book templates export
a symmetric margin and `tools/impose.swift` moves each page toward its own
spine afterwards.

The arithmetic. Let *i* be the inside margin and *o* the outside. The template
sets both side margins to (*i* + *o*) / 2, so the text block already has its
final width, centered. The tool then translates each page by (*i* − *o*) / 2,
right on a recto page and left on a verso one. A recto page lands with *i* on
its left and *o* on its right; a verso page lands the other way round.

Each page is drawn once into a new `CGPDFContext` under that translation, which
keeps text as text and leaves the embedded fonts embedded. Nothing is scaled,
rasterized or re-flowed.

| Trim | Inside | Outside | Symmetric export | Shift |
|:--|:--|:--|:--|:--|
| 7 x 10 | 1.125 in | 0.75 in | 0.9375 in | 13.5 pt |
| 6 x 9 | 1.0 in | 0.625 in | 0.8125 in | 13.5 pt |
| 5.5 x 8.5 | 0.75 in | 0.5 in | 0.625 in | 9 pt |

Measured on `tests/fixtures/sample.md` through `composed.pdf`, on 2026-09-17,
with PDFKit text-selection bounds. Before imposition every page of the 6 x 9
render measured 58.5 pt on both sides; after it, odd pages measured 72.0 pt left
and 45.0 pt right and even pages the reverse, which is 1.000 in and 0.625 in
exactly. The 7 x 10 and 5.5 x 8.5 renders came out equally exact.

Lulu's gutter allowance grows with a book's page count, so the inside margins
above are a starting point for a book in the middle of the range. Check them
against Lulu's current table for the actual page count before a print run.

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
| `shared/oranburg-common.css` | iA Writer markup: View > Font Size classes, print margins, page breaks, heading keep-with-next, footnotes, citations, `{{TOC}}`, highlights, math, content blocks, the Hebrew tiers and flags, header/footer/title page layout, Law of the Firm boxes, Preview warnings | all |
| `shared/oranburg-book-base.css` | book typography | US Trade, Digest, Executive |
| `shared/oranburg.js` | footnote, citation, heading and box handling (below) | all |

Each template's `style.css` imports the shared files and adds only what is specific to its format.

## oranburg.js

iA Writer replaces the `innerHTML` of the `data-document` element and then dispatches `ia-writer-change` on that element (the app's `Template.js`; the event does not bubble). The script listens there and reruns after every update. Features are switched on by attributes on `<body>` in `document.html`:

- **Always:** normalizes a footnote reference into `<sup>`; marks the first H1 `.doc-title` and hides it from `{{TOC}}`; tags an H4 starting with 📜, 💡 or 📄 and the blockquote after it with `box-source`, `box-insight` or `box-transaction` (Law of the Firm convention, `LawOS/docs/writing/document-types/lotf-casebook.md`) and hides those H4s from `{{TOC}}`, where each would otherwise take a line; marks the Hebrew blocks, tiers and flag strings described above; shows a Preview warning when the first H1 is a heading it recognizes as a section, because every template treats the first H1 as the document title and that file has silently lost a section; fills an empty `data-author` on the title page with "Seth C. Oranburg".
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


## Hebrew and Aramaic

`Conventions/hebrew-sources.md` in the iA Writer library is the standard. It
declares SBL general-purpose romanization with four named deviations, lays
Hebrew out in three tiers, and defines a set of exact flag strings for work
that is not finished. The templates implement that file; where this document
and that one disagree, that one wins.

**Direction** relies on Unicode bidi, with no markup. Paragraphs, list items,
headings, cells and captions carry `unicode-bidi: plaintext`, so a paragraph
whose first strong character is Hebrew runs right to left and an English
paragraph with an inline Hebrew word stays left to right. An explicit
`dir="rtl"` still wins.

`plaintext` sets the inline direction and leaves `text-align` alone, so a
Hebrew paragraph in a justified template would have hung its last line on the
left. `oranburg.js` therefore also adds `.hebrew-block` to any element whose
first strong character is Hebrew, and the class sets `text-align: right` and
turns justification off. Justified Hebrew is worth avoiding on its own account:
WebKit stretches the spaces around a maqaf and the nikud drift off their
letters.

**Leading.** Nikud sits below the baseline and ta'amim above it. At the 1.15 the
Latin body uses, pointed Hebrew crowds and cantillated Hebrew collides.
`.hebrew-block` takes `--line-height-hebrew-print` (1.5) and
`--line-height-hebrew` (1.7) instead.

**The tiers.** `oranburg.js` recognizes them from the shape the convention
prescribes, since the Markdown carries no markup to hook onto:

- *Tier 1* is a blockquote that starts Hebrew, optionally a second blockquote
  after it holding the English, then a short italic line: the citation and
  edition. The citation line gets `.source-citation`, the gap between the
  blockquotes closes, and the group is kept on one page.
- *Tier 2* is a Hebrew paragraph, a paragraph whose entire content is one `<em>`
  (the romanization), and a paragraph opening with a quotation mark (the gloss).
  All three get `.tier2`, lose the first-line indent, and are set off from the
  body above and below. A Hebrew paragraph inside a blockquote is skipped, since
  that is Tier 1.
- *Tier 3* needs nothing beyond the direction rule.

The Tier 2 test is a heuristic and it can miss. A romanization line carrying a
trailing citation in roman type falls out of the pattern and is styled as body
text, which is a silent degradation rather than a wrong one.

**Flag strings** are matched exactly, as the convention requires, including the
two that carry an argument (`[Vocalization: ...]`, `[Not fetched: ...]`). Each
is wrapped in `.heb-flag` and boxed. They stay visible in print: a page that
looks finished while a vocalization is still unattributed is worse than a page
that admits it. `[Aramaic]` is a language label, so it takes the quieter
`.heb-flag-label` grey.

**Fonts.** Crimson Text, Oswald and Roboto have no Hebrew.
`oranburg-variables.css` defines "Oranburg Hebrew Serif" and "Oranburg Hebrew
Sans" with `unicode-range` limited to U+0590 to U+05FF, U+FB1D to U+FB4F, the
RTL mark and the alef-bet symbols, and puts them first in the stacks, so Latin
text is untouched. The serif stack is SBL Hebrew, Ezra SIL, Taamey Frank CLM,
Frank Ruhl Libre, David Libre, Noto Serif Hebrew, New Peninim MT, Times New
Roman.

The order is by how well each face places marks. The first three were designed
for pointed and cantillated Biblical text. The middle three place nikud well
and ta'amim poorly. New Peninim MT and Times New Roman ship with macOS and are
the floor. On 2026-09-17 this machine had Frank Ruhl Libre, David Libre and
Noto Serif Hebrew installed and none of the first three, so Hebrew was
resolving to Frank Ruhl Libre; `brew install --cask font-ezra-sil` moves it up
two places for about a megabyte.

A `local()` stack fails silently. To find out which face is actually drawing,
open the Web Inspector on Preview (see below) and check the computed font on a
Hebrew paragraph.


## Development and Debugging

**Reload template in preview:** Shift+Command+R (fully reloads CSS and HTML)

**Enable Web Inspector:** Run in Terminal:
```
defaults write pro.writer.mac WebKitDeveloperExtras -bool true
```
Then right-click in Preview and select "Inspect Element."

**Windows:** Ctrl+J enables the Chromium inspector.

**Vertical margins:** Avoid setting vertical margins/padding on the document page body. iA Writer adjusts `<html>` padding in Preview to match the Editor. Top and bottom margins for PDF are controlled by header/footer heights in Info.plist.

**Which render output to measure.** `render_test.sh` writes two PDFs per
bundle and they do not agree. `document.pdf` comes from an `NSPrintOperation`
on a web view whose width in CSS pixels is set to the paper width in points,
with `horizontalPagination = .fit`; AppKit scales that to the sheet, and every
margin in it came out 1.0667 times the CSS value when measured on 2026-09-17.
`composed.pdf` applies the 96-to-72 conversion explicitly and measured exact:
72.0 pt where Draft asks for 1 in, 90.0 pt where Law Review asks for 1.25 in.
**Measure `composed.pdf`.** A margin discrepancy seen in `document.pdf` is the
harness, not the template.

**Render test without iA Writer:** `tools/render_test.sh` converts `tests/fixtures/sample.md` into the HTML shapes iA Writer emits (`tools/ia_html.py`, via pandoc), loads each bundle's own `document.html` in WebKit, fills it the way `Template.js` does, and writes light and dark Preview snapshots, a WebKit print of the body with the plist margins, and a composed PDF with the title, header and footer pages drawn in (`tools/render.swift`). It is a model of iA Writer, not iA Writer; confirm in the app before trusting a detail. The script now picks an older SDK itself when one is present, because a macOS
update routinely leaves the command-line `swiftc` older than the default SDK.
Setting `SDKROOT` by hand still overrides it.

**Toolbar color:** iA Writer matches the Preview toolbar color to the template. Set `color` and `background-color` on the `<html>` element for this to work correctly.


## Known Gaps and Future Work

1. **Mirror margins in PDF:** not possible in WebKit. Book templates put the gutter on the left.
2. **Header/footer scale:** iA does not document the scale at which it renders `header.html` and `footer.html`. The templates assume the same CSS-inch-to-point mapping as the document. If an exported PDF shows the running head wider or narrower than the text block, adjust `--page-margin-left/right` for the header only.
3. **Font bundling:** the templates rely on locally installed Crimson Text, Oswald and Roboto (installed on this Mac through Homebrew). Roboto Mono and Courier Prime are optional; the stacks fall back to SF Mono/Menlo and Courier New. Bundling `.woff2` files under `Resources/fonts/` would make the bundles self-contained at the cost of size; the Google Fonts licence (OFL) allows it.
4. **Title-page metadata:** iA Writer passes only title (file name), author and date to template pages; YAML front matter does not reach them. The Law Review star note is therefore static text in `title.html`.
5. **Footnotes are endnotes** in iA Writer's own PDF. Page-bottom footnotes need the DOCX pipeline.

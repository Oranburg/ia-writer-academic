iA Writer Template Engineering Notes
=====================================

Technical reference for the Oranburg Academic template family. Documents how iA Writer's template system works, known limitations, workarounds, and decisions made during development.


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

To style the document title differently from section headings, use the CSS selector `h1:first-of-type`. This targets the first H1 in the document body regardless of which markdown syntax produced it. This is what the Oranburg templates do.

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


## Page Dimensions and @page Rules

The CSS `@page` rule sets page size and margins for PDF export:

```css
@page {
    size: 6in 9in;          /* width height */
    margin: 0.625in 0.625in 0.75in 1.0in;  /* top right bottom left */
}
```

There is a known WebKit bug (iA Writer Templates issue #12) where physical dimensions may not render exactly as specified. The `@page { size }` property should work in current versions, but physical accuracy should be verified with a printed proof before submitting to Lulu or any print service.

**Mirror margins:** CSS `@page` does not support mirror margins (different inside/outside margins for recto/verso pages). The margin values in the book templates use the gutter (inside) margin as the left margin, which means verso pages will have the gutter on the wrong side. For true mirror margins, post-process through Word (which supports mirror margins natively) or use pandoc with a reference document.


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

The Oranburg templates use `page-break-after: avoid` and `break-after: avoid` as declarations (in case WebKit fixes the bug), but do not currently implement the `::after` hack. This is a known gap that should be addressed if page breaks after headings become a problem in practice.


## Shared CSS Architecture

All Oranburg templates import from two shared CSS files:

**`shared/oranburg-variables.css`** -- CSS custom properties for:
- Color palette (8 brand colors + neutrals)
- Font stacks (Crimson Text, Oswald, Roboto, Roboto Mono, TNR override)
- Heading colors for light mode, dark mode, and print (all black)
- Spacing values (line height, font sizes, indents)
- Print heading hierarchy (sizes and weights per D-015)

**`shared/oranburg-book-base.css`** -- Common rules for book-format templates:
- Base typography and layout
- Heading styles with color hierarchy
- Paragraph handling (first-line indent for print, block paragraphs for screen)
- Blockquotes, links, lists, tables, code, footnotes
- Running header and footer styles
- iOS font size support

Individual book templates (US Trade, Digest, Executive) import the book base and add only their `@page` rule with the correct page size and margins.


## Template Bundle Reference

Each `.iatemplate` bundle follows this structure:

```
Name.iatemplate/
    Contents/
        Info.plist              Required. Bundle metadata.
        Resources/
            document.html       Required. Wraps data-document body.
            style.css           Required. All styling.
            title.html          Optional. Separate title page (PDF only).
            header.html         Optional. Running header (PDF only).
            footer.html         Optional. Running footer (PDF only).
            fonts/              Optional. Bundled font files.
```

**Info.plist required keys:**
- `CFBundleName` -- template name shown in iA Writer
- `CFBundleIdentifier` -- unique reverse-DNS identifier
- `IATemplateDocumentFile` -- HTML filename without extension

**Info.plist optional keys:**
- `IATemplateTitleFile`, `IATemplateHeaderFile`, `IATemplateFooterFile` -- filenames
- `IATemplateHeaderHeight`, `IATemplateFooterHeight` -- max 400 CSS pixels
- `IATemplateTitleUsesHeaderAndFooterHeight` -- boolean, default YES
- `IATemplateDescription`, `IATemplateAuthor`, `IATemplateAuthorURL`

**HTML data attributes:**
- `data-document` -- document body (on `<body>` element of document.html)
- `data-title` -- document filename
- `data-author` -- from iA Writer Preferences
- `data-date` -- current date (with optional format string)
- `data-page-number` -- current page (not available on title page)
- `data-page-count` -- total pages

**CSS environment classes** (added to `<html>` element):
- `.night-mode` -- dark mode is active
- `.ios` -- rendering on iOS
- `.mac` -- rendering on macOS


## Development and Debugging

**Reload template in preview:** Shift+Command+R (fully reloads CSS and HTML)

**Enable Web Inspector:** Run in Terminal:
```
defaults write pro.writer.mac WebKitDeveloperExtras -bool true
```
Then right-click in Preview and select "Inspect Element."

**Windows:** Ctrl+J enables the Chromium inspector.

**Vertical margins:** Avoid setting vertical margins/padding on the document page body. iA Writer adjusts `<html>` padding in Preview to match the Editor. Top and bottom margins for PDF are controlled by header/footer heights in Info.plist.

**Toolbar color:** iA Writer matches the Preview toolbar color to the template. Set `color` and `background-color` on the `<html>` element for this to work correctly.


## Known Gaps and Future Work

1. **Mirror margins in PDF:** Not supported by CSS `@page`. Book templates use fixed left-gutter margins. For true mirror margins, use the pandoc-to-Word pipeline with reference documents that have mirror margins enabled.

2. **Page break after headings:** The `::after` pseudo-element hack should be added to all templates if heading-orphaning becomes a problem.

3. **Font bundling:** Templates currently rely on locally installed Google Fonts (Crimson Text, Oswald, Roboto, Roboto Mono). Bundling `.ttf` or `.woff2` files inside each template's `Resources/fonts/` directory would make them self-contained. This adds file size but removes the local installation requirement.

4. **`@import` path for shared CSS:** The templates import shared CSS via relative paths (`../../shared/oranburg-variables.css`). This works when the templates are in the repo directory structure. When installed into iA Writer (which copies the bundle), the shared files are NOT copied. Each template's `style.css` would need to be self-contained for installation. A build step that inlines the shared CSS would solve this.

5. **White band in dark mode PDF:** Waiting on iA Writer to support page background colors in export. No workaround exists.

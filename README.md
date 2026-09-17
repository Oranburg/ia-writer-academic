# iA Writer Academic Templates

A family of [iA Writer](https://ia.net/writer) templates for academic writing, legal scholarship, and book production. Built on the Oranburg Style system.

## Templates

| Template | Use Case | Print Format |
|:--|:--|:--|
| **Oranburg Screen** | On-screen reading and editing | Plain print, 1 in margins |
| **Oranburg Draft** | Working manuscripts | 8.5 x 11, 1 in margins, Crimson Text 12pt, 1.15 spacing |
| **Oranburg Law Review** | Bluebook-compliant law review manuscripts | 8.5 x 11, 1 in / 1.25 in margins, title page, legal outline numbering (I, A, 1, i, a) |
| **Oranburg Submission** | Journal submission | 8.5 x 11, 1 in margins, Times New Roman 12pt, double-spaced |
| **Oranburg US Trade** | Scholarly monographs | 6 x 9, gutter margin, running headers |
| **Oranburg Digest** | Essays and pamphlets | 5.5 x 8.5, compact margins |
| **Oranburg Executive** | Law school casebooks | 7 x 10, wide text block |

## Design Principles

All templates share a consistent on-screen experience with differentiated print output.

**On screen:** Color-coded heading hierarchy helps you see document structure at a glance. Crimson Text body (Roboto in Oranburg Screen), Oswald headings, comfortable line spacing. Text size follows iA Writer's View > Font Size. Full dark mode support with pure black (`#000000`) background.

**In print/PDF:** All black text. Hierarchy expressed through font family, weight, and size only. Each template targets a specific page size and margin set.

### Heading Colors

| Level | Light Mode | Dark Mode |
|:--|:--|:--|
| Title (first H1) | Deep Blue `#0A3255` | Yellow `#FFD65C` |
| H1 (sections) | Deep Blue `#0A3255` | Light Blue `#6DACDE` |
| H2 (subdivisions) | Bright Blue `#2459A9` | Teal `#B5E1E1` |
| H3 (sub-subdivisions) | Cardinal Red `#B21F2C` | Light Red `#E96955` |
| H4+ | Black `#000000` | White `#FFFFFF` |

### Typography

| Role | Font | Source |
|:--|:--|:--|
| Body text | Crimson Text | [Google Fonts](https://fonts.google.com/specimen/Crimson+Text) |
| Headings | Oswald | [Google Fonts](https://fonts.google.com/specimen/Oswald) |
| UI / Sans body | Roboto | [Google Fonts](https://fonts.google.com/specimen/Roboto) |
| Code | Roboto Mono | [Google Fonts](https://fonts.google.com/specimen/Roboto+Mono) |

Install Crimson Text, Oswald and Roboto locally (Google Fonts, or `brew install --cask font-crimson-text font-oswald font-roboto`). Roboto Mono is optional. Hebrew falls back to SBL Hebrew if installed, otherwise to New Peninim MT or Times New Roman, which ship with macOS.

### Seth's Markdown Conventions

- **Footnotes** (`[^fn-label]`) print as endnotes; iA Writer has no page-bottom footnotes.
- **Citations**: a `[#CiteKey]` inside a footnote prints as the full text of its `[#CiteKey]:` definition, not as iA Writer's bracketed number. Keys without a definition show in red in Preview.
- **Law Review numbering** (I, A, 1, i, a) skips Abstract, Contents, Introduction, Conclusion, Acknowledgments and Appendix headings, and skips any heading you numbered yourself. `{{TOC}}` gets the same numbers.
- **Hebrew** paragraphs run right to left automatically.
- **Law of the Firm boxes**: an H4 starting with 📜, 💡 or 📄 plus the blockquote after it prints as a Source, Insight or Transaction box.
- `+++` forces a page break.

## Installation

### macOS

1. Run `python3 tools/build.py` (it should end with `OK 7 bundles`).
2. Double-click each `.iatemplate` bundle in Finder, drag it onto iA Writer in the Dock, or use Settings > Templates > + > Install Template. When iA Writer reports a duplicate template, choose **Replace**.
3. In Settings > Templates: under Web Preview turn **off** Number headings and Indent paragraphs (the templates do both); under Printing & PDF Export turn **on** Headers and Footers, and Title page for Law Review.
4. Set your name in Settings > Authors; templates show it as the author.
5. Before exporting a PDF, choose the paper size in **File > Page Setup**: US Letter for Draft, Law Review and Submission; a custom size of 6 x 9, 5.5 x 8.5 or 7 x 10 in (zero margins) for US Trade, Digest and Executive.

**Note:** iA Writer copies templates when installed. If you modify the originals after installation, reinstall them. To find installed templates, right-click one in Settings and select "Show in Finder."

### iOS / iPadOS

Send the `.iatemplate` folder (or the `.zip` from `python3 tools/build.py --zip`) via AirDrop, or use "Copy to iA Writer" from the Files app.

### Windows

Run `python3 tools/build.py --zip`, then in iA Writer: File, Install Template, select the `.zip` file from `dist/`. (Citations are an Apple-platform feature of iA Writer.)

## Book Templates and Lulu

The US Trade, Digest, and Executive templates are sized for [Lulu](https://www.lulu.com/) print-on-demand production. Margins follow Lulu's gutter specifications for the 151-400 page range. iA Writer takes the trim size from File > Page Setup, the top and bottom margins from `IATemplateHeaderHeight` and `IATemplateFooterHeight` in `Info.plist`, and the inside and outside margins from `--page-margin-left` and `--page-margin-right` in the template's `style.css`. WebKit cannot mirror margins, so the gutter is always on the left. See `docs/TEMPLATE-ENGINEERING.md`.

| Template | Trim Size | Gutter (Inside) | Outside | Top | Bottom |
|:--|:--|:--|:--|:--|:--|
| US Trade | 6 x 9 | 1.0 in | 0.625 in | 0.625 in | 0.75 in |
| Digest | 5.5 x 8.5 | 0.75 in | 0.5 in | 0.5 in | 0.625 in |
| Executive | 7 x 10 | 1.125 in | 0.75 in | 0.75 in | 0.875 in |

## Architecture

iA Writer copies a template bundle when it installs it, so every bundle must be self-contained. Shared CSS and JavaScript live once in `shared/` and `tools/build.py` copies them into each bundle.

```
shared/
    oranburg-variables.css      Palette, font stacks, colors, sizes, page-margin variables
    oranburg-common.css         Styling for the HTML iA Writer emits (footnotes, citations,
                                TOC, page breaks, Hebrew, running heads, title page, boxes)
    oranburg-book-base.css      Common rules for all book formats
    oranburg.js                 Citation, heading-number and box handling
tools/
    build.py                    Sync shared/ into bundles, validate, bump versions, zip
    render_test.sh              Headless render of every template (no iA Writer needed)
    ia_html.py, render.swift    Parts of the render test
tests/fixtures/sample.md        Synthetic test document

Oranburg-Screen.iatemplate/     On-screen reading (plain print)
Oranburg-Draft.iatemplate/      8.5x11 working draft
Oranburg-LawReview.iatemplate/  Bluebook law review with outline numbering
Oranburg-Submission.iatemplate/ TNR double-spaced journal submission
Oranburg-USTrade.iatemplate/    6x9 monograph
Oranburg-Digest.iatemplate/     5.5x8.5 essay/pamphlet
Oranburg-Executive.iatemplate/  7x10 casebook
```

**Edit files in `shared/`, never the copies inside a bundle.** Then run `python3 tools/build.py`, which syncs and checks everything, and commit the result. `python3 tools/build.py --bump minor` raises every template's version before a release. `docs/TEMPLATE-ENGINEERING.md` records how iA Writer 8 templates work and what was verified.

## Customization

All colors, fonts, spacing and side margins are defined as CSS custom properties in `shared/oranburg-variables.css`. To adapt the templates to a different brand or institution, edit that one file and run `python3 tools/build.py`. The Law Review title page's star note is static text in `Oranburg-LawReview.iatemplate/Contents/Resources/title.html`.

## Author

Seth C. Oranburg ([oranburg.github.io](https://oranburg.github.io))

## License

MIT

# iA Writer Academic Templates

A family of [iA Writer](https://ia.net/writer) templates for academic writing, legal scholarship, and book production. Built on the Oranburg Style system.

## Templates

| Template | Use Case | Print Format |
|:--|:--|:--|
| **Oranburg Law Review** | Bluebook law review manuscripts | 8.5 x 11, 1 in / 1.25 in margins, title page, legal outline numbering (I, A, 1, i, a) |
| **Oranburg Draft** | Working manuscripts | 8.5 x 11, 1 in margins, Times New Roman 12pt |
| **Oranburg Teaching Notes** | Class prep sheets, printed and taught from | 8.5 x 11, 1.3 in left (an annotation gutter) and 0.7 in right, 11pt |
| **Oranburg Double-Spaced** | Reading and markup copies | 8.5 x 11, 1 in margins, Times New Roman 12pt, double-spaced |
| **Oranburg Executive** | Law school casebooks | 7 x 10, gutter margin, running headers |
| **Oranburg US Trade** | Scholarly monographs | 6 x 9, gutter margin, running headers |
| **Oranburg Digest** | Essays and pamphlets | 5.5 x 8.5, compact margins |

### Law Review and Double-Spaced

Law Review is the article: your own outline numbering, a title page, a table of contents, tight leading, and a footer carrying the draft notice. Use it for what you read, for what you send a colleague, and for what a journal receives when the journal states no format of its own.

Double-Spaced is the same article set for someone holding a pen: Times New Roman 12pt, double-spaced, so there is room to write between the lines. Use it for a reader who will mark it up and for the journals that ask for double spacing. The name states the format itself, because a law review article is already a submission and the old name "Submission" left the two templates indistinguishable.

The retired **Oranburg Screen** template sits in `archive/`, where `tools/build.py` leaves it alone.

## Design Principles

All templates share a consistent on-screen experience with differentiated print output.

**On screen:** Color-coded heading hierarchy helps you see document structure at a glance. Times New Roman throughout, comfortable line spacing. Text size follows iA Writer's View > Font Size. Full dark mode support with pure black (`#000000`) background.

**In print/PDF:** All black text, one family. Hierarchy is expressed through size, weight, style, case and space, never by changing the face. Each template targets a specific page size and margin set.

### Heading Colors

| Level | Light Mode | Dark Mode |
|:--|:--|:--|
| Title (first H1) | Deep Blue `#0A3255` | Yellow `#FFD65C` |
| H1 (sections) | Deep Blue `#0A3255` | Light Blue `#6DACDE` |
| H2 (subdivisions) | Bright Blue `#2459A9` | Teal `#B5E1E1` |
| H3 (sub-subdivisions) | Cardinal Red `#B21F2C` | Light Red `#E96955` |
| H4+ | Black `#000000` | White `#FFFFFF` |

### Typography

**Times New Roman sets everything**: body text, all six heading levels, running
heads and folios. That is the author's ruling of 2026-09-17. Nothing in document
text is condensed, sans, or another serif.

| Role | Font | Getting it |
|:--|:--|:--|
| Everything | Times New Roman | ships with macOS and with Microsoft Office |
| The same, in a build | Tinos | `brew install --cask font-tinos` |
| Code | Roboto Mono | `brew install --cask font-roboto-mono` (optional; falls back to SF Mono or Menlo) |
| Heavily accented Hebrew | Ezra SIL | `brew install --cask font-ezra-sil` (optional; see below) |

On a Mac nothing needs installing: Times New Roman is already there.

**Tinos is Times New Roman's metric twin**, not a lookalike. Every advance width
and the line metrics match it to the unit, so a document paginates identically.
Times New Roman is licensed with the system and may not be copied into a
repository. Any build that vendors its fonts and makes its own PDFs therefore
uses Tinos, and Times New Roman never enters that build.
`python3 tools/font_metrics.py` re-checks the match.

**The heading ladder**, one family, each level separated from the one above by
something other than the face:

| Level | Size | Style | Space above |
|:--|--:|:--|--:|
| H1 | 16pt | bold | 28pt |
| H2 | 14pt | bold | 22pt |
| H3 | 13pt | bold | 8pt |
| H4 | 12pt | bold italic | 7pt |
| H5 | 12pt | italic | 6pt |
| H6 | 11pt | capitals, tracked, grey | 6pt |

The space above decreases strictly, so no level ever has more air than the one
it belongs to. The large step between H2 and H3 is deliberate: the two are one
point apart, too little for a reader to see, so space carries the difference.

**No small caps anywhere.** Times New Roman has no drawn small caps, so every
renderer fakes them by shrinking capitals and thinning their strokes. Where a
book would use small caps, these templates use real capitals, tracked: H6, Law
Review's Part headings, and every running head.

**Leading: 1.22 declared, 1.1875 rendered.** WebKit, which is what iA Writer
prints through, sets lines on whole pixels and rounds down. So the 1.22 in the
stylesheet prints at 12pt as 19/16, or 14.25pt, and that is the house value.
Teaching Notes declares 1.1 and prints 1.0909. Double-Spaced prints at exactly
2.0. `docs/TYPOGRAPHY-SPEC.md` section 4.0 has the measurements.

The full specification, H1 through H6 and every iA Writer feature, is in
`docs/TYPOGRAPHY-SPEC.md`.

### Hebrew and Aramaic

`Conventions/hebrew-sources.md` in the iA Writer library is the standard, and the templates implement that file.

**Direction** is left to Unicode bidi. A paragraph, heading, list item or cell whose first strong character is Hebrew runs right to left and is set flush right; an English paragraph holding an inline Hebrew word stays left to right. An explicit `dir="rtl"` still wins.

**Leading.** Hebrew carrying nikud, and more so ta'amei ha-miqra, needs more room between lines than the Latin body's leading. Any block that starts Hebrew gets 1.5 in print and 1.7 on screen, and it is set ragged, because justification makes WebKit stretch the spaces around a maqaf and push the points off their letters.

**The three tiers** are styled as the convention defines them.

- *Tier 1, quotation.* Two stacked blockquotes, Hebrew then English, with the citation and edition italicized below. The three parts close up into one unit, the rule sits on the right of the Hebrew block where the text starts, and the unit stays on one page.
- *Tier 2, teaching block.* Hebrew, then the romanization in italic, then the gloss in quotation marks. The three lines are grouped, take no first-line indent, and are set off from the body text above and below.
- *Tier 3, inline gloss.* A Hebrew word inside an English sentence is handled by the direction rule above.

**Flag strings** are boxed so they are visible. `[Editorial nikud: verify]`, `[Vocalization: ...]`, `[Gloss pending]`, `[Unverified: no corpus hit]`, `[Not fetched: ...]` and `[Mixed register: needs human]` show in the flag color on screen and boxed in black in print. They stay visible in print on purpose: a page that looks finished while a vocalization is still unattributed is worse than a page that says so. `[Aramaic]` marks the language of a phrase, so it is boxed in grey.

**Fonts.** Hebrew is set in Times New Roman's own Hebrew, which carries the full
cantillation (ta'amei ha-miqra) and positions its own marks. It needs one
correction. Times draws Hebrew small beside its own capitals: its alef stands at
0.837 of its cap height, where faces drawn for both scripts sit near 0.90. So
`oranburg-variables.css` scales Times's Hebrew, and only its Hebrew, to 107.5%
with `size-adjust`. Latin text is untouched.

| Face | Used for | Hebrew scale |
|:--|:--|--:|
| Times New Roman | all Hebrew, when installed | 107.5% |
| Tinos | all Hebrew, where Times is absent | 100%, already at 0.904 |
| Ezra SIL | a heavily accented passage, marked `.hebrew-block` | 88%, since it runs large |

Ezra SIL is the best cantillation font available, and the switch to it takes a
whole element, never a single word. Split a word across two fonts and its
accents detach from their letters, because a mark can only be positioned
against a letter from its own font.

Frank Ruhl Libre, David Libre and Heebo are not used: none of them has
cantillation glyphs. Where a different Hebrew face is right, as for unpointed
modern text read by native readers, `--font-hebrew-override` changes it in one
line. That breaks the pagination guarantee, so re-measure afterwards.

### Seth's Markdown Conventions

- **Footnotes** (`[^fn-label]`) print as endnotes; iA Writer has no page-bottom footnotes. See the limits section below.
- **Citations**: a `[#CiteKey]` inside a footnote prints as the full text of its `[#CiteKey]:` definition, in place of iA Writer's bracketed number. A key whose definition is still missing shows in red in Preview.
- **The first H1 is the article title** in every template: centered, unnumbered, and left out of the Contents. A file that opens with a section heading gives that section up to the title styling, so Law Review shows a warning in Preview when it recognizes the first heading as a section.
- **Law Review numbering** (I, A, 1, i, a) skips Abstract, Contents, Introduction, Conclusion, Acknowledgments and Appendix headings, and skips any heading you numbered yourself. `{{TOC}}` gets the same numbers, and leaves out the title, the Contents heading itself and the Law of the Firm boxes.
- **Hebrew** paragraphs run right to left automatically. See above.
- **Law of the Firm boxes**: an H4 starting with 📜, 💡 or 📄 plus the blockquote after it prints as a Source, Insight or Transaction box.
- `+++` forces a page break.

## Installation

### macOS

1. Run `python3 tools/build.py` (it should end with `OK 7 bundles`).
2. Double-click each `.iatemplate` bundle in Finder, drag it onto iA Writer in the Dock, or use Settings > Templates > + > Install Template. When iA Writer reports a duplicate template, choose **Replace**.
3. In Settings > Templates: under Web Preview turn **off** Number headings and Indent paragraphs (the templates do both); under Printing & PDF Export turn **on** Headers and Footers, and Title page for Law Review.
4. Set your name in Settings > Authors; templates show it as the author.
5. Before exporting a PDF, choose the paper size in **File > Page Setup**: US Letter for Law Review, Draft, Double-Spaced and Teaching Notes; a custom size of 7 x 10, 6 x 9 or 5.5 x 8.5 in (zero margins) for Executive, US Trade and Digest.

**Note:** iA Writer copies templates when installed. If you modify the originals after installation, reinstall them. To find installed templates, right-click one in Settings and select "Show in Finder."

### iOS / iPadOS

Send the `.iatemplate` folder (or the `.zip` from `python3 tools/build.py --zip`) via AirDrop, or use "Copy to iA Writer" from the Files app.

### Windows

Run `python3 tools/build.py --zip`, then in iA Writer: File, Install Template, select the `.zip` file from `dist/`. (Citations are an Apple-platform feature of iA Writer.)

## Books: the export is not the interior

The Executive, US Trade and Digest templates are sized for [Lulu](https://www.lulu.com/) print-on-demand, and reaching a usable interior takes one step after the export.

A bound book needs the wider margin on the spine, and the spine is on the left of a recto page and the right of a verso page. WebKit, which is what iA Writer prints through, has no notion of recto and verso: the left margin the CSS sets is the left margin of every page. Sending an iA Writer export straight to Lulu therefore puts the gutter on the wrong side of every even page.

So the templates export a **symmetric** margin, each side half of inside plus outside, and `tools/make_book.sh` moves every page toward its own spine:

```
tools/make_book.sh executive ~/Downloads/Casebook.pdf
```

That writes `Casebook-book.pdf` with the inside margin on the bound edge of every page. Nothing is scaled or resampled; each page is drawn once into a new PDF under a translation, so text stays text and the embedded fonts stay embedded. The `tests/fixtures/sample.md` render measures out exact, to a tenth of a point, on all three trims.

| Template | Trim | Inside (spine) | Outside | Exported symmetric | Shift applied |
|:--|:--|:--|:--|:--|:--|
| Executive | 7 x 10 | 1.125 in | 0.75 in | 0.9375 in | 13.5 pt |
| US Trade | 6 x 9 | 1.0 in | 0.625 in | 0.8125 in | 13.5 pt |
| Digest | 5.5 x 8.5 | 0.75 in | 0.5 in | 0.625 in | 9 pt |

Top and bottom margins come from `IATemplateHeaderHeight` and `IATemplateFooterHeight` in each `Info.plist`; the trim comes from File > Page Setup. Lulu's gutter allowance grows with a book's page count, so check these against Lulu's current table for the book you are actually printing, and measure one exported PDF with a ruler before a print run.

## Limits worth knowing before you rely on one

- **Footnotes print as endnotes.** iA Writer has no page-bottom footnote placement, and no template can add one. A law review article that needs footnotes on the page goes through the pandoc-to-Word pipeline.
- **`{{TOC}}` has no page numbers.** WebKit does not report page numbers to the document, so the Contents lists section titles alone.
- **Dark mode PDFs show white bands.** iA Writer wraps each page in a white container that template CSS cannot reach. Print output is designed for a white page, which is why every template forces black text and a transparent background in `@media print`.
- **Title-page metadata** comes to three fields: the file name, the author from Settings > Authors, and the date. YAML front matter stops before the template pages, so the Law Review star footnote is static text in `title.html`.

## Architecture

iA Writer copies a template bundle when it installs it, so every bundle must be self-contained. Shared CSS and JavaScript live once in `shared/` and `tools/build.py` copies them into each bundle.

```
shared/
    oranburg-variables.css      Palette, font stacks (Latin and Hebrew), colors,
                                sizes, page-margin variables
    oranburg-common.css         Styling for the HTML iA Writer emits (footnotes,
                                citations, TOC, page breaks, Hebrew tiers, running
                                heads, title page, boxes, Preview warnings)
    oranburg-book-base.css      Common rules for all book formats
    oranburg.js                 Citation, heading-number, Hebrew and box handling
tools/
    build.py                    Sync shared/ into bundles, validate, bump versions, zip
    render_test.sh              Headless render of every template (no iA Writer needed)
    ia_html.py, render.swift    Parts of the render test
    make_book.sh, impose.swift  Give an exported book PDF its binding gutter
    font_metrics.py             Re-measure the fonts the spec relies on
    retype_word_template.py     Rebuild the Word templates to the same ladder
word/                           Oranburg Article.dotx and Oranburg Submission.dotx,
                                the Word templates, matched to these
docs/TYPOGRAPHY-SPEC.md         The full typographic specification
tests/fixtures/sample.md        Synthetic test document

Oranburg-LawReview.iatemplate/    Bluebook law review with outline numbering
Oranburg-Draft.iatemplate/        8.5x11 working draft
Oranburg-TeachingNotes.iatemplate/ 8.5x11 class prep sheet with an annotation gutter
Oranburg-DoubleSpaced.iatemplate/ TNR double-spaced reading and markup copy
Oranburg-Executive.iatemplate/    7x10 casebook
Oranburg-USTrade.iatemplate/      6x9 monograph
Oranburg-Digest.iatemplate/       5.5x8.5 essay and pamphlet
archive/                          Retired templates; the build skips this folder
```

**Edit files in `shared/`, never the copies inside a bundle.** Then run `python3 tools/build.py`, which syncs and checks everything, and commit the result. `python3 tools/build.py --bump minor` raises every template's version before a release. `docs/TEMPLATE-ENGINEERING.md` records how iA Writer 8 templates work and what was verified.

## Customization

All colors, fonts, spacing and side margins are defined as CSS custom properties in `shared/oranburg-variables.css`. To adapt the templates to a different brand or institution, edit that one file and run `python3 tools/build.py`. The Law Review title page's star note is static text in `Oranburg-LawReview.iatemplate/Contents/Resources/title.html`.

## Author

Seth C. Oranburg ([oranburg.github.io](https://oranburg.github.io))

## License

MIT

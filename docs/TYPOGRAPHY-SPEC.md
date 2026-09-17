Oranburg Typography Specification
=================================

The complete typographic specification for the Oranburg iA Writer templates.
Every element iA Writer 8 can emit has an entry here, including the ones Seth
does not use today, so that a document that starts using one is already
designed for.

Written 2026-09-17 against a census of Seth's iA Writer library (1,640 authored
markdown files outside `Sources/`, 26,207 headings counted) and a measurement of
every font involved, read out of the font binaries. Where this file states a
number, that number was counted or measured. Where it states a judgment, it says
so.

`docs/TEMPLATE-ENGINEERING.md` records how iA Writer's template system works.
This file records what the templates should look like. When the two disagree
about a mechanism, the engineering notes win; when they disagree about an
appearance, this file wins.


## 1. The evidence this is built on

**Heading depth, by deepest level used per file.** H1 through H3 covers 92.1% of
authored files. H4 appears in 121 files. H5 appears in 49, essentially all of
them K casebook chapters, where it is the doctrinal sub-rule level. H6 has never
been hand-authored: the six instances in the library are in machine-ingested
text.

| Deepest level | Files | Share | Heading instances | Share |
|:--|--:|--:|--:|--:|
| none | 207 | 12.6% | | |
| H1 | 286 | 17.4% | 3,001 | 11.5% |
| H2 | 624 | 38.0% | 9,790 | 37.4% |
| H3 | 396 | 24.1% | 10,022 | 38.2% |
| H4 | 76 | 4.6% | 2,818 | 10.8% |
| H5 | 49 | 3.0% | 570 | 2.2% |
| H6 | 2 | 0.1% | 6 | 0.02% |

H5 and H6 are specified in full anyway. A level that is designed costs nothing
until it is used, and a level that is undesigned fails the first time it is.

**Heading semantics are not stable across documents,** which is the single most
important constraint on this spec. Three conventions coexist in the library:

- `#` is the document title, `##` a Part, `###` a section, `####` a subsection.
  Used by GCG, TSPT, HOW, SoL.
- `#` is a Part (`# I.`), with no document-title H1 at all. Used by SFCG v5.
- `##` is a chapter, `###` a section, `####` and `#####` rule levels. Used by
  the K casebook.

So **no template may assume that the first H1 is the document title.** Section 4
states the rule that replaces that assumption.

**Feature frequency**, counted across the same 1,640 files:

| Feature | Files | Notes |
|:--|--:|:--|
| Tables | 386 | Heaviest in teaching materials, memos, syllabi |
| Blockquotes | 335 | Case excerpts, statutory text, call and response |
| Footnotes `[^…]` | 294 | 150 to 672 per article where present |
| Hebrew | 152 | Concentrated in MH, TOURO, AotV |
| Citations `[#…]` | 79 | LotF and LG |
| Images | 31 | Almost entirely scraped source material |
| Page breaks `+++` | 17 | Exam and handout pagination |

Footnotes are the most demanding feature in the corpus: an article routinely
runs 500 to 1,700 lines of body against 300 to 700 notes. The endnote apparatus
gets the most attention of any single element here.

The largest single document is the assembled casebook, 19,318 lines and 3.27 MB.
Every rule in this file has to survive it.


## 2. The families

Measured from the font binaries on 2026-09-17. "Real small caps" means the font
contains an OpenType `smcp` feature; where it does not, WebKit and Microsoft
Word both synthesize small caps by scaling capitals down, which leaves their
strokes lighter than the capitals beside them.

| Family | Styles available | Weights | Real italic | Real small caps | Hebrew |
|:--|:--|:--|:--|:--|:--|
| Crimson Text | 6 static | 400, 600, 700 | yes | **no** | no |
| Crimson Pro | variable + italic | 200 to 900 | yes | **no** | no |
| Oswald | variable | 200 to 700 | **no** | **no** | no |
| EB Garamond | static + SC families | 400, 500, 600, 700 | yes | **yes** (`smcp`, `c2sc`) | no |
| Cardo | 3 static | 400, 700 | yes | **yes** | yes, with cantillation |
| Roboto | variable | 100 to 900 | yes | yes | no |
| Times New Roman | 4 static | 400, 700 | yes | no | yes, with cantillation |

Two consequences govern the rest of this file.

**Oswald cannot support a full heading ladder.** It has no italic, so it cannot
express the subordinate levels that legal and scholarly convention sets in
italic, and it has no small caps. It is a condensed display grotesque, and it is
at its best large or in a running head where condensation is a virtue.

**Small caps require a face that draws them.** Crimson Text does not. This is
not an iA Writer limitation: Word synthesizes for the same font, for the same
reason. Verified by rendering both in WebKit, the engine iA Writer uses.

### 2.1 The variables

All of this is set in `shared/oranburg-variables.css`. Changing a family is one
edit followed by `python3 tools/build.py`.

| Variable | Role | Value |
|:--|:--|:--|
| `--font-body` | Body text, and every heading level | Crimson Text |
| `--font-heading` | Running heads and footers only | Oswald |
| `--font-ui` | Screen chrome only, never document text | Roboto |
| `--font-mono` | Code, and the transaction box | Roboto Mono |
| `--font-submission` | The Double-Spaced PDF, all of it | Times New Roman |
| `--font-hebrew-serif` | Hebrew inside body text | see section 9 |
| `--font-hebrew-sans` | Hebrew inside running heads | see section 9 |
| `--font-hebrew-taamim` | Any element that includes cantillation | see section 9 |

**One family sets all six heading levels.** Levels are distinguished by size,
weight, style, case, alignment and indentation, never by changing family. This
is the standing rule; it was broken twice in earlier drafts of these templates
and it is stated here so it is not broken again.


## 3. Vertical space, the page-count budget

The teaching prep sheets are the most-printed documents, and the current
templates set a 2,585-word sheet in 7 pages. Measured against `Oranburg-Draft`,
roughly 84 em of that document is inter-block whitespace, about 14 vertical
inches, about 1.5 full pages of a 7-page document. Heading air is the largest
single item: 17 headings at about 2 em of leading space each.

The old heading margins and their replacements:

| Level | Was, margin-top | Now | Now, margin-bottom |
|:--|--:|--:|--:|
| H1 | 2.00em | **1.40em** | 0.30em |
| H2 | 1.75em | **1.00em** | 0.25em |
| H3 | 1.50em | **0.70em** | 0.20em |
| H4 | 1.25em | **0.60em** | 0.15em |
| H5 | 1.00em | **0.50em** | 0.15em |
| H6 | 1.00em | **0.50em** | 0.15em |

Butterick's rule is that space above and below is the most effective and most
subtle way to mark a heading, which argues for keeping some; the page count
argues for less. These values keep the signal and halve the cost.

Two further economies, both specified in their own sections: blockquotes take a
left indent only, never a symmetric one (section 6.3), and the Teaching Notes
template cuts the header and footer bands that cost Draft two inches of every
sheet (section 10.7).


## 4. Headings, H1 through H6

### 4.1 The document title

**The first H1 is the document title only when it is neither numbered nor a
structural name.** A heading whose text begins with a number or a roman numeral
(`# I. Formation`) is a Part, because that is how SFCG is written. A heading
reading Abstract, Contents, Introduction, Conclusion, Acknowledgments, Appendix,
Preface, Foreword, Epigraph or Summary is a structural section. Anything else in
first position is the title.

When a title is found it is centered, unnumbered, and left out of `{{TOC}}`.
When none is found, every H1 is an ordinary H1 and nothing is centered. The
Preview warning that used to fire on a structural first H1 is retained, because
that case is still usually a mistake.

For PDF export the title page is `title.html`, which takes the file name rather
than the first heading. The two are independent by design.

### 4.2 The ladder

Against a 12pt body. Sizes follow Butterick: the smallest increment that shows,
so the top of the ladder is 14pt and not 16pt.

| Level | Size | Weight | Style | Case | Alignment |
|:--|--:|--:|:--|:--|:--|
| H1 | 14pt | 700 | roman | letterspaced caps, 0.04em | centered |
| H2 | 13pt | 700 | roman | as typed | flush left |
| H3 | 12pt | 700 | roman | as typed | flush left |
| H4 | 12pt | 700 | *italic* | as typed | flush left |
| H5 | 12pt | 400 | *italic* | as typed | flush left |
| H6 | 12pt | 400 | *italic* | as typed | flush left, indented 0.25in |

Six levels, one family, distinguished by four devices. H6 is specified even
though the library contains no hand-authored instance.

On screen the same ladder runs in em against the root size, so View > Font Size
scales it, and the color hierarchy of section 12 applies.

### 4.3 Small caps

Law review convention sets Part headings in small caps. Crimson Text contains no
small-cap glyphs, so `font-variant-caps: small-caps` gives synthesized ones.

**Word is no better, and on one point it is worse.** OOXML defines
`w:smallCaps` as displaying lowercase "as their capital letter character
equivalents in a font size two points smaller." That definition never mentions
the font: Word's checkbox is a display transform on the run, so it ignores real
small-cap glyphs even in a font that has them. The reduction is a flat two
points, so the same character style comes out at different proportions at 14pt
and at 10pt. Butterick: "Don't click on the small-cap formatting box in your
word processor. Ever. This option does not produce small caps. It produces
inferior counterfeits."

Measured on this Mac, rendering an H at 300px:

| | Real (EB Garamond) | Synthesized (Crimson Text) |
|:--|--:|--:|
| Small-cap height, share of cap height | 76.7% | 70.0% |
| Stem width, share of cap stem | 90.5% | 71.6% |
| Stem ÷ height, small cap | 0.192 | 0.134 |
| Stem ÷ height, full cap | 0.163 | 0.131 |

The last two rows are the whole story. A drawn small cap gets about 18% more
weight per unit of height than the capital beside it, because the designer put
it there. A synthesized one shows the same ratio as the capital, which is the
signature of a pure linear scale with nothing compensated. The line then reads
grey and slightly pinched while its opening capital looks too heavy.

**Where the face has no `smcp`,** the templates set H1 in letterspaced full
capitals at 92%, which is what a book does when small caps are unavailable.

**Where the face has `smcp`,** the rule is:

```css
h1 { font-variant-caps: small-caps; }
```

Three implementation points, all measured:

- Use `font-variant-caps`, not `font-feature-settings`. The latter is
  all-or-nothing, any child that redeclares it discards the parent's whole list,
  and it does nothing at all on a font without the feature.
- **The CSS family name must be the CoreText family name.** With
  `font-family: "EB Garamond 12"`, which is the file's full name, WebKit drew
  Garamond and still synthesized the small caps. With `font-family: "EB
  Garamond"`, the real family, the feature applied. Optical sizes are styles
  inside that family and CSS cannot select them.
- Ship with `font-synthesis-small-caps: auto`, the default, so a later font
  change cannot silently blank the styling. Setting it to `none` is a
  diagnostic: every counterfeit run reverts to plain lowercase, which makes the
  fakes name themselves.

A separate small-caps family such as EB Garamond SC is the more portable route,
because it is a font and survives any tool including Word. In these templates it
costs more than it returns: that family ships Regular only, so a bold Part
heading would get a synthetic bold in trade for a real small cap, and a font
switch drops any Hebrew in the run to a different fallback.

### 4.4 Numbering

Automatic numbering is Law Review only, enabled by `data-oranburg-outline`.
It is I, A, 1, i, a across H1 to H5, in CSS counters so it survives scripts
being off. Structural headings are skipped. A heading the author numbered by
hand is detected and not numbered twice; 37.4% of the library uses hand
numbering, so this case is common and not an edge.

H6 is never numbered.

### 4.5 Keeping a heading with its text

WebKit ignores `page-break-after: avoid`. Every heading therefore gets a
`::after` pseudo-element of 60pt height with a matching negative bottom margin,
so that `page-break-inside: avoid` keeps roughly four lines of following text
with the heading. All six levels get this.


## 5. Text

| Element | Print | Screen |
|:--|:--|:--|
| Body paragraph | 12pt, 1.15 leading, first line indent 0.5in, no space between | 1rem, 1.6 leading, no indent, 1em between |
| First paragraph after any heading, blockquote, list, table, figure or page break | no indent | as above |
| `.no-indent` | no indent | no indent |
| Emphasis `*x*` | italic | italic |
| Strong `**x**` | weight 600 | weight 600 |
| Both | 600 italic | 600 italic |
| Strikethrough `~~x~~` | line-through, kept in print | line-through |
| Highlight `==x==` | `<mark>`, 10% grey in print | yellow wash at 55% |
| Superscript, subscript | 0.7em, no line-height disturbance | same |
| Hard line break | honored | honored |
| Hashtag `#tag` | body color | link color |
| Wikilink `[[x]]` | body color | link color |
| Link | black, no underline | link color, underlined |

Print keeps a link's text and drops its decoration, because a printed underline
shows no destination. The URL is not expanded; a citation supplies it.


## 6. Blocks

### 6.1 Lists

Unordered and ordered, nested to any depth. Markers: disc, then circle, then
square; decimal, then lower-alpha, then lower-roman. Print leading 1.15,
`li` bottom margin 0.15em, block margin 0.4em. A paragraph inside a list item
takes no first-line indent.

Nested list indentation is 1.5em per level, capped at three visual levels of
indent however deep the nesting goes, so a deep list does not walk off the
measure.

### 6.2 Task lists

iA Writer emits `<li class="task-list-item"><input type="checkbox" disabled>`.
The marker is suppressed, the box is aligned to the first baseline, and the two
app options are honored: `.task-list-item-checked-fade` sets a checked item to
the muted color, `.task-list-item-checked-line-through` strikes it. In print the
checkbox is drawn as an outlined square so it survives a monochrome printer.

### 6.3 Blockquotes

The one economy that matters most for teaching material. A blockquote takes a
**left indent only, 0.3in, with no right indent**, because a symmetric 0.5in
indent on both sides costs an inch of measure and turns three quoted lines into
five.

Print: 11pt, 1.2 leading, no italic, no border. Screen: a 3pt left rule in the
rule color and 1.2em of left padding.

Adjacent blockquotes separated by a blank line close up to 0.35em, so statutory
text set as several quoted subsections reads as one block.

Nested blockquotes add 0.3in per level and, on screen, a second rule.

### 6.4 Code

Inline code: `--font-mono` at 0.9em with a light background. Fenced and indented
blocks: 0.9em, wrapped rather than scrolled in print, 0.75em margins, and
`page-break-inside: avoid`. Syntax highlighting is not attempted; iA Writer does
not emit token classes.

### 6.5 Horizontal rules

`---` becomes `<hr>`: a hairline in the rule color, 30% width, flush left, 1em
above and below. It is a thematic break, not a page break.

### 6.6 Page breaks

`+++` becomes `<div class="page-break">`. In print it forces a break and the
following element loses its top margin. On screen it draws a dashed rule so the
break is visible while writing. Used in 17 files, all exam and handout material.

### 6.7 Definition lists

MultiMarkdown emits `<dl><dt><dd>`. The term is set in weight 600, the
definition indented 0.3in with no first-line indent, and the pair is kept
together across a page break. Unused in the library today; specified so it
works.


## 8. Tables

The second most common block feature in the corpus, and the heaviest element in
teaching materials, memos and syllabi.

Print: body font at 11pt, full measure, `border-collapse`. A 1pt rule above and
below the header row and below the last row, hairlines between body rows, and no
vertical rules at all. Cell padding 0.3em by 0.5em, top-aligned. Numeric columns
take `font-variant-numeric: tabular-nums`. Column alignment follows the
markdown's own colons.

A row never splits across a page. A table longer than one page repeats nothing,
because iA Writer emits no `<thead>` marker that WebKit will repeat; a long
table should be broken by hand.

A caption sits below the table, 10pt italic in the muted color, flush left.

Smart Tables, which is a CSV content block rendered as a table, takes the same
styling. `IATemplateSupportsSmartTables` stays at its default of YES.


## 9. Hebrew and Aramaic

`Conventions/hebrew-sources.md` in the iA Writer library is the standard; these
templates implement it. 152 files include Hebrew. Full detail is in the README;
what belongs here is the type.

**Direction** comes from Unicode bidi: any block whose first strong character is
Hebrew is set right to left and flush right, and is never justified.

**Size.** Hebrew has no ascender or descender to align against, so each face
sets at a different apparent size beside the same Latin. The Hebrew is scaled so
its alef matches the Latin cap height. Crimson Text's cap measures 0.6465 em.

| Face | Alef height | Scale against Crimson Text |
|:--|--:|--:|
| Ezra SIL | 0.7051 em | 92% |
| Noto Serif Hebrew | 0.6470 em | 100% |
| Cardo | 0.6172 em | 105% |
| Tinos | 0.5918 em | 109% |
| Frank Ruhl Libre | 0.5900 em | 110% |
| Heebo | 0.5752 em | 112% |
| Noto Sans Hebrew | 0.5840 em | 111% |
| Times New Roman | 0.5542 em | 117% |
| David Libre | 0.5278 em | 122% |
| Arial Hebrew | 0.5180 em | 125% |
| New Peninim MT | 0.4980 em | 130% |

**Leading** is 1.5 in print and 1.7 on screen, because nikud sits below the
baseline and ta'amim above it.

**Cantillation** switches the whole element to a face that draws it. It is never
a per-character fallback: GPOS anchors are defined within one font, so a mark
from one font has nothing to attach to on a letter from another.

**Tiers**, per the convention: Tier 1 is two stacked blockquotes with an italic
citation line, closed up into one unit and kept on one page. Tier 2 is Hebrew,
romanization in italic, then a quoted gloss, grouped and set off. Tier 3 is a
word inline in English and needs only the direction rule.

**Flag strings** are boxed and stay visible in print.


## 10. Per-template geometry

Paper comes from File > Page Setup. Top and bottom margins are
`IATemplateHeaderHeight` and `IATemplateFooterHeight`. Left and right are CSS.

| Template | Paper | Top | Bottom | Left | Right | Body | Leading |
|:--|:--|--:|--:|--:|--:|--:|--:|
| Law Review | Letter | 72pt | 72pt | 1.25in | 1.25in | 12pt | 1.15 |
| Draft | Letter | 72pt | 72pt | 1in | 1in | 12pt | 1.15 |
| Double-Spaced | Letter | 72pt | 72pt | 1in | 1in | 12pt | 2.0 |
| **Teaching Notes** | Letter | 40pt | 40pt | **1.3in** | **0.7in** | 11pt | 1.1 |
| Executive | 7 x 10 | 54pt | 63pt | 0.9375in | 0.9375in | 12pt | 1.15 |
| US Trade | 6 x 9 | 45pt | 54pt | 0.8125in | 0.8125in | 12pt | 1.15 |
| Digest | 5.5 x 8.5 | 36pt | 45pt | 0.625in | 0.625in | 12pt | 1.15 |

The three book templates use a symmetric side margin and take their gutter
from `tools/make_book.sh` after export; see the engineering notes.

### 10.7 Teaching Notes, the new template

The most-printed document in the corpus has had no template. Its requirements
are specific and none of the six existing bundles meets them.

**A 1.3in left margin against a 0.7in right.** Seth is left-handed and
annotates down the left side of the sheet. This is recorded in
`LawOS/lawos/emit/classpack.py`, whose own test asserts that the left margin
must remain the widest on the page. The left margin is an annotation gutter, not
a symmetry.

**Letter paper**, because that is what the department's printers hold.

**Small header and footer bands**, 40pt rather than 72pt, recovering nearly an
inch of every sheet. The footer shows the page number and nothing else.

**11pt body at 1.1 leading**, and the tightened heading margins of section 3.

**Run-in H3.** A prep sheet's H3 level is a run of statutory section headings,
each introducing three to six quoted lines. Set as a sidehead, the heading and
its first line share a line, which recovers a line per section.

Target: a 2,585-word prep sheet in three pages rather than seven.


## 11. Footnotes, citations and contents

### 11.1 Footnotes

iA Writer's footnotes are endnotes; there is no page-bottom placement, and no
template can add one. An article needing true footnotes goes through the
pandoc-to-Word pipeline.

The reference is a superscript figure at 0.7em, raised, in the body font, with
no underline and no color. The note list is 10pt at 1.2 leading, numbers
outside, 0.4em between notes, no first-line indent within a note. The separating
rule is 33% width, flush left. A note never splits across a page. The return
arrow is screen only.

At 300 to 700 notes this apparatus is most of the back of the document, so it is
set as tight as legibility allows.

### 11.2 Citations

A `[#Key]` inside a footnote prints as the full text of its definition, with the
duplicate bibliography entry hidden. An undefined key shows in the flag color on
screen and as its literal bracketed text in print.

### 11.3 Contents

`{{TOC}}` is nested lists with no markers, the numbers written on by the outline
script, no page numbers, and the document title, the Contents heading itself and
any Law of the Firm box left out. In Law Review the Contents ends its page.


## 12. Screen, color and app settings

Color hierarchy applies on screen only; print is black throughout. Title and H1
deep blue, H2 bright blue, H3 cardinal red, H4 and below black, with the night
mode palette on a pure black ground.

`View > Font Size` sets `html.content-size-*`; the scale matches iA Writer's own
templates so the keyboard shortcuts behave normally.

Settings that must be **off**, because the templates do this work: Number
headings, Indent paragraphs. Settings that must be **on** for export: Headers,
Footers, and Title page for Law Review.

`.center-headings` is honored where the app sets it. `.emphasis-mark` and the
two task-list options are honored.


## 13. Math, content blocks and other features

**Math.** `IATemplateSupportsMath` stays YES. KaTeX output is left to KaTeX;
display math is centered with 0.75em above and below and kept off a page break.
Inline math does not disturb leading.

**Content blocks.** An image block becomes `<figure><img><figcaption>`: centered,
max width 100%, caption 10pt italic centered below, the whole kept on one page. A
CSV block becomes a table and takes section 8. A markdown block is rendered
inline and takes every rule here. Images are 31 files in the library and almost
all scraped, so this is specified rather than tuned.

**Law of the Firm boxes.** An H4 beginning with a scroll, bulb or page emoji,
with the blockquote after it, becomes a Source, Insight or Transaction box. The
title bar and body share a fill that prints. The transaction box is set in the
mono face. Title and body are kept together across a page break.

**Front matter.** iA Writer hides YAML front matter from the preview and does
not pass it to template pages, so no template may depend on it. The Law Review
star footnote is static text in `title.html` for this reason.

**HTML passthrough.** Inline HTML is rendered. No template styles it beyond
what it inherits.


## 14. What is deliberately not specified

- Page-bottom footnotes. Not available.
- Repeating table headers. WebKit will not.
- Mirror margins in the export. Handled after export by `tools/impose.swift`.
- Page numbers in `{{TOC}}`. WebKit does not report them to the document.
- Syntax highlighting. iA Writer emits no token classes.

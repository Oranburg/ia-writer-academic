# iA Writer Academic Templates

A family of [iA Writer](https://ia.net/writer) templates for academic writing, legal scholarship, and book production. Built on the Oranburg Style system.

## Templates

| Template | Use Case | Print Format |
|:--|:--|:--|
| **Oranburg Screen** | On-screen reading and editing | No print output |
| **Oranburg Draft** | Working manuscripts | 8.5 x 11, Crimson Text 12pt, 1.15 spacing |
| **Oranburg Law Review** | Bluebook-compliant law review manuscripts | 8.5 x 11, legal outline numbering (I, A, 1, i, a) |
| **Oranburg Submission** | Journal submission | 8.5 x 11, Times New Roman 12pt, double-spaced |
| **Oranburg US Trade** | Scholarly monographs | 6 x 9, mirror margins, running headers |
| **Oranburg Digest** | Essays and pamphlets | 5.5 x 8.5, compact margins |
| **Oranburg Executive** | Law school casebooks | 7 x 10, wide text block |

## Design Principles

All templates share a consistent on-screen experience with differentiated print output.

**On screen:** Color-coded heading hierarchy helps you see document structure at a glance. Crimson Text body, Oswald headings, comfortable line spacing. Full dark mode support with pure black (`#000000`) background.

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

For best results, install all four font families locally from Google Fonts.

## Installation

### macOS

Double-click any `.iatemplate` folder in Finder, or drag it onto the iA Writer icon in the Dock. You can also add templates in iA Writer's Settings, under Templates.

**Note:** iA Writer copies templates when installed. If you modify the originals after installation, reinstall them. To find installed templates, right-click one in Settings and select "Show in Finder."

### iOS / iPadOS

Send the `.iatemplate` folder via AirDrop, or use "Copy to iA Writer" from the Files app.

### Windows

Zip the `.iatemplate` folder first, then in iA Writer: File, Install Template, select the `.zip` file.

## Book Templates and Lulu

The US Trade, Digest, and Executive templates are sized for [Lulu](https://www.lulu.com/) print-on-demand production. Margins follow Lulu's gutter specifications for the 151-400 page range. For books outside that range, adjust the `@page` margin values in the template's `style.css`.

| Template | Trim Size | Gutter (Inside) | Outside | Top | Bottom |
|:--|:--|:--|:--|:--|:--|
| US Trade | 6 x 9 | 1.0 in | 0.625 in | 0.625 in | 0.75 in |
| Digest | 5.5 x 8.5 | 0.75 in | 0.5 in | 0.5 in | 0.625 in |
| Executive | 7 x 10 | 1.125 in | 0.75 in | 0.75 in | 0.875 in |

## Architecture

Templates share CSS custom properties through `shared/oranburg-variables.css` (palette, fonts, spacing) and `shared/oranburg-book-base.css` (common book formatting). Each template's `style.css` imports the shared files and adds only what is specific to that format.

```
shared/
    oranburg-variables.css      Color palette, font stacks, heading colors
    oranburg-book-base.css      Common rules for all book formats

Oranburg-Screen.iatemplate/     On-screen reading (no print)
Oranburg-Draft.iatemplate/      8.5x11 working draft
Oranburg-LawReview.iatemplate/  Bluebook law review with outline numbering
Oranburg-Submission.iatemplate/ TNR double-spaced journal submission
Oranburg-USTrade.iatemplate/    6x9 monograph
Oranburg-Digest.iatemplate/     5.5x8.5 essay/pamphlet
Oranburg-Executive.iatemplate/  7x10 casebook
```

## Customization

All colors, fonts, and spacing are defined as CSS custom properties in `shared/oranburg-variables.css`. To adapt the templates to a different brand or institution, edit that one file.

## Author

Seth C. Oranburg ([oranburg.github.io](https://oranburg.github.io))

## License

MIT

#!/usr/bin/env python3
"""Approximate iA Writer 8's HTML for a Markdown file, for render tests.

iA Writer's own converter is not available outside the app. This script
runs pandoc and rewrites its output into the shapes iA Writer documents
and emits (github.com/iainc/iA-Writer-Templates, Markup.html, and the
format strings in iA Writer 8.0.7's Kit framework):

  footnote reference  <sup><a href="#fn1" id="fnr1" title="see footnote" class="footnote">1</a></sup>
  footnote list       <div class="footnotes"><hr /><ol><li id="fn1"><p>... <a class="reversefootnote">
  citation            <a class="citation" href="#fnN" title="Jump to citation">[N]<span class="citekey">Key</span></a>
  citation entry      <li id="fnN" class="citation"><span class="citekey">Key</span><p>...</p></li>
  undefined key       <span class="externalcitation">[#Key]</span>   (approximation)
  {{TOC}}             <div class="TOC"><ul>...</ul></div>
  +++                 <div class="page-break" style="page-break-before: always;"></div>

Headings are emitted without id attributes, as in iA's Markup.html, so
the templates are tested without relying on ids. Pass --ids to add them.

Usage: python3 tools/ia_html.py [--ids] input.md > fragment.html
Needs pandoc on PATH (or set PANDOC=/path/to/pandoc).
"""
import html
import os
import re
import subprocess
import sys

PANDOC = os.environ.get("PANDOC", "pandoc")


def pandoc(text, fmt="markdown-smart"):
    return subprocess.run(
        [PANDOC, "-f", fmt, "-t", "html5", "--wrap=none"],
        input=text, capture_output=True, text=True, check=True).stdout


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    keep_ids = "--ids" in sys.argv
    # iA Writer does not convert straight quotes when it renders, so the
    # default here does not either: a render should show what iA shows.
    # --smart is for a one-off reading copy whose source has straight
    # quotes, and the output then no longer matches iA Writer's.
    # A reading copy also links its bare URLs, so they are clickable in
    # the PDF and never hyphenated (see .url and a in oranburg-common.css).
    fmt = ("markdown+smart+autolink_bare_uris" if "--smart" in sys.argv
           else "markdown-smart")
    src = open(args[0], encoding="utf-8").read()

    # [#Key]: definitions
    defs = {}

    def take_def(m):
        defs[m.group(1)] = m.group(2).strip()
        return ""
    src = re.sub(r"^\[#([^\]]+)\]:[ \t]*(.+)$", take_def, src, flags=re.M)

    # citation references, with an optional [locator] before them
    cites = []

    def take_cite(m):
        cites.append((m.group(1), m.group(2)))
        return "CITETOKEN%dX" % (len(cites) - 1)
    src = re.sub(r"(?:\[([^\]^#][^\]]*)\])?\[#([^\]]+)\]", take_cite, src)

    src = re.sub(r"^\{\{TOC\}\}$", "TOCTOKEN", src, flags=re.M)
    src = re.sub(r"^\+\+\+$", "PAGEBREAKTOKEN", src, flags=re.M)
    src = re.sub(r"(?<!=)==(?=[^=\s])(.+?)(?<=[^=\s])==(?!=)", r"<mark>\1</mark>", src)

    out = pandoc(src, fmt)

    # headings: collect for the TOC, strip ids
    heads = []

    def head(m):
        level, hid, body = m.group(1), m.group(2), m.group(3)
        heads.append((int(level), hid, re.sub("<[^>]+>", "", body)))
        idattr = ' id="%s"' % hid if keep_ids else ""
        return "<h%s%s>%s</h%s>" % (level, idattr, body, level)
    out = re.sub(r'<h([1-6]) id="([^"]*)"[^>]*>(.*?)</h\1>', head, out)

    # footnotes
    def ref(m):
        n = m.group(1)
        return ('<sup><a href="#fn%s" id="fnr%s" title="see footnote" class="footnote">%s</a></sup>'
                % (n, n, n))
    out = re.sub(r'<a href="#fn(\d+)" class="footnote-ref" id="fnref\d+"[^>]*><sup>\d+</sup></a>', ref, out)
    out = re.sub(r'<a href="#fnref(\d+)" class="footnote-back"[^>]*>[^<]*</a>',
                 r'<a href="#fnr\1" title="return to article" class="reversefootnote">&#8617;&#xFE0E;</a>',
                 out)
    m = re.search(r'<section id="footnotes"[^>]*>\s*<hr />\s*<ol>(.*?)</ol>\s*</section>', out, flags=re.S)
    notes = m.group(1) if m else ""
    n_notes = len(re.findall(r"<li id=", notes))
    if m:
        out = out[:m.start()] + out[m.end():]

    # citations are numbered after the footnotes, in order of first use
    order = []
    for _, key in cites:
        if key in defs and key not in order:
            order.append(key)
    num = {k: n_notes + i + 1 for i, k in enumerate(order)}

    def cite(m):
        loc, key = cites[int(m.group(1))]
        if key not in defs:
            return '<span class="externalcitation">[#%s]</span>' % html.escape(key)
        n = num[key]
        locator = '<span class="locator">%s</span>, ' % html.escape(loc) if loc else ""
        return ('<a class="citation" href="#fn%d" title="Jump to citation">[%s%d]'
                '<span class="citekey" style="display:none">%s</span></a>'
                % (n, locator, n, html.escape(key)))
    out = re.sub(r"CITETOKEN(\d+)X", cite, out)
    notes = re.sub(r"CITETOKEN(\d+)X", cite, notes)

    cite_items = ""
    for k in order:
        body = pandoc(defs[k], fmt).strip()
        cite_items += ('\n<li id="fn%d" class="citation"><span class="citekey" style="display:none">'
                       '%s</span>%s\n</li>\n' % (num[k], html.escape(k), body))
    if notes or cite_items:
        notes = re.sub(r'<li id="fn(\d+)"[^>]*>', r'\n<li id="fn\1">', notes)
        out += '\n<div class="footnotes">\n<hr />\n<ol>\n%s%s\n</ol>\n</div>\n' % (notes, cite_items)

    # {{TOC}}
    def toc():
        parts, depth = ['<div class="TOC">\n'], 0
        for level, hid, text in heads:
            if level > depth:
                parts.append("<ul>\n" * (level - depth))
            elif level < depth:
                parts.append("</li>\n" + "</ul>\n</li>\n" * (depth - level))
            else:
                parts.append("</li>\n")
            depth = level
            parts.append('<li><a href="#%s">%s</a>' % (hid, text))
        parts.append("</li>\n" + "</ul>\n</li>\n" * (depth - 1) + "</ul>\n</div>")
        return "".join(parts)
    out = re.sub(r"<p>TOCTOKEN</p>", lambda _: toc(), out)
    out = out.replace("<p>PAGEBREAKTOKEN</p>",
                      '<div class="page-break" style="page-break-before: always;"></div>')
    sys.stdout.write(out)


if __name__ == "__main__":
    main()

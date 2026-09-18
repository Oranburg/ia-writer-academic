"""Retype an Oranburg Word template to Times New Roman.

Replaces only each target style's pPr and rPr, so Word's own wiring
(basedOn, next, link, uiPriority, qFormat) is untouched, and points the
theme's major and minor Latin fonts at Times so that no style Word
generates later -- Caption, TOC, Quote, table styles -- can fall back
to the Calibri the theme used to name.
"""
import re, sys, pathlib

TNR = ('<w:rFonts w:ascii="Times New Roman" w:eastAsia="Times New Roman" '
       'w:hAnsi="Times New Roman" w:cs="Times New Roman"/>')

def rpr(sz, bold=False, ital=False, caps=False, track=None, color=None):
    x = [TNR]                                   # ECMA-376 rPr order
    if bold:  x += ['<w:b/>', '<w:bCs/>']
    if ital:  x += ['<w:i/>', '<w:iCs/>']
    if caps:  x += ['<w:caps/>']
    if color: x += ['<w:color w:val="%s"/>' % color]
    if track: x += ['<w:spacing w:val="%d"/>' % track]
    x += ['<w:sz w:val="%d"/>' % sz, '<w:szCs w:val="%d"/>' % sz]
    return '<w:rPr>' + ''.join(x) + '</w:rPr>'

def ppr(before=None, after=0, line=293, jc=None, ind=None, keep=True):
    x = []                                      # ECMA-376 pPr order
    if keep: x += ['<w:keepNext/>', '<w:keepLines/>']
    sp = '<w:spacing'
    if before is not None: sp += ' w:before="%d"' % before
    sp += ' w:after="%d"' % after
    if line: sp += ' w:line="%d" w:lineRule="auto"' % line
    x.append(sp + '/>')
    if ind: x.append('<w:ind w:left="%d"/>' % ind)
    if jc:  x.append('<w:jc w:val="%s"/>' % jc)
    return '<w:pPr>' + ''.join(x) + '</w:pPr>'

# The general template: the iA ladder, 12pt at 1.22 (w:line 293; 240 is
# single). Space in twentieths of a point, taken from the settled ladder in
# docs/TYPOGRAPHY-SPEC.md section 3, which is designed in points:
#   H1 28pt  H2 22pt  H3 8pt  H4 7pt  H5 6pt  H6 6pt   (strictly decreasing)
# The first version of this table had 5pt above H3 and 7.2pt above H4, the
# same inversion the iA ladder had before df1d153. Keep the two in step.
ARTICLE = {
 'Normal':   (ppr(after=0, line=293, keep=False),              rpr(24)),
 'Title':    (ppr(before=0,   after=240, line=293, jc='center'), rpr(32, bold=True)),
 'Heading1': (ppr(before=560, after=96,  line=293),            rpr(32, bold=True)),
 'Heading2': (ppr(before=440, after=70,  line=293),            rpr(28, bold=True)),
 'Heading3': (ppr(before=160, after=52,  line=293),            rpr(26, bold=True)),
 'Heading4': (ppr(before=140, after=36,  line=293),            rpr(24, bold=True, ital=True)),
 'Heading5': (ppr(before=120, after=36,  line=293),            rpr(24, ital=True)),
 'Heading6': (ppr(before=120, after=33,  line=293),            rpr(22, caps=True, track=19, color='444444')),
}

# The venue template. Journals want 12pt double-spaced with headings at
# body size, so size is not available and each rung changes something
# else. The old file set H3 through H6 identically, collapsing four levels.
D = 480                                         # double spacing
SUBMISSION = {
 'Normal':   (ppr(after=0, line=D, keep=False),                rpr(24)),
 'Title':    (ppr(before=0,   after=0, line=D, jc='center'),   rpr(24, bold=True)),
 'Heading1': (ppr(before=240, after=0, line=D, jc='center'),   rpr(24, bold=True, caps=True, track=20)),
 'Heading2': (ppr(before=0,   after=0, line=D),                rpr(24, bold=True)),
 'Heading3': (ppr(before=0,   after=0, line=D),                rpr(24, bold=True, ital=True)),
 'Heading4': (ppr(before=0,   after=0, line=D),                rpr(24, ital=True)),
 'Heading5': (ppr(before=0,   after=0, line=D, ind=720),       rpr(24, ital=True)),
 'Heading6': (ppr(before=0,   after=0, line=D, ind=720),       rpr(24, caps=True, track=20)),
}

def retype(root, table):
    root = pathlib.Path(root)
    st = root / 'word' / 'styles.xml'
    s = st.read_text(encoding='utf-8')
    done = []
    for sid, (new_ppr, new_rpr) in table.items():
        m = re.search(r'(<w:style [^>]*w:styleId="%s"[^>]*>)(.*?)(</w:style>)' % sid, s, re.S)
        if not m:
            continue
        body = re.sub(r'<w:pPr>.*?</w:pPr>', '', m.group(2), flags=re.S)
        body = re.sub(r'<w:rPr>.*?</w:rPr>', '', body, flags=re.S).strip()
        s = s[:m.start()] + m.group(1) + body + new_ppr + new_rpr + m.group(3) + s[m.end():]
        done.append(sid)
    # docDefaults: no theme font behind Normal
    s = re.sub(r'<w:rFonts w:asciiTheme="minorHAnsi"[^/]*/>', TNR, s)
    s = s.replace('<w:smallCaps/>', '')         # Word only ever fakes them
    st.write_text(s, encoding='utf-8')

    for th in (root / 'word' / 'theme').glob('*.xml'):
        t = th.read_text(encoding='utf-8')
        t = re.sub(r'(<a:majorFont>\s*<a:latin typeface=")[^"]*(")', r'\1Times New Roman\2', t)
        t = re.sub(r'(<a:minorFont>\s*<a:latin typeface=")[^"]*(")', r'\1Times New Roman\2', t)
        th.write_text(t, encoding='utf-8')
    return done

if __name__ == '__main__':
    root, kind = sys.argv[1], sys.argv[2]
    print(kind, 'rewrote:', ', '.join(retype(root, ARTICLE if kind == 'article' else SUBMISSION)))

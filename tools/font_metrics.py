#!/usr/bin/env python3
"""Measure the installed faces the templates name, with no dependencies.

Two numbers decide things in docs/TYPOGRAPHY-SPEC.md and neither can be
judged by eye:

  alef / cap    How large a font draws Hebrew against its own Latin.
                Faces drawn for both scripts cluster near 0.90. A face
                below that sets Hebrew small beside its own capitals,
                which is a property of the letters and has nothing to do
                with whether they carry points or accents. Section 9
                turns this column into the size-adjust percentages.

  advance widths  Whether two faces paginate identically. Tinos stands in
                for Times New Roman in any build that cannot ship
                Microsoft's font, and that substitution is only safe
                because every advance width and the hhea metrics match to
                the unit. Section 2.1 depends on it; re-run this after any
                font update rather than assuming it still holds.

Usage:
    python3 tools/font_metrics.py              # the faces the templates name
    python3 tools/font_metrics.py FILE...      # specific font files
"""

import struct
import sys
from pathlib import Path

# The faces the templates name, plus the ones the spec compares them to.
DEFAULTS = [
    "/System/Library/Fonts/Supplemental/Times New Roman.ttf",
    "~/Library/Fonts/Tinos-Regular.ttf",
    "~/Library/Fonts/Cardo104s.ttf",
    "~/Library/Fonts/FrankRuhlLibre[wght].ttf",
    "~/Library/Fonts/NotoSerifHebrew[wdth,wght].ttf",
    "~/Library/Fonts/DavidLibre-Regular.ttf",
    "~/Library/Fonts/Heebo[wght].ttf",
    "~/Library/Fonts/CrimsonText-Regular.ttf",
]

ALEF = 0x05D0
TARGET = 0.900          # the norm those faces agree on; see section 9


def tables(d):
    n = struct.unpack(">H", d[4:6])[0]
    t = {}
    for i in range(n):
        o = 12 + i * 16
        tag = d[o:o + 4].decode("latin1")
        off, ln = struct.unpack(">II", d[o + 8:o + 16])
        t[tag] = (off, ln)
    return t


def cmap_lookup(d, t, ch):
    off = t["cmap"][0]
    n = struct.unpack(">H", d[off + 2:off + 4])[0]
    best = None
    for i in range(n):
        p = off + 4 + i * 8
        _pid, _eid, so = struct.unpack(">HHI", d[p:p + 8])
        fmt = struct.unpack(">H", d[off + so:off + so + 2])[0]
        if fmt in (4, 12):
            best = (fmt, off + so)
        if fmt == 12:
            break
    if not best:
        return 0
    fmt, sub = best
    if fmt == 4:
        segX2 = struct.unpack(">H", d[sub + 6:sub + 8])[0]
        seg = segX2 // 2
        ends = struct.unpack(">%dH" % seg, d[sub + 14:sub + 14 + segX2])
        sp = sub + 16 + segX2
        starts = struct.unpack(">%dH" % seg, d[sp:sp + segX2])
        dp = sp + segX2
        deltas = struct.unpack(">%dh" % seg, d[dp:dp + segX2])
        rp = dp + segX2
        ranges = struct.unpack(">%dH" % seg, d[rp:rp + segX2])
        for i in range(seg):
            if starts[i] <= ch <= ends[i]:
                if ranges[i] == 0:
                    return (ch + deltas[i]) & 0xFFFF
                gp = rp + i * 2 + ranges[i] + (ch - starts[i]) * 2
                g = struct.unpack(">H", d[gp:gp + 2])[0]
                return 0 if g == 0 else (g + deltas[i]) & 0xFFFF
        return 0
    ng = struct.unpack(">I", d[sub + 12:sub + 16])[0]
    for i in range(ng):
        p = sub + 16 + i * 12
        s, e, gi = struct.unpack(">III", d[p:p + 12])
        if s <= ch <= e:
            return gi + (ch - s)
    return 0


def bbox(d, t, gid):
    if "loca" not in t or "glyf" not in t:
        return None                      # CFF outlines; not measured here
    io = t["head"][0]
    fmt = struct.unpack(">h", d[io + 50:io + 52])[0]
    lo, go = t["loca"][0], t["glyf"][0]
    if fmt == 0:
        a, b = struct.unpack(">HH", d[lo + gid * 2:lo + gid * 2 + 4])
        a, b = a * 2, b * 2
    else:
        a, b = struct.unpack(">II", d[lo + gid * 4:lo + gid * 4 + 8])
    if a == b:
        return None
    return struct.unpack(">hhhh", d[go + a + 2:go + a + 10])


def advance(d, t, gid):
    num = struct.unpack(">H", d[t["hhea"][0] + 34:t["hhea"][0] + 36])[0]
    mo = t["hmtx"][0]
    return struct.unpack(">H", d[mo + min(gid, num - 1) * 4:mo + min(gid, num - 1) * 4 + 2])[0]


def measure(path):
    d = Path(path).read_bytes()
    t = tables(d)
    upm = struct.unpack(">H", d[t["head"][0] + 18:t["head"][0] + 20])[0]
    scale = 1000.0 / upm

    def top(ch):
        g = cmap_lookup(d, t, ch)
        b = bbox(d, t, g) if g else None
        return round(b[3] * scale) if b else None

    def adv(ch):
        g = cmap_lookup(d, t, ch)
        return round(advance(d, t, g) * scale) if g else None

    ho = t["hhea"][0]
    asc, desc, gap = struct.unpack(">hhh", d[ho + 4:ho + 10])
    return {
        "name": Path(path).name,
        "alef": top(ALEF),
        "cap": top(ord("H")),
        "x": top(ord("x")),
        "adv": {c: adv(ord(c)) for c in "nomeMI "},
        "hhea": (round(asc * scale), round(desc * scale), round(gap * scale)),
    }


def main(argv):
    paths = argv[1:] or DEFAULTS
    rows = []
    for p in paths:
        f = Path(p).expanduser()
        if not f.exists():
            print("missing  %s" % p, file=sys.stderr)
            continue
        try:
            rows.append(measure(f))
        except Exception as exc:                       # noqa: BLE001
            print("failed   %s: %s" % (p, exc), file=sys.stderr)

    print("\nHEBREW AGAINST ITS OWN LATIN  (spec section 9)")
    print("%-30s %6s %6s %9s %10s" % ("face", "alef", "cap H", "alef/cap", "correction"))
    for r in sorted(rows, key=lambda r: -(r["alef"] / r["cap"]) if r["alef"] and r["cap"] else 1):
        if not r["alef"] or not r["cap"]:
            print("%-30s %6s %6s %9s %10s"
                  % (r["name"], r["alef"] or "-", r["cap"] or "-", "-", "no Hebrew"))
            continue
        ratio = r["alef"] / r["cap"]
        corr = TARGET / ratio
        flag = "" if 0.98 <= corr <= 1.02 else "  <-- needs %.1f%%" % (corr * 100)
        print("%-30s %6d %6d %9.3f %9.1f%%%s"
              % (r["name"], r["alef"], r["cap"], ratio, corr * 100, flag))

    print("\nADVANCE WIDTHS AND LINE METRICS  (spec section 2.1)")
    print("%-30s %s %14s" % ("face", "  n   o   m   e   M   I  sp", "hhea a/d/gap"))
    for r in rows:
        a = r["adv"]
        print("%-30s %4s%4s%4s%4s%4s%4s%4s   %s"
              % (r["name"], a["n"], a["o"], a["m"], a["e"], a["M"], a["I"], a[" "],
                 "/".join(str(v) for v in r["hhea"])))
    print("\nTinos stands in for Times New Roman only where every figure on its")
    print("row matches Times's exactly. If they diverge, re-measure before")
    print("trusting any page count built on the substitution.\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

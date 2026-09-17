#!/bin/sh
# Turn a book PDF exported from iA Writer into a Lulu-ready interior.
#
#   tools/make_book.sh <template> <exported.pdf> [out.pdf]
#
#   template: ustrade | digest | executive
#
# iA Writer prints through WebKit, which cannot tell a recto page from a
# verso one, so the book templates export with a symmetric margin and
# this script moves each page toward its own spine: right on odd pages,
# left on even ones. The result has the inside margin on the bound edge
# of every page, which is what a print-on-demand interior needs.
#
# Verify one exported PDF with a ruler before a print run, and check the
# gutter against Lulu's current table for the book's actual page count.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)

if [ -z "${SDKROOT:-}" ]; then
    for sdk in /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk \
               /Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk; do
        [ -d "$sdk" ] && SDKROOT="$sdk" && export SDKROOT && break
    done
fi

usage() {
    echo "usage: tools/make_book.sh <ustrade|digest|executive> <exported.pdf> [out.pdf]" >&2
    exit 2
}

[ $# -ge 2 ] || usage
TEMPLATE=$1
INPUT=$2

case "$TEMPLATE" in
    ustrade)   SHIFT=13.5 ; TRIM="6 x 9"      ; INSIDE="1.0in"   ; OUTSIDE="0.625in" ;;
    digest)    SHIFT=9    ; TRIM="5.5 x 8.5"  ; INSIDE="0.75in"  ; OUTSIDE="0.5in"   ;;
    executive) SHIFT=13.5 ; TRIM="7 x 10"     ; INSIDE="1.125in" ; OUTSIDE="0.75in"  ;;
    *) usage ;;
esac

OUTPUT=${3:-$(dirname "$INPUT")/$(basename "$INPUT" .pdf)-book.pdf}

BIN=$(mktemp -d "${TMPDIR:-/tmp}/oranburg-impose.XXXXXX")
trap 'rm -rf "$BIN"' EXIT
swiftc -O -o "$BIN/impose" "$ROOT/tools/impose.swift"

"$BIN/impose" "$INPUT" "$OUTPUT" "$SHIFT"
echo "$TRIM interior: inside $INSIDE on the bound edge, outside $OUTSIDE."

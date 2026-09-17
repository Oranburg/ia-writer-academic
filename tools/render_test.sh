#!/bin/sh
# Render every template against tests/fixtures/sample.md (or a given .md)
# without launching iA Writer. Output goes to $OUT (default: a temp dir).
#
#   tools/render_test.sh [sample.md]
#
# Needs pandoc and the Xcode Command Line Tools. If swiftc complains that
# the SDK is not supported by the compiler, point SDKROOT at an older SDK:
#   SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk tools/render_test.sh
set -eu

# swiftc refuses an SDK newer than itself. Prefer a matching SDK when the
# default one is too new, which is the usual state after a macOS update.
if [ -z "${SDKROOT:-}" ]; then
    for sdk in /Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk \
               /Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk; do
        [ -d "$sdk" ] && SDKROOT="$sdk" && export SDKROOT && break
    done
fi
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MD=${1:-"$ROOT/tests/fixtures/sample.md"}
OUT=${OUT:-$(mktemp -d "${TMPDIR:-/tmp}/oranburg-render.XXXXXX")}
PANDOC=${PANDOC:-$(command -v pandoc || echo /opt/homebrew/bin/pandoc)}
export PANDOC

python3 "$ROOT/tools/build.py" --check
PANDOC="$PANDOC" python3 "$ROOT/tools/ia_html.py" "$MD" > "$OUT/fragment.html"
swiftc -O -o "$OUT/render" "$ROOT/tools/render.swift"

size() {
    case "$1" in
        *USTrade*)   echo "432 648" ;;
        *Digest*)    echo "396 612" ;;
        *Executive*) echo "504 720" ;;
        *)           echo "612 792" ;;
    esac
}

for b in "$ROOT"/*.iatemplate; do
    name=$(basename "$b" .iatemplate)
    # shellcheck disable=SC2046
    "$OUT/render" "$b" "$OUT/fragment.html" "$OUT/$name" $(size "$name")
done
echo "Renders in $OUT"

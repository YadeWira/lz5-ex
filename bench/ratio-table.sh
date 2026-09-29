#!/bin/sh
# Emit a per-file compressed-size table for levels 0-3, in both routes.
#
#   route "frame" : programs/lz5 -<level> (the CLI, frame format, 4 MB blocks)
#   route "block" : lzbench calling LZ5_compress_HC (one block per file)
#
# Usage: ratio-table.sh <silesia-dir> [lzbench-binary]
#
# Output is TSV, sorted:  route <TAB> file <TAB> level <TAB> csize
# Sizes do not depend on the machine, which is what makes them usable as a
# committed baseline; speeds are deliberately not part of this table.
#
# The lzbench binary is optional: the frame route alone still exercises the
# same parser, but the frame path splits input into blocks, so a change can
# show up in one route and not the other. Both are worth recording.

set -e

SILESIA="${1:-}"
LZBENCH="${2:-}"
HERE=$(cd "$(dirname "$0")" && pwd)
BIN="${LZ5_BIN:-$HERE/../programs/lz5}"

if [ -z "$SILESIA" ] || [ ! -d "$SILESIA" ]; then
    echo "usage: $0 <silesia-dir> [lzbench-binary]" >&2
    exit 1
fi
if [ ! -x "$BIN" ]; then
    echo "error: lz5 CLI not found at $BIN (build it with make -C programs)" >&2
    exit 1
fi

# Stale-binary guard. A binary left over from an earlier experiment silently
# produces a table for code that is no longer there, which is worse than no
# table at all - this has bitten the project more than once.
newest_src=$(ls -t "$HERE"/../lib/*.c "$HERE"/../lib/*.h 2>/dev/null | head -1)
if [ -n "$newest_src" ] && [ "$BIN" -ot "$newest_src" ]; then
    echo "error: $BIN is older than $newest_src - rebuild it first" >&2
    echo "       (make -C programs, and rebuild lzbench after touching lib/)" >&2
    exit 1
fi

for f in "$SILESIA"/*; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    for l in 0 1 2 3; do
        n=$("$BIN" -z "-$l" -q -c "$f" | wc -c)
        printf 'frame\t%s\t%s\t%s\n' "$base" "$l" "$n"
    done
done

if [ -n "$LZBENCH" ]; then
    if [ ! -x "$LZBENCH" ]; then
        echo "error: lzbench not found at $LZBENCH" >&2
        exit 1
    fi
    # lzbench links its rust codecs with a relative rpath, so it has to be
    # started from its own directory. It also has to be newer than the library
    # sources, for the same reason as the CLI above.
    if [ -n "$newest_src" ] && [ "$LZBENCH" -ot "$newest_src" ]; then
        echo "error: $LZBENCH is older than $newest_src - rebuild lzbench first" >&2
        exit 1
    fi
    # lzbench links its rust codecs with a relative rpath, so it has to be
    # started from its own directory.
    LZBDIR=$(cd "$(dirname "$LZBENCH")" && pwd)
    (cd "$LZBDIR" && ./lzbench -elz5,0,1,2,3 -i1 -o4 -r "$SILESIA") 2>/dev/null |
    awk -F, '$1 ~ /^lz5-ex/ && $7 != "" {
        lvl = $1; sub(/.* -/, "", lvl)
        n = split($7, p, "/")
        printf "block\t%s\t%s\t%s\n", p[n], lvl, $5
    }'
fi

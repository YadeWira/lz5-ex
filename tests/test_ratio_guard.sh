#!/bin/sh
# Ratio guard: fail if any file, at any level, compresses worse than the
# recorded baseline. This is the automated form of a hard project rule:
# a change may keep the ratio or improve it, never lose it - and per file,
# not merely in the corpus aggregate.
#
# Usage: test_ratio_guard.sh <silesia-dir> [lzbench-binary]
#
# Compares against bench/baseline-ratio.tsv, which holds the accepted sizes
# (route, file, level, csize). Speeds are not checked here: they are
# machine-dependent and are handled separately by the A/B measurement script.

set -e

SILESIA="${1:-}"
LZBENCH="${2:-}"
HERE=$(cd "$(dirname "$0")" && pwd)
BASELINE="$HERE/../bench/baseline-ratio.tsv"

if [ -z "$SILESIA" ] || [ ! -d "$SILESIA" ]; then
    echo "usage: $0 <silesia-dir> [lzbench-binary]" >&2
    exit 1
fi
if [ ! -f "$BASELINE" ]; then
    echo "error: baseline not found at $BASELINE" >&2
    exit 1
fi

WORK="${TMPDIR:-/tmp}/ratio-guard.$$"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"

"$HERE/../bench/ratio-table.sh" "$SILESIA" $LZBENCH > "$WORK/current.tsv"

# Join on (route,file,level); report every case where the new size is larger.
awk -F'\t' '
$0 ~ /^#/ { next }
FNR==NR { key=$1"|"$2"|"$3; base[key]=$4; next }
{
    key=$1"|"$2"|"$3
    if (!(key in base)) { printf "new case (no baseline): %s = %s\n", key, $4; next }
    if ($4 > base[key]) {
        printf "REGRESSION %s: %s -> %s (+%s bytes)\n", key, base[key], $4, $4-base[key]
        bad++
    } else if ($4 < base[key]) {
        printf "improved   %s: %s -> %s (-%s bytes)\n", key, base[key], $4, base[key]-$4
        good++
    }
    seen[key]=1
}
END {
    for (k in base) if (!(k in seen)) printf "missing case: %s\n", k
    printf "cases compared: %d, improved: %d, regressed: %d\n", length(seen), good, bad
    exit bad ? 1 : 0
}' "$BASELINE" "$WORK/current.tsv"

#!/bin/sh
# Interleaved A/B speed measurement.
#
# Build two lzbench binaries over the same corpus - one linked against the
# baseline library (A) and one against the candidate (B) - then run
#
#   ab-speed.sh <silesia-dir> <lzbench-A> <lzbench-B> [levels] [rounds]
#
# The two are alternated (A,B,A,B,...) so machine drift affects both equally,
# and the median per level is reported. Decisions are made on medians, never
# on a single run: run-to-run noise on one core is a few percent.
#
# Prints, per level: median encode MB/s for A and B, and the change.
# Aggregation matches bench/aggregate.awk: total bytes over total time.

set -e

SILESIA="${1:-}"
LZB_A="${2:-}"
LZB_B="${3:-}"
LEVELS="${4:-0,1,2,3}"
ROUNDS="${5:-5}"

if [ -z "$SILESIA" ] || [ -z "$LZB_A" ] || [ -z "$LZB_B" ]; then
    echo "usage: $0 <silesia-dir> <lzbench-A> <lzbench-B> [levels] [rounds]" >&2
    exit 1
fi

WORK="${TMPDIR:-/tmp}/ab-speed.$$"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK"

run_one() {   # $1 = lzbench binary, $2 = output file
    d=$(cd "$(dirname "$1")" && pwd)
    b=$(basename "$1")
    (cd "$d" && ./"$b" -e"lz5,$LEVELS" -i1 -o4 -r "$SILESIA") 2>/dev/null > "$2"
}

i=1
while [ "$i" -le "$ROUNDS" ]; do
    run_one "$LZB_A" "$WORK/a.$i.csv"
    run_one "$LZB_B" "$WORK/b.$i.csv"
    i=$((i + 1))
done

report() {   # $1 = label, $2 = perfiles glob
    awk -F, -v lbl="$1" '
    FNR==1 { f++ }
    $1 ~ /^lz5-ex/ {
        lvl=$1; sub(/.* -/, "", lvl)
        o[lvl]+=$4; t[lvl]+=$4/$2
    }
    END { for (l in o) printf "%s\t%s\t%.1f\n", l, lbl, o[l]/t[l] }
    ' $2
}

report A "$WORK/a.*.csv" > "$WORK/A.tsv"
report B "$WORK/b.*.csv" > "$WORK/B.tsv"

# median helper: sort numerically, take the middle value
median() { sort -n | awk '{v[NR]=$1} END{ if(NR%2) print v[(NR+1)/2]; else printf "%.1f\n", (v[NR/2]+v[NR/2+1])/2 }'; }

printf "%-6s %10s %10s %9s\n" level "A MB/s" "B MB/s" "change"
for lvl in $(awk -F'\t' '{print $1}' "$WORK/A.tsv" | sort -n -u); do
    ma=$(awk -F'\t' -v l="$lvl" '$1==l && $2=="A" {print $3}' "$WORK/A.tsv" | median)
    mb=$(awk -F'\t' -v l="$lvl" '$1==l && $2=="B" {print $3}' "$WORK/B.tsv" | median)
    chg=$(awk -v a="$ma" -v b="$mb" 'BEGIN{ if (a>0) printf "%+.1f%%", 100*(b-a)/a; else print "n/a" }')
    printf "%-6s %10.1f %10.1f %9s\n" "$lvl" "$ma" "$mb" "$chg"
done

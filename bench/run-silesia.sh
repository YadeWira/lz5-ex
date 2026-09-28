#!/bin/sh
# Reproduce the Silesia benchmark table in README.md.
#
# What it does:
#   1. clones lzbench at the commit the published numbers were taken from
#   2. applies lzbench-add-lz5.patch, which registers lz5-ex as a codec
#   3. drops this project's lib/ sources into the lzbench tree as that codec
#   4. builds lzbench and runs it over the Silesia corpus
#   5. aggregates the per-file CSV into one row per codec
#
# Requirements: git, make, a C/C++ toolchain, and the Silesia corpus.
#
# Usage:
#   ./bench/run-silesia.sh [path-to-silesia-corpus]
#
# The corpus can be obtained from
#   http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia
# and unpacks to 12 files totalling 211,938,580 bytes.

set -e

SILESIA="${1:-}"
if [ -z "$SILESIA" ] || [ ! -d "$SILESIA" ]; then
    echo "usage: $0 <path-to-silesia-corpus-directory>" >&2
    exit 1
fi

HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/.." && pwd)

# The lzbench revision the published numbers were produced with. lzbench
# upstream carries lizard, not lz5, so the codec has to be added.
LZBENCH_REPO=https://github.com/inikep/lzbench.git
LZBENCH_COMMIT=fd753e01c57fdd357a15b4340a927c97b8835919

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "==> fetching lzbench $LZBENCH_COMMIT"
git clone --quiet "$LZBENCH_REPO" lzbench
cd lzbench
git checkout --quiet "$LZBENCH_COMMIT"

echo "==> applying the lz5-ex codec patch"
git apply "$HERE/lzbench-add-lz5.patch"

echo "==> copying the lz5-ex library in as the codec"
mkdir -p lz/lz5
cp "$REPO"/lib/lz5.c "$REPO"/lib/lz5hc.c lz/lz5/
cp "$REPO"/lib/lz5.h "$REPO"/lib/lz5hc.h "$REPO"/lib/lz5common.h "$REPO"/lib/mem.h lz/lz5/
cp "$HERE/lz5.mk" mk/lz5.mk

echo "==> building"
make -j"$(nproc)"

echo "==> benchmarking"
# The compressor set matches the one in the published run: every lz5-ex level
# plus a spread of reference codecs. lzbench calibrates each measurement to
# roughly one second, so -i1 is a floor, not a single pass.
./lzbench \
  -e"lz5,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15/lz4/lz4hc,9/zstd,1,3,9,19/brotli,5,11/xz,6,9/bzip2,9/zlib,9/lizard,20" \
  -i1 -o4 -r "$SILESIA" > "$WORK/silesia-raw.csv" 2>/dev/null

cp "$WORK/silesia-raw.csv" "$HERE/silesia.csv.run"

echo "==> aggregating"
awk -f "$HERE/aggregate.awk" "$WORK/silesia-raw.csv" | sort -t, -k4,4n > "$HERE/silesia-aggregated.csv.run"

echo
echo "raw output      : $HERE/silesia.csv.run"
echo "aggregated      : $HERE/silesia-aggregated.csv.run"
echo
echo "Compare against the committed bench/silesia.csv and"
echo "bench/silesia-aggregated.csv; sizes should match exactly."

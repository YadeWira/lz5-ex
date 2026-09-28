#!/bin/bash
# Cross-compatibility test: lz5-ex must stay interoperable with LZ5 1.5.0.
#
# The project rule is: maintain and improve what can be improved without
# breaking compatibility with LZ5 1.5.0. Compatibility here means
# INTEROPERABILITY, not byte-identical output:
#
#   MUST pass   - every stream lz5-ex produces decodes correctly with the
#                 LZ5 1.5.0 binary, and every stream 1.5.0 produces decodes
#                 correctly with lz5-ex, round-tripping to the original data.
#   Informational - whether the compressed bytes still match 1.5.0 exactly.
#                 Parser improvements are allowed to change the bytes as long
#                 as both sides can decode them; drift is reported so it never
#                 happens silently.
#
# Usage:
#   ./test_compat_lz5_15.sh <path-to-LZ5-1.5.0-binary> [corpus-directory]
#
# The corpus directory is optional; without it the test runs on generated
# synthetic data. With it, every file in the directory is also tested.

set -u

REF="$1"
CORPUS="${2:-}"
if [ ! -x "$REF" ]; then
    echo "usage: $0 <path-to-LZ5-1.5.0-binary> [corpus-directory]" >&2
    exit 2
fi

HERE=$(cd "$(dirname "$0")" && pwd)
NEW="$HERE/../programs/lz5"
if [ ! -x "$NEW" ]; then
    echo "building lz5-ex..." >&2
    make -C "$HERE/../programs" lz5 >/dev/null || exit 2
fi
NEW=$(cd "$(dirname "$NEW")" && pwd)/lz5

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- test data: always the synthetic set, plus the corpus if given ---
: > "$TMP/empty.bin"
printf 'a' > "$TMP/one.bin"
head -c 3000000 /dev/zero > "$TMP/zeros.bin"
dd if=/dev/urandom of="$TMP/rand.bin" bs=1M count=5 2>/dev/null
yes "lz5-ex interoperability test line" | head -c 2000000 > "$TMP/repeat.txt"
head -c 1048576 /dev/urandom > "$TMP/mixed.bin"
{ head -c 524288 /dev/zero; head -c 524288 /dev/urandom; } > "$TMP/half.bin"

FILES=""
for f in empty.bin one.bin zeros.bin rand.bin repeat.txt mixed.bin half.bin; do
    FILES="$FILES $TMP/$f"
done
if [ -n "$CORPUS" ]; then
    for f in "$CORPUS"/*; do
        [ -f "$f" ] && FILES="$FILES $f"
    done
fi

LEVELS="0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"

cross_fail=0
identity_fail=0
identity_total=0
n=0

echo "reference binary : $($REF --version 2>&1 | head -1)"
echo "lz5-ex binary    : $($NEW --version 2>&1 | head -1)"
echo

for lvl in $LEVELS; do
    lvl_fail=0
    lvl_drift=0
    lvl_total=0
    for src in $FILES; do
        n=$((n+1))
        "$NEW" -z -$lvl -q -c "$src" > "$TMP/new.lz5" 2>/dev/null
        "$REF" -z -$lvl -q -c "$src" > "$TMP/ref.lz5" 2>/dev/null

        # MUST: 1.5.0 decodes what lz5-ex produced
        if ! "$REF" -d -q -c "$TMP/new.lz5" 2>/dev/null | cmp -s - "$src"; then
            echo "INTEROP FAIL: 1.5.0 cannot decode lz5-ex output (level $lvl, $(basename "$src"))"
            cross_fail=$((cross_fail+1)); lvl_fail=$((lvl_fail+1))
        fi
        # MUST: lz5-ex decodes what 1.5.0 produced
        if ! "$NEW" -d -q -c "$TMP/ref.lz5" 2>/dev/null | cmp -s - "$src"; then
            echo "INTEROP FAIL: lz5-ex cannot decode 1.5.0 output (level $lvl, $(basename "$src"))"
            cross_fail=$((cross_fail+1)); lvl_fail=$((lvl_fail+1))
        fi
        # INFORMATIONAL: byte identity with 1.5.0
        lvl_total=$((lvl_total+1))
        if ! cmp -s "$TMP/new.lz5" "$TMP/ref.lz5"; then
            identity_fail=$((identity_fail+1)); lvl_drift=$((lvl_drift+1))
        fi
        identity_total=$((identity_total+1))
    done
    status="ok"
    [ $lvl_fail -gt 0 ] && status="INTEROP BROKEN"
    [ $lvl_drift -gt 0 ] && status="$status (bytes drifted from 1.5.0: $lvl_drift/$lvl_total)"
    echo "level $lvl: $status"
done

echo
echo "cases: $n   interoperability failures: $cross_fail"
echo "byte identity vs 1.5.0: $((identity_total-identity_fail))/$identity_total identical (drift is allowed, see header)"

if [ $cross_fail -gt 0 ]; then
    echo "RESULT: FAILURE - compatibility with LZ5 1.5.0 is broken"
    exit 1
fi
echo "RESULT: interoperable with LZ5 1.5.0"

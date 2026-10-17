#!/bin/bash
# Command line test: every option of the lz5 program, one at a time.
#
# Each check runs the program the way a user would and looks at what matters:
# the exit code, the round trip, the bytes of the frame header, or the files
# left behind. It needs only bash and the usual POSIX tools, so it runs on
# Linux, macOS and Windows (Git Bash), against any build of the program.
#
# Usage:
#   ./test_cli.sh [path-to-lz5]        (default: ../programs/lz5)
#
# Checks that need a terminal (the console guard, automatic output names) run
# only where util-linux `script` is available, i.e. on Linux.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
LZ5="${1:-$HERE/../programs/lz5}"
if [ ! -x "$LZ5" ] && [ -x "$LZ5.exe" ]; then LZ5="$LZ5.exe"; fi
if [ ! -x "$LZ5" ]; then
    echo "usage: $0 [path-to-lz5]" >&2
    exit 2
fi
LZ5=$(cd "$(dirname "$LZ5")" && pwd)/$(basename "$LZ5")

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP" || exit 2

pass=0
fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "FAIL: $*"; }
# check <description> <command...>: the command must succeed
check() { local d="$1"; shift; if "$@"; then ok; else bad "$d"; fi; }
# refuse <description> <command...>: the command must fail
refuse() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then bad "$d (should have failed)"; else ok; fi; }
# byte <file> <offset>: one byte of a file, as two lowercase hex digits
byte() { od -An -tx1 -j "$2" -N1 "$1" | tr -d ' \n'; }
# same <a> <b>: both files exist and are identical
same() { [ -f "$1" ] && [ -f "$2" ] && cmp -s "$1" "$2"; }

# --- test data ---
yes "lz5-ex command line test, a line that repeats" | head -c 1500000 > text
head -c 300000 /dev/urandom > rand
{ head -c 100000 /dev/urandom; head -c 2000000 /dev/zero; head -c 100000 /dev/urandom; } > holes
: > empty

echo "binary: $("$LZ5" -V 2>&1 | head -1)"

# --- information: -V --version -h -H ---
check "-V prints the version"      sh -c '"$0" -V 2>&1 | grep -q "LZ5 command line interface"' "$LZ5"
check "--version prints it too"    sh -c '"$0" --version 2>&1 | grep -q "LZ5 command line interface"' "$LZ5"
check "-h prints the usage"        sh -c '"$0" -h 2>&1 | grep -q "Usage"' "$LZ5"
check "-H prints the long help"    sh -c '"$0" -H 2>&1 | grep -q "Advanced comment"' "$LZ5"
refuse "an unknown option is rejected"       "$LZ5" -Y text out
refuse "a missing input file is an error"    "$LZ5" no-such-file out

# --- every level, both directions; levels above 15 act as 15 ---
for lvl in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    for f in text rand holes empty; do
        "$LZ5" -q -f -$lvl "$f" c.lz5 && "$LZ5" -q -f -d c.lz5 d
        check "level $lvl round trip ($f)" same d "$f"
    done
done
"$LZ5" -q -f -15 text c15.lz5
"$LZ5" -q -f -16 text c16.lz5
check "-16 compresses like -15"    same c15.lz5 c16.lz5
"$LZ5" -q -f text c0.lz5
"$LZ5" -q -f -0 text c00.lz5
check "the default level is -0"    same c0.lz5 c00.lz5

# --- -z -d --compress --decompress --uncompress, and the .lz5 extension ---
"$LZ5" -q -f text t.lz5
"$LZ5" -q -f -z t.lz5 tt.lz5 && "$LZ5" -q -f -d tt.lz5 t2.lz5
check "-z compresses even a .lz5 input"            same t2.lz5 t.lz5
"$LZ5" -q -f --compress t.lz5 tt2.lz5
check "--compress is -z"                           same tt2.lz5 tt.lz5
cp t.lz5 noext
"$LZ5" -q -f -d noext a.out
check "-d decodes a file without .lz5"             same a.out text
"$LZ5" -q -f --decompress noext b.out
check "--decompress is -d"                         same b.out text
"$LZ5" -q -f --uncompress noext c.out
check "--uncompress is -d"                         same c.out text
refuse "-d rejects data that is not lz5"           "$LZ5" -q -d text x.out
"$LZ5" -q -f -d text x.out
check "-d -f copies data that is not lz5 through"  same x.out text
refuse "-t rejects data that is not lz5"           "$LZ5" -q -t text
refuse "-t -f rejects it too"                      "$LZ5" -q -f -t text

# --- -t --test ---
check "-t accepts a good frame"           "$LZ5" -q -t t.lz5
check "--test accepts a good frame"       "$LZ5" -q --test t.lz5
cp t.lz5 trunc.lz5
head -c $(( $(wc -c < t.lz5) - 10 )) t.lz5 > trunc.lz5
refuse "-t rejects a truncated frame"     "$LZ5" -q -t trunc.lz5
refuse "-d rejects a truncated frame"     "$LZ5" -q -f -d trunc.lz5 x.out
check "-t writes no file"                 sh -c '! ls t 2>/dev/null'

# --- -c --stdout --to-stdout, '-', stdin, stdout, null ---
"$LZ5" -c text > s.lz5;  "$LZ5" -d -c s.lz5 > s.out
check "-c writes to standard output"        same s.out text
"$LZ5" --stdout text > s2.lz5
check "--stdout is -c"                      same s2.lz5 s.lz5
"$LZ5" --to-stdout text > s3.lz5
check "--to-stdout is -c"                   same s3.lz5 s.lz5
"$LZ5" - - < text > p.lz5; "$LZ5" -d - - < p.lz5 > p.out
check "'-' reads stdin and writes stdout"   same p.out text
"$LZ5" stdin stdout < text > n.lz5; "$LZ5" -d stdin stdout < n.lz5 > n.out
check "'stdin' and 'stdout' names"          same n.out text
cat text | "$LZ5" | "$LZ5" -d > pipe.out
check "pure pipe mode"                      same pipe.out text
check "'null' discards the output"          "$LZ5" -q text null
check "'null' after -d tests the frame"     "$LZ5" -q -d t.lz5 null
check "'null' leaves no file named null"    sh -c '! ls null 2>/dev/null'
check "'null' needs no -f and asks nothing" sh -c '"$0" text null < /dev/null 2>/dev/null' "$LZ5"

# --- -f --force --no-force, and the overwrite question ---
echo old > o.lz5
refuse "an existing file is kept with -q"   "$LZ5" -q text o.lz5
check "... and not changed"                 sh -c 'test "$(cat o.lz5)" = old'
echo n | "$LZ5" text o.lz5 2>/dev/null
check "answering n keeps the file"          sh -c 'test "$(cat o.lz5)" = old'
echo y | "$LZ5" text o.lz5 2>/dev/null
check "answering y overwrites it"           same o.lz5 c0.lz5
echo old > o.lz5
"$LZ5" -q -f text o.lz5 < /dev/null
check "-f overwrites without asking"        same o.lz5 c0.lz5
echo old > o.lz5
"$LZ5" -q --force text o.lz5 < /dev/null
check "--force is -f"                       same o.lz5 c0.lz5
echo old > o.lz5
refuse "--no-force undoes -f"               "$LZ5" -q -f --no-force text o.lz5
echo old > o.lz5
refuse "the question is not asked when the data comes from stdin" sh -c '"$0" -q - o.lz5 < text' "$LZ5"

# --- -k --keep: the source file always stays ---
cp text k.src
"$LZ5" -q -f -k k.src k.lz5
check "-k keeps the source"        same k.src text
"$LZ5" -q -f --keep k.src k2.lz5
check "--keep keeps the source"    same k.src text
"$LZ5" -q -f k.src k3.lz5
check "the source stays without -k"  same k.src text

# --- -v --verbose -q --quiet ---
check "-v shows the version banner"        sh -c '"$0" -v -f text v.lz5 2>&1 | grep -q "LZ5 command line interface"' "$LZ5"
check "--verbose is -v"                    sh -c '"$0" --verbose -f text v.lz5 2>&1 | grep -q "LZ5 command line interface"' "$LZ5"
check "the default level reports the ratio" sh -c '"$0" -f text v.lz5 2>&1 | grep -q "Compressed"' "$LZ5"
check "-q hides the ratio"                 sh -c 'test -z "$("$0" -q -f text v.lz5 2>&1)"' "$LZ5"
check "--quiet is -q"                      sh -c 'test -z "$("$0" --quiet -f text v.lz5 2>&1)"' "$LZ5"
check "-q still shows errors"              sh -c '"$0" -q no-such-file v.lz5 2>&1 | grep -q .' "$LZ5"
check "-qq hides errors too"               sh -c 'test -z "$("$0" -qq no-such-file v.lz5 2>&1)"' "$LZ5"
refuse "-qq still fails on an error"       "$LZ5" -qq no-such-file v.lz5

# --- -m --multiple ---
cp text m1; cp rand m2; cp holes m3
"$LZ5" -q -f -m m1 m2 m3
check "-m names each output after its input"  sh -c 'test -f m1.lz5 && test -f m2.lz5 && test -f m3.lz5'
mkdir mm; mv m1.lz5 m2.lz5 m3.lz5 mm/
"$LZ5" -q -f -d -m mm/m1.lz5 mm/m2.lz5 mm/m3.lz5
check "-d -m decompresses each one"           sh -c 'cmp -s mm/m1 m1 && cmp -s mm/m2 m2 && cmp -s mm/m3 m3'
rm -f m1.lz5 m2.lz5 m3.lz5
"$LZ5" -q -f --multiple m1 m2
check "--multiple is -m"                      sh -c 'test -f m1.lz5 && test -f m2.lz5'

# --- -B1 ... -B7: block size in the frame descriptor (BD byte) ---
yes "block size test" | head -c 70000000 > big
for b in 1 2 3 4 5 6 7; do
    "$LZ5" -q -f -B$b big b.lz5
    check "-B$b writes block size id $b"       test "$(byte b.lz5 5)" = "${b}0"
    "$LZ5" -q -f -d b.lz5 b.out
    check "-B$b round trip"                    same b.out big
done
rm -f big b.out
"$LZ5" -q -f -BX text bx.lz5 && "$LZ5" -q -f -d bx.lz5 bx.out
check "-BX (block checksum) round trip"        same bx.out text
"$LZ5" -q -f -B9 text b9.lz5 && "$LZ5" -q -f -d b9.lz5 b9.out
check "-B9 (not a block size) still works" same b9.out text

# --- frame flags: --frame-crc --no-frame-crc --content-size --no-content-size ---
# FLG byte (offset 4): bit 3 = content size, bit 2 = content checksum
flg() { echo $(( 0x$(byte "$1" 4) )); }
"$LZ5" -q -f text f.lz5
check "the checksum is on by default"           test $(( $(flg f.lz5) & 4 )) -ne 0
check "the content size is off by default"      test $(( $(flg f.lz5) & 8 )) -eq 0
"$LZ5" -q -f --no-frame-crc text f.lz5
check "--no-frame-crc clears the flag"          test $(( $(flg f.lz5) & 4 )) -eq 0
"$LZ5" -q -f -d f.lz5 f.out; check "--no-frame-crc round trip" same f.out text
"$LZ5" -q -f --no-frame-crc --frame-crc text f.lz5
check "--frame-crc sets it again"               test $(( $(flg f.lz5) & 4 )) -ne 0
"$LZ5" -q -f --content-size text f.lz5
check "--content-size sets the flag"            test $(( $(flg f.lz5) & 8 )) -ne 0
"$LZ5" -q -f -d f.lz5 f.out; check "--content-size round trip" same f.out text
"$LZ5" -q -c --content-size < text > fs.lz5
check "--content-size from stdin (size unknown) still decodes" sh -c '"$0" -d -c fs.lz5 | cmp -s - text' "$LZ5"
"$LZ5" -q -f --content-size --no-content-size text f.lz5
check "--no-content-size clears it again"       test $(( $(flg f.lz5) & 8 )) -eq 0
# a damaged byte in a stored (incompressible) block: only the checksum sees it
"$LZ5" -q -f rand r.lz5
"$LZ5" -q -f --no-frame-crc rand rn.lz5
flip() { local v=$(( 0x$(byte "$1" 100) ^ 1 )); { head -c 100 "$1"; printf "\\$(printf %o $v)"; tail -c +102 "$1"; } > "$2"; }
flip r.lz5 rbad.lz5; flip rn.lz5 rnbad.lz5
refuse "the checksum catches a damaged byte"    "$LZ5" -q -t rbad.lz5
check "without it, the same damage goes unseen" "$LZ5" -q -t rnbad.lz5

# --- --sparse --no-sparse: same bytes either way; holes only where they can be ---
"$LZ5" -q -f holes h.lz5
"$LZ5" -q -f -d --sparse h.lz5 hs.out
"$LZ5" -q -f -d --no-sparse h.lz5 hn.out
check "--sparse output is correct"      same hs.out holes
check "--no-sparse output is correct"   same hn.out holes
"$LZ5" -q -d -c --sparse h.lz5 > hc.out
check "--sparse to stdout is correct"   same hc.out holes
if [ "$(uname -s)" = Linux ]; then
    blk() { du -k "$1" | cut -f1; }
    check "--sparse leaves holes"            test "$(blk hs.out)" -lt 1000
    check "--no-sparse writes every block"   test "$(blk hn.out)" -ge 2000
fi

# --- several frames in one file, and skippable frames ---
"$LZ5" -q -c text > cat.lz5; "$LZ5" -q -c rand >> cat.lz5
cat text rand > cat.ref
check "concatenated frames decode in order"   sh -c '"$0" -d -c cat.lz5 | cmp -s - cat.ref' "$LZ5"
{ printf '\120\052\115\030\004\000\000\000abcd'; cat t.lz5; } > skip.lz5
check "a skippable frame is skipped"          sh -c '"$0" -d -c skip.lz5 | cmp -s - text' "$LZ5"

# --- short options can be grouped ---
echo old > g.lz5
"$LZ5" -9fq text g.lz5
"$LZ5" -q -f -9 text g9.lz5
check "-9fq is -9 -f -q"           same g.lz5 g9.lz5
"$LZ5" -dc g.lz5 > g.out
check "-dc is -d -c"               same g.out text
check "-tq is -t -q"               "$LZ5" -tq g.lz5

# --- -b -i#: benchmark mode ---
check "-b benchmarks a file"       sh -c '"$0" -b -i1 text 2>&1 | grep -q "text"' "$LZ5"
check "-b takes several files"     sh -c '"$0" -b -i1 text rand 2>&1 | grep -q "rand"' "$LZ5"
check "-b -9 benchmarks level 9"   sh -c '"$0" -b9 -i1 text >/dev/null 2>&1' "$LZ5"
check "-p (pause) waits for a key"  sh -c 'echo | "$0" -p -b -i1 text >/dev/null 2>&1' "$LZ5"

# --- terminal checks: console guard and automatic names (needs util-linux script) ---
if script -qec true /dev/null >/dev/null 2>&1; then
    tty() { script -qec "$*" /dev/null > tty.log 2>&1; }
    tty "'$LZ5' text"
    check "on a console, the output is named .lz5"     same text.lz5 c0.lz5
    mv text.lz5 auto.lz5; mkdir tt; mv auto.lz5 tt/
    (cd tt && script -qec "'$LZ5' auto.lz5" /dev/null >/dev/null 2>&1)
    check "on a console, .lz5 is removed on decompression" same tt/auto text
    rm -f x; cp text x
    tty "'$LZ5' -d x"
    check "a name without .lz5 cannot be decompressed to a console" grep -q "Cannot determine an output filename" tty.log
    tty "'$LZ5' -c text > /dev/null; '$LZ5' text - ; echo rc=\$?"
    check "lz5 refuses to write binary to the console without -c" grep -q "refusing to write to console" tty.log
    tty "'$LZ5' < /dev/tty; echo rc=\$?"
    check "lz5 refuses to read from the console"   grep -q "refusing to read from a console" tty.log
fi

echo
echo "checks: $((pass+fail))   failures: $fail"
[ $fail -eq 0 ] && echo "RESULT: every option works" || echo "RESULT: FAILURE"
[ $fail -eq 0 ]

#!/bin/sh
# Package an LZ5 release tarball.
#
# Usage:  make release   (or)   ./make-release.sh [version]
#
# Produces  lz5-<version>.tar.gz  containing lib/, programs/, tests/, the format
# specifications and both licences (lib/ is BSD, programs/ is GPLv2).
#
# The version is read from lib/lz5.h and cross-checked against lib/Makefile,
# so the shared library SONAME and the tarball name cannot drift apart.

set -e

cd "$(dirname "$0")"

VERSION_H=$(sed -n 's/^#define LZ5_VERSION  *"\(.*\)"/\1/p' lib/lz5.h | sed 's/^v//')
VERSION_M=$(sed -n 's/^VERSION?= *//p' lib/Makefile)

if [ -z "$VERSION_H" ]; then
    echo "error: cannot read version from lib/lz5.h" >&2
    exit 1
fi
if [ "$VERSION_H" != "$VERSION_M" ]; then
    echo "error: version mismatch: lib/lz5.h says $VERSION_H, lib/Makefile says $VERSION_M" >&2
    echo "       update both before packaging." >&2
    exit 1
fi
if [ -n "$1" ]; then
    if [ "$1" != "$VERSION_H" ]; then
        echo "error: requested $1 but the tree is at $VERSION_H" >&2
        exit 1
    fi
fi
VERSION="$VERSION_H"

TARBALL="lz5-$VERSION.tar.gz"
STAGE="lz5-$VERSION"

echo "==> version $VERSION"

# --- verify the tree builds and the round-trip works before packaging -------
echo "==> building"
make clean >/dev/null 2>&1 || true
make >/dev/null

echo "==> smoke test"
( cd programs && make lz5 datagen >/dev/null 2>&1 )
( cd programs && ./datagen -g2M | ./lz5 -9 | ./lz5 -t >/dev/null )
( cd programs && ./datagen -g1M -P99 | ./lz5 -12 | ./lz5 -t >/dev/null )

if [ -d tests ]; then
    echo "==> regression tests"
    ( cd tests && make >/dev/null 2>&1 && make test >/dev/null )
fi

# --- stage ------------------------------------------------------------------
echo "==> staging"
rm -rf "$STAGE" "$TARBALL"
mkdir -p "$STAGE"

# Only files under version control ship, so build artefacts (programs/lz5,
# the test binaries, objects, libraries) cannot leak into the tarball.
git ls-files -z lib programs tests projects .github Makefile NEWS README.md \
    lz5_Block_format.md lz5_Frame_format.md | xargs -0 cp --parents -t "$STAGE"

# Licences: lib/ is BSD (lib/LICENSE), programs/ is GPLv2 (programs/COPYING).
[ -f lib/LICENSE ] && cp lib/LICENSE "$STAGE/LICENSE.lib"
[ -f programs/COPYING ] && cp programs/COPYING "$STAGE/COPYING.programs"

# --- checksum ---------------------------------------------------------------
( cd . && find "$STAGE" -type f | LC_ALL=C sort | xargs sha256sum > "$STAGE.sha256" )

# --- package ----------------------------------------------------------------
echo "==> packaging $TARBALL"
tar czf "$TARBALL" "$STAGE"
rm -rf "$STAGE"

echo
echo "created: $TARBALL"
echo "sha256 : $(sha256sum "$TARBALL" | cut -d' ' -f1)"
echo
echo "next steps:"
echo "  sha256sum -c $TARBALL.sha256"
echo "  upload to the release page / distro packaging"

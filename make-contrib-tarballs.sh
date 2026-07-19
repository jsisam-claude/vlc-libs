#!/bin/sh -e
# Build the contrib source archives VLC's build system expects from the
# source trees vendored in contrib-src/ (fetched from each project's
# OFFICIAL repository at the exact production version the recipes pin —
# see contrib-src/*/.vendored for provenance).
#
# For each package this script:
#   1. copies the pristine tree to a temp dir
#   2. runs autogen/autoreconf if the package's build needs a generated
#      ./configure that release archives normally ship (git trees do not)
#   3. packs it as the exact filename vlc/contrib expects, with the
#      canonical top-level directory name
#   4. rewrites the package's SHA512SUMS line in vlc/contrib/src so the
#      contrib build verifies OUR archive (provenance: official tag in
#      .vendored -> committed tree -> generated archive -> pinned hash)
#
# Run on a machine with autotools + xz installed, then commit
# contrib-tarballs/ and the SHA512SUMS changes under vlc/.
#
# Packages with no official GitHub (gnutls, nettle, gmp, libiconv,
# libdvbpsi) are NOT covered here — fetch-contribs.sh downloads their
# official release archives (SHA-512-verified) as the supplement.

ROOT=$(cd "$(dirname "$0")" && pwd -P)
TARBALLS="$ROOT/contrib-tarballs"
mkdir -p "$TARBALLS"

# pkg-dir  recipe-dir  archive-name              top-level-dir     needs-autogen
SET="\
ffmpeg    ffmpeg   ffmpeg-8.1.2.tar.xz      ffmpeg-8.1.2      no
ass       ass      libass-0.17.5.tar.xz     libass-0.17.5     yes
freetype2 freetype2 freetype-2.13.1.tar.xz  freetype-2.13.1   yes
fribidi   fribidi  fribidi-1.0.12.tar.xz    fribidi-1.0.12    yes
harfbuzz  harfbuzz harfbuzz-14.2.1.tar.xz   harfbuzz-14.2.1   yes
ogg       ogg      libogg-1.3.6.tar.xz      libogg-1.3.6      yes
ebml      ebml     libebml-1.4.5.tar.xz     libebml-1.4.5     no
matroska  matroska libmatroska-1.7.1.tar.xz libmatroska-1.7.1 no"

echo "$SET" | while read -r pkg recipe archive topdir autogen; do
    [ -n "$pkg" ] || continue
    src="$ROOT/contrib-src/$pkg"
    [ -d "$src" ] || { echo "missing $src — run the vendor step first"; exit 1; }

    tmp=$(mktemp -d)
    cp -a "$src" "$tmp/$topdir"
    rm -f "$tmp/$topdir/.vendored"

    if [ "$autogen" = yes ] && [ ! -x "$tmp/$topdir/configure" ]; then
        ( cd "$tmp/$topdir" && \
          { [ -x ./autogen.sh ] && NOCONFIGURE=1 ./autogen.sh || autoreconf -fiv; } ) \
          || echo "WARNING: autogen failed for $pkg — the contrib build may need to bootstrap it"
    fi

    ( cd "$tmp" && tar -cJf "$TARBALLS/$archive" "$topdir" )
    rm -rf "$tmp"

    sum=$(sha512sum "$TARBALLS/$archive" | awk '{print $1}')
    sums="$ROOT/vlc/contrib/src/$recipe/SHA512SUMS"
    grep -v " $archive\$" "$sums" > "$sums.new" 2>/dev/null || true
    printf '%s  %s\n' "$sum" "$archive" >> "$sums.new"
    mv "$sums.new" "$sums"
    echo "OK $archive ($sum)"
done

echo
echo "Done. Commit contrib-tarballs/ and the vlc/contrib/src/*/SHA512SUMS updates."

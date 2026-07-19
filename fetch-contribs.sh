#!/bin/sh -e
# Populate contrib-tarballs/ with the source archives VLC's contrib system
# needs, using VLC's own fetch + SHA-512 verification machinery
# (vlc/contrib/src/*/SHA512SUMS). Run once on a machine with network access,
# then commit contrib-tarballs/.
#
# The cache is target-independent for almost all packages; the vlc-android
# build (with TARBALLS pointing here) verifies every archive again at build
# time and will fetch-and-verify any target-specific stragglers on its first
# run — commit those additions too, after which builds are fully offline.
ROOT=$(cd "$(dirname "$0")" && pwd -P)
export TARBALLS="$ROOT/contrib-tarballs"
mkdir -p "$TARBALLS"

BUILDDIR="$ROOT/vlc/contrib/contrib-fetch"
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"
../bootstrap
make fetch-all || make fetch
echo
echo "Archives cached in $TARBALLS:"
ls "$TARBALLS" | wc -l
echo "Now: git add contrib-tarballs && git commit"

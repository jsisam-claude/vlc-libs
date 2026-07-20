#!/bin/sh -e
# Place the vendored build inputs where the native build reads them.
# The VLC contrib/tools makefiles hard-assign their tarball dirs
# (TARBALLS := $(TOPSRC)/tarballs, etc.), so an env override is not enough —
# the archives must physically sit in-tree. Run this after checking out
# vlc-libs and before ./buildsystem/compile.sh in the consumer repo.
ROOT=$(cd "$(dirname "$0")" && pwd -P)

mkdir -p "$ROOT/vlc/contrib/tarballs"
cp -n "$ROOT"/contrib-tarballs/*.tar.* "$ROOT/vlc/contrib/tarballs/" 2>/dev/null || true

mkdir -p "$ROOT/vlc/extras/tools"
cp -n "$ROOT"/host-tools/*.tar.* "$ROOT/vlc/extras/tools/" 2>/dev/null || true

echo "Placed $(ls "$ROOT"/contrib-tarballs/*.tar.* 2>/dev/null | wc -l) contrib + $(ls "$ROOT"/host-tools/*.tar.* 2>/dev/null | wc -l) host-tool archives into the vlc tree."

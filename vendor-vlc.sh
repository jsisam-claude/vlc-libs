#!/bin/sh -e
# Re-vendor vlc/ at an exact upstream commit (source only, .git stripped).
# Usage: ./vendor-vlc.sh <commit-sha>
# GitHub's mirror allows fetching arbitrary commits by sha.
SHA=$1
[ -n "$SHA" ] || { echo "usage: $0 <commit-sha>"; exit 1; }
ROOT=$(cd "$(dirname "$0")" && pwd -P)

CUR=$(cat "$ROOT/vlc/.vendored" 2>/dev/null || true)
if [ "$CUR" = "$SHA" ]; then
    echo "vlc/ already at $SHA"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
git -C "$TMP" init -q
git -C "$TMP" remote add origin https://github.com/videolan/vlc.git
git -C "$TMP" fetch --depth 1 origin "$SHA"
git -C "$TMP" checkout -q FETCH_HEAD
rm -rf "$TMP/.git"
rm -rf "$ROOT/vlc"
mv "$TMP" "$ROOT/vlc"
trap - EXIT
echo "$SHA" > "$ROOT/vlc/.vendored"
# optional second argument: a directory of patches to apply (e.g. the
# libvlcjni android patch stack) — recorded in vlc/.patched
if [ -n "$2" ] && [ -d "$2" ]; then
    for p in "$2"/*.patch; do
        ( cd "$ROOT/vlc" && git apply "$p" ) || { echo "patch failed: $p"; exit 1; }
    done
    { echo "patches from: $2"; ls "$2"; } > "$ROOT/vlc/.patched"
    echo "applied $(ls "$2"/*.patch | wc -l) patches (recorded in vlc/.patched)"
fi
echo "vlc/ now at $SHA — update VERSIONS, review and commit."

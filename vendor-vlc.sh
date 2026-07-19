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
echo "vlc/ now at $SHA — update VERSIONS, review and commit."

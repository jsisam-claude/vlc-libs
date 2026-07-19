# vlc-libs

Shared vendored **source** for the VLC-based projects in this account
(vlc-android privacy fork, vlc-windows, gallery). Nothing in this repository
is a binary or prebuilt: it holds upstream source trees and, once populated,
hash-verified **source archives** that the projects compile themselves.

## Layout

| Path | Contents |
|---|---|
| `vlc/` | Full VLC source tree, branch `3.0.x`, pinned commit in `vlc/.vendored` (from the github.com/videolan/vlc mirror, `.git` stripped) |
| `contrib-tarballs/` | Cache of VLC contrib **source** tarballs (ffmpeg, dav1d, gnutls, …). Every archive is SHA-512-verified by VLC's own contrib build system against the checksums committed in `vlc/contrib/src/*/SHA512SUMS`. Populated by `fetch-contribs.sh`, then committed. |
| `contrib-src/` | **Pruned** contrib set vendored as source trees from each project's **official repository** at the exact production version the recipes pin (ffmpeg, libass, freetype, fribidi, harfbuzz, ogg, libebml, libmatroska). Provenance in each `.vendored` file. |
| `contrib-pruned.list` | The pruned package list (what's vendored, what's supplemented, what was dropped and why) |
| `make-contrib-tarballs.sh` | Generates the archives vlc/contrib expects from `contrib-src/` and re-pins the `SHA512SUMS` in the vlc tree accordingly |
| `vendor-vlc.sh` | Re-vendors `vlc/` at an exact upstream commit (used when a consumer pins a different VLC revision) |
| `fetch-contribs.sh` | Populates `contrib-tarballs/` using VLC's own fetch machinery (run once on a machine with network access, then commit) |
| `VERSIONS` | Machine-readable pin list |

## Policy

- Upstream **git trees** are committed as plain source with a `.vendored`
  marker file recording the exact commit.
- Third-party **source archives** (contribs, sqlite) are committed as the
  original tarballs, pinned by the SHA-512 sums that upstream's build system
  enforces at extract time. They are compiled from source during the build —
  no prebuilt binaries, no downloads at build time once this repo is populated.
- No jars, AARs, `.so`/`.dll`/`.a` files, or tool binaries, ever.

## Consumers

`vlc-android` (the privacy fork) expects this repository checked out as a
**sibling directory** (`../vlc-libs`). Its `tools/vendor-videolan.sh` links
`libvlcjni/vlc → ../../vlc-libs/vlc` and its build reads contrib tarballs via
`TARBALLS=$PWD/../vlc-libs/contrib-tarballs`.

## Populating the contrib cache (one-time)

```sh
./make-contrib-tarballs.sh   # archives from the official-source trees in contrib-src/
./fetch-contribs.sh          # supplement: official release archives for gnutls,
                             # nettle, gmp, libiconv, libdvbpsi (SHA-512-verified)
git add -A && git commit -m "Vendor contrib source archives"
```

`make-contrib-tarballs.sh` needs autotools + xz on the machine running it.
The android build may top the cache up with a few target-specific archives on
its first run (same verification path); commit those additions the same way.

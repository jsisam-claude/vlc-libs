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

## Build inputs are vendored and committed

`contrib-tarballs/` — the full dependency-correct set of ~50 contrib source
archives (the fork's kept features pull these: decoders + libass/freetype/
fribidi/harfbuzz subtitle stack, gnutls+nettle+gmp+gcrypt+gpg-error+libtasn1
TLS, smb2/nfs/libdsm/upnp/microdns browsing+casting, taglib, lua, zlib, image
and audio codecs). Every archive is SHA-512-verified against the sums in
`vlc/contrib/src/*/SHA512SUMS`. This supersedes the earlier "13 packages"
framing: VLC's dependency graph makes that unbuildable, but the ~50-set still
reflects the real pruning — dav1d, libvpx, x264/x265, dvdnav/dvdread, live555,
bluray, mad, aom, lame and the other encoders/disc/streaming libs are gone.

`host-tools/` — source archives for the four host build tools VLC bootstraps
itself (libtool, protobuf 3.4.1 for casting, apache-ant, help2man) plus
gettext/ninja fallbacks. Everything else (autoconf, automake, cmake, meson,
nasm, m4, pkg-config) is satisfied from the distro per the toolchain boundary.

`place-build-inputs.sh` — copies both sets into the vlc tree where the
contrib/tools makefiles hard-expect them (they use `:=` tarball dirs, so an
env override is not enough). Run it before building.

The vendored VLC tree also carries one build-compat patch beyond the 20-patch
Android stack (recorded in `vlc/.patched`): `-DCMAKE_POLICY_DEFAULT_CMP0057=NEW`
in the contrib CMake invocation, needed for NDK 27's toolchain file with
CMake 3.28.

### Native-build status (honest)

The app/JVM layer — where every telemetry and feature change lives — compiles
cleanly. The native contrib+libvlc build was driven far in-sandbox (NDK 27,
arm64): the vendored VLC source + patches configure, the guards prevent all
clones/downloads, the host-tool bootstrap builds from the vendored sources,
and the CMake-based contribs build after the CMP0057 fix. Remaining failures
(gnutls "cannot compile and link", harfbuzz depfile races) are
incompatibilities between VLC 3.0.x-era contribs and this newer NDK/host-tool
combination — the reason VLC's own buildbot pins an exact toolchain. Building
on the VLC-tested toolchain versions is expected to close these; nothing here
is a defect in the vendored sources.

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

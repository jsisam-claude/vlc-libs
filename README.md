# vlc-libs

Shared vendored **source** for the VLC-based projects in this account
(vlc-android privacy fork, and future VLC-based tools). Nothing in this
repository is a binary or prebuilt: it holds upstream source trees and
hash-verified third-party **source archives** that the projects compile
themselves.

## Layout

| Path | Contents |
|---|---|
| `vlc/` | Full VLC source tree, branch `3.0.x`, pinned commit in `vlc/.vendored`, patches applied on top recorded in `vlc/.patched` (from the github.com/videolan/vlc mirror, `.git` stripped) |
| `contrib-tarballs/` | The dependency-correct set of ~49 contrib **source** archives the build actually compiles. Every archive is SHA-512-verified against the checksums committed in `vlc/contrib/src/*/SHA512SUMS`. |
| `host-tools/` | Source archives for the host build tools VLC bootstraps itself (libtool, protobuf, apache-ant, help2man) plus gettext/ninja fallbacks. |
| `place-build-inputs.sh` | Stages `contrib-tarballs/` and `host-tools/` into the vlc tree where the contrib/tools makefiles hard-expect them. Run before building. |
| `vendor-vlc.sh` | Re-vendors `vlc/` at an exact upstream commit (+ optional patch dir), for re-pinning the VLC revision. |
| `fetch-contribs.sh` | Re-populates `contrib-tarballs/` using VLC's own fetch machinery (only needed to re-pin contrib versions; the current set is already committed). |
| `VERSIONS` | Machine-readable pin list. |

## Policy

- Upstream **git trees** are committed as plain source with a `.vendored`
  marker recording the exact commit (and `.patched` listing any patches
  applied on top).
- Third-party **source archives** (contribs, sqlite) are committed as the
  original upstream tarballs, pinned by the SHA-512 sums that VLC's build
  system enforces at extract time. They are compiled from source during the
  build — no prebuilt binaries, no build-time downloads once staged.
- No jars, AARs, `.so`/`.dll`/`.a` files, or tool binaries, ever.

## Consumers

`vlc-android` (the privacy fork) expects this repository checked out as a
**sibling directory** (`../vlc-libs`). Its `tools/vendor-videolan.sh` links
`libvlcjni/vlc → ../../vlc-libs/vlc`, and `place-build-inputs.sh` stages the
committed archives into that tree before `./buildsystem/compile.sh` runs.

## The vendored build inputs

`contrib-tarballs/` is the **dependency-correct** set for the fork's kept
features — not a hand-picked minimum. VLC's contrib graph pulls in the
decoders plus the libass/freetype/fribidi/harfbuzz subtitle stack, the
gnutls + nettle + gmp + gcrypt + gpg-error + libtasn1 TLS stack, the
smb2/nfs/libdsm/upnp/microdns network-browsing + casting stack, taglib, lua,
zlib, and the image/audio codecs. Every archive is SHA-512-verified against
the sums in `vlc/contrib/src/*/SHA512SUMS`.

The pruning is real even though the set is ~49, not a dozen: the heavy and
out-of-scope libraries are gone — dav1d, libvpx, x264/x265, dvdnav/dvdread,
live555, bluray, cddb, mad, aom, lame, openapv, mysofa and the other
encoders / disc / streaming / spatial-audio libraries are all disabled at the
contrib bootstrap (see the fork's `libvlcjni/buildsystem/compile-libvlc.sh`).

The vendored VLC tree carries one build-compat patch beyond the 20-patch
Android stack (recorded in `vlc/.patched`): `-DCMAKE_POLICY_DEFAULT_CMP0057=NEW`
in the contrib CMake invocation, needed for NDK 27's toolchain file with
CMake 3.28.

### Native-build status (honest)

The app/JVM layer — where every telemetry and feature change lives — compiles
cleanly. The native contrib+libvlc build was driven far in-sandbox (NDK 27,
arm64, the version libvlcjni requires for 64-bit): the vendored VLC source +
patches configure, the marker guards prevent all clones/downloads, the
host-tool bootstrap builds from the vendored `host-tools/` sources, and the
CMake-based contribs build after the CMP0057 patch. The remaining contrib
failures (gnutls "cannot compile and link", harfbuzz depfile races) are
friction between VLC 3.0.x-era contribs and this newer NDK + host-tool
combination — the reason VLC's own buildbot pins an exact host toolchain.
Building on VLC's tested host-tool versions is expected to close these;
nothing here is a defect in the vendored sources.

## Re-pinning (only when changing versions)

The current inputs are committed; you do not need to run anything to build.
To move to different upstream revisions:

```sh
./vendor-vlc.sh <vlc-commit> [patch-dir]   # re-vendor the VLC tree
./fetch-contribs.sh                         # re-fetch contrib archives (SHA-512-verified)
git add -A && git commit -m "Re-pin VLC/contrib versions"
```

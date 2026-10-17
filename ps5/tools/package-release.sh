#!/usr/bin/env bash
# Dusklight for the PlayStation 5 - pack the built title folder as a release archive.
#
#   ps5/tools/package-release.sh VERSION      (through tools/vm.sh package-release 0.1.0)
#
# Writes dist/Dusklight-PS5-vVERSION.zip: the title folder dist/<TITLE_ID>/ as the
# console takes it (eboot.bin, sce_sys/, sce_module/, res/, licenses/), with
# SOURCE.txt beside eboot.bin naming the revision of every part the build
# linked. A built title is under GPL-3.0: that file is how a release says where
# its source is. No disc image, save or cache goes in, and it refuses if one is
# in the folder.
#
# After the Quake3e port's package-release.sh.
# SPDX-License-Identifier: MIT
set -euo pipefail
version=${1:?usage: package-release.sh VERSION}
ps5=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
root=$(dirname "$ps5")
vulkan=$(cd -- "${PS5_VULKAN_DIR:-$root/../PS5_Vulkan}" && pwd)
dusklight="$root/vendor/dusklight"
title_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["titleId"])' "$ps5/sce_sys/param.json")
app="$root/dist/$title_id"
for file in eboot.bin sce_sys/param.json sce_sys/icon0.png sce_sys/pic0.dds sce_sys/pic1.dds sce_module/libc.prx res/rml; do
    [[ -e $app/$file ]] || { echo "missing $app/$file: run build.sh first" >&2; exit 2; }
done
[[ -f $app/res/logo.png ]] || { echo "$app is the renderer test, not the game: run build.sh" >&2; exit 2; }
stray=$(find "$app" \( -iname '*.iso' -o -iname '*.ciso' -o -iname '*.gcm' -o -iname '*.rvz' -o -iname '*.gci' \
    -o -name userdata -o -name 'radv-shader-cache' \) -print -quit)
[[ -z $stray ]] || { echo "game data or a save in the title folder ($stray): a release never carries it" >&2; exit 2; }
# the submodule's working tree carries the console's patches: that is not a change here
[[ -z $(git -C "$root" status --porcelain --ignore-submodules=dirty) ]] ||
    { echo "uncommitted changes: a release is built from a commit" >&2; exit 2; }
provenance="$vulkan/.deps/native/radv-release/PROVENANCE.txt"
versions="$dusklight/extern/aurora/cmake/AuroraDependencyVersions.cmake"
mkdir -p "$app/licenses"
cp "$root/licenses/GPL-3.0.txt" "$root/licenses/MIT.txt" "$root/licenses/Zlib.txt" "$app/licenses/"
cp "$root/LICENSING.md" "$app/licenses/LICENSING.md"
cp "$dusklight/extern/borealis/LICENSE" "$app/licenses/Borealis-LICENSE.txt"
cat > "$app/SOURCE.txt" <<SOURCE
Dusklight for PlayStation 5, version $version
An unofficial homebrew port. Not affiliated with the Dusklight project, Nintendo
or Sony Interactive Entertainment.

This title is distributed under the GNU General Public License, version 3
(licenses/GPL-3.0.txt). Its source is these projects at these revisions:

The port (patches, SDL3 drivers, disc reader, platform layer, build)
  $(git -C "$root" remote get-url origin 2>/dev/null || echo "this repository")
  $(git -C "$root" rev-parse HEAD)
The game's code: Dusklight (CC0-1.0), with ps5/patches/dusklight.patch
  https://github.com/TwilitRealm/dusklight
  $(git -C "$dusklight" rev-parse HEAD)
The GameCube layer: Aurora (MIT), with ps5/patches/aurora.patch
  https://github.com/encounter/aurora
  $(git -C "$dusklight/extern/aurora" rev-parse HEAD)
Support code: Borealis (MIT), with ps5/patches/borealis.patch
  https://github.com/encounter/borealis
  $(git -C "$dusklight/extern/borealis" rev-parse HEAD)
WebGPU: Dawn (BSD-3-Clause), with ps5/patches/dawn.patch and dawn-abseil.patch
  https://github.com/encounter/dawn
  $(sed -n 's/^_aurora_dependency_version(AURORA_DAWN_REF "\([0-9a-f]\{40\}\)".*/\1/p' "$versions")
SDL3 (Zlib), with ps5/patches/sdl.patch and the drivers in ps5/sdl
  https://github.com/libsdl-org/SDL
  $(sed -n 's/^_aurora_dependency_version(AURORA_SDL3_REF "refs\/tags\/\([^"]*\)".*/\1/p' "$versions")
The Vulkan driver: RADV, from PS5_Mesa (MIT)
  https://github.com/mihawk-99/PS5_Mesa
  $(sed -n 's/^revision: //p' "$provenance")
The link recipe, CRT, libc.prx and packaging: PS5_Vulkan (GPL-3.0)
  https://github.com/mihawk-99/PS5_Vulkan
  $(git -C "$vulkan" rev-parse HEAD)
The platform layer and SDK: PS5_PayloadSDK (GPL-3.0), over ps5-payload-dev/sdk v0.42
  https://github.com/mihawk-99/PS5_PayloadSDK
  title: $(sed -n 's/^sdk_revision=//p' "$ps5/tools/setup-sdk.sh")
  RADV archive: $(sed -n 's/^sdk: //p' "$provenance")
The other libraries Aurora and Dusklight fetch (fmt, zstd, libpng, FreeType,
Dear ImGui, RmlUi, SQLite, xxHash, Tracy, miniz, PicoSHA2, cxxopts) are at the
versions those two projects name, at the revisions above.
Compiler: $(${PS5_CLANG:-clang} --version | head -1)

No game data is included. The Legend of Zelda: Twilight Princess belongs to
Nintendo; this title does nothing without a GameCube disc image (.iso or .ciso)
that you provide in /data/dusklight/$title_id/images/ (legacy app-folder images
are imported on first protected launch). Saves/settings use the sibling user/
directory so later app-folder replacement does not own personal data.
The pictures in sce_sys/ are the
port's own, made for it with an image generator; nothing in them is from the game.

eboot.bin sha256: $(sha256sum "$app/eboot.bin" | cut -d' ' -f1)
SOURCE
out="$root/dist/Dusklight-PS5-v$version.zip"
rm -f "$out"
(cd "$root/dist" && zip -q -r -X "$out" "$title_id" -x '*/.DS_Store')
printf '==> %s (%s bytes)\n' "$out" "$(stat -c %s "$out")"
unzip -l "$out" | tail -n +4 | awk '{print "    " $1, $4}' | grep -v "/res/" | head -30

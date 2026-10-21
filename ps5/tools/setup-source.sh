#!/usr/bin/env bash
# Dusklight for the PlayStation 5 - Dusklight's sources, with the console's changes.
#
#   ps5/tools/setup-source.sh    check out vendor/dusklight and apply ps5/patches to it
#
# Dusklight is a submodule at an upstream revision, with Aurora and Borealis as
# submodules of its own. What the console needs changed in them is kept here as
# patches, not as a fork:
#
#   ps5/patches/dusklight.patch  the disc image found in the title's folder (no
#                                file dialog), and std::atomic_ref for libc++ 18
#   ps5/patches/aurora.patch     the console's surface for Dawn, and .dds texture
#                                replacements saved as sRGB
#   ps5/patches/borealis.patch   ElfW for a FreeBSD's link.h
#
# A patch already applied is left alone, so this can run before every build.
#
# SPDX-License-Identifier: MIT
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
dusklight="$root/vendor/dusklight"

[[ -f $dusklight/CMakeLists.txt ]] || git -C "$root" submodule update --init vendor/dusklight
[[ -f $dusklight/extern/aurora/CMakeLists.txt && -f $dusklight/extern/borealis/CMakeLists.txt ]] ||
    git -C "$dusklight" submodule update --init extern/aurora extern/borealis

apply() {
    local tree=$1 patch="$root/ps5/patches/$2"
    if git -C "$tree" apply --reverse --check "$patch" 2>/dev/null; then
        return 0 # applied already
    fi
    git -C "$tree" apply --check "$patch" || {
        echo "setup-source.sh: $2 does not apply to $tree (a different upstream revision?)" >&2
        exit 2
    }
    git -C "$tree" apply --whitespace=nowarn "$patch"
    echo "setup-source.sh: applied $2" >&2
}
apply "$dusklight" dusklight.patch
apply "$dusklight/extern/aurora" aurora.patch
apply "$dusklight/extern/borealis" borealis.patch
apply "$dusklight" ui.patch

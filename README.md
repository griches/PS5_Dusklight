> **Draft candidate — HOLD for console testing.** See [PAL/UI test notes](PAL-UI-TESTING.md) for the shared five-language menu, controller picker, progress display and Gary-style buttons.

# Dusklight for PlayStation 5

[![stars](https://img.shields.io/github/stars/griches/PS5_Dusklight?style=flat)](https://github.com/griches/PS5_Dusklight/stargazers)
[![release](https://img.shields.io/github/v/release/griches/PS5_Dusklight)](https://github.com/griches/PS5_Dusklight/releases/latest)
[![Track Dusklight](https://github.com/griches/PS5_Dusklight/actions/workflows/track-dusklight.yml/badge.svg)](https://github.com/griches/PS5_Dusklight/actions/workflows/track-dusklight.yml)
[![licence](https://img.shields.io/badge/licence-GPL--3.0%20as%20built-blue)](LICENSING.md)

A PS5 homebrew port of [Dusklight](https://github.com/TwilitRealm/dusklight), the
reverse-engineered reimplementation of a classic GameCube adventure. It draws
through Dusklight's own renderer ([Aurora](https://github.com/encounter/aurora) on
Dawn's WebGPU) on RADV, Mesa's Vulkan driver, from the
[PS5 Vulkan](https://github.com/mihawk-99/PS5_Vulkan) stack.

It needs a PS5 that already runs homebrew, and a disc image of the game that you
provide. No game data, Nintendo artwork, Sony software or keys are included, here
or in a build.

This is an unofficial port. It is not part of the Dusklight project and is not
supported by it: please do not take PS5 problems to them.

## Status

Tested on one console, on 2026-10-10 and 11, with the GameCube USA disc (GZ2E01).
"Seen" means it ran there and was watched, or read in the console's log; nothing
else is claimed.

| Area | Seen on the console | Not yet verified |
| --- | --- | --- |
| Start-up | Finds the disc image in the title's folder, boots into the game | Exit back to the home screen from the game's own menu |
| Rendering | 3840x2160 on a 59.94 Hz display, several minutes of play with no crash | Frame rate over a long session; 120 Hz; later areas of the game |
| Saving | A memory card file is created, and a save survived closing and restarting the title | |
| Button prompts | The DualSense's symbols on the game's buttons, on the file select and in play: Cross (A), Circle (B), Square (X), Triangle (Y), R1 (Z) | Other prompts (L, R, Start, the D-pad and stick pictures); a changed button mapping; the other regions' discs |
| Input | A DualSense plays the game | Each button of the mapping; rumble; a second controller |
| Sound | | Everything: the driver opens, nobody has confirmed what it sounds like |
| Shader cache | Aurora's pipeline cache opens and is written | That it is reused after a restart |

Known limits:

- **Objects can appear a frame late the first time a scene shows them.** Aurora
  compiles each new render pipeline on a worker thread and skips the draw until
  it is ready, as it does on every platform. They are cached once compiled.
- **Disc images: GameCube `.iso` or `.ciso` only.** Upstream reads RVZ, GCZ, WIA
  and WBFS through a Rust library; this port has its own small reader in its
  place (`ps5/nod/`). Wii discs are not supported.
- **No code mods, no updater, no Discord presence, no network.** They are turned
  off in this build. The mods in Dusklight's `mods/` folder (the randomizer, the
  Luau runtime and the rest) are code mods, so none is bundled, and a mod that
  needs the Luau runtime does not run. An asset-only `.dusk` (textures, files
  that replace the disc's) put in `/data/homebrew/PPSA99305/mods/` is listed and
  can be switched on in the Mods menu. Online mods cannot be browsed.
- **"Disc not verified" on the menu can be expected.** An automatically found
  disc has not yet been hashed; choosing it from the controller picker runs the
  normal upstream verification. A `.ciso` leaves out the disc's filler
  data, so its hash could not match the original's anyway.
- **The button symbols follow the default mapping.** The game draws a button as
  a coloured shape with a white letter, each letter a texture of its own; the
  port replaces those five textures with symbols from Kenney's Input Prompts
  (www.kenney.nl, CC0; `ps5/art/kenney/`, cut to size by `ps5/art/make-glyphs.py`,
  shipped in `res/ps5-glyphs/`, loaded as texture replacements named for the
  USA disc's textures), and turns the green tint of the A button blue. They say Cross for A, Circle for B, Square for X,
  Triangle for Y and R1 for Z, which is Dusklight's default mapping: remap the
  buttons and the symbols no longer match. A replacement of your own for the
  same texture wins, and turning texture replacements off in the settings turns
  these off too.
- **Texture packs: loose files or a `.dusk`, `.png` or `.dds`.** Files named the
  way Dolphin names them (`tex1_256x128_e6a4c7be9bf48305_14.dds`) are picked up
  from `/data/dusklight/PPSA99305/user/texture_replacements/`
  and its subfolders, or from the `textures/` folder of a `.dusk`. A `.dds` may
  be uncompressed 32-bit RGBA or BGRA, BC1 (DXT1), BC3 (DXT5), BC5 or BC7, with
  or without mipmaps; this port also takes the sRGB-tagged variants of those,
  which upstream refuses. BC2 (DXT3), BC4, BC6H and ASTC are not loaded, and a
  compressed texture's width and height must be multiples of 4. Seen on the
  console on 2026-10-12 with three test files in the loose folder: BC7 tagged
  sRGB with mipmaps, DXT5, and uncompressed RGBA; a real texture pack has not
  been tried. The game makes that folder at its first start, and from this
  build on opens it to the FTP server at every start: with v0.2.0 an upload
  into it is refused until the folder's permissions are changed.
- **Disc selection uses a controller folder/file browser.** Navigate USB0/USB1
  subfolders or /data, select an ISO/GCM/CISO and use it directly at that path.
  No internal copy is required. No disc is copied or restored automatically.
  App-local images require explicit **Move and use ISO** to protect them before
  a future Store update. GameCube PAL `GZ2P01` uses upstream's PAL code/languages;
  USA and Japan retain their own regions. All three require revision 0.

## Install

Download `Dusklight-PS5-vX.Y.Z.zip` from the
[latest release](https://github.com/griches/PS5_Dusklight/releases/latest) and
unpack it: it holds one folder, `PPSA99305`. (Or build that folder yourself, see
Build.) It contains no game data.

**What the console needs**

- A PS5 that runs homebrew, with etaHEN (or an equivalent) loaded.
- ShadowMountPlus, which shows the folders in `/data/homebrew` as titles on the
  home screen.
- A way to copy files, such as a web file manager or an FTP server.
- Write access to `/data`. If the title is sandboxed, the **Lapy owned-root daemon**
  must already be running. Startup uses the cooperative filesystem request supplied
  by this port's existing SDK pin, before worker threads start; it does not install
  a daemon or change that SDK pin. A failed request blocks game launch and shows an
  error instead of silently storing personal data inside the replaceable app folder.

**Steps**

1. Unpack the release (or build: the result is the folder `dist/PPSA99305/`).
2. Copy that whole folder to the console as `/data/homebrew/PPSA99305/`, so that
   you have:

   ```text
   /data/homebrew/PPSA99305/eboot.bin
   /data/homebrew/PPSA99305/sce_sys/      (param.json, icon0.png, pic0.dds, pic1.dds)
   /data/homebrew/PPSA99305/sce_module/libc.prx
   /data/homebrew/PPSA99305/res/          (fonts and the menus' documents)
   /data/homebrew/PPSA99305/licenses/
   ```

   Copy `sce_sys/icon0.png` with the first upload: ShadowMountPlus will not
   register a title without its icon, and after two failed tries it skips that
   title until it is restarted.
3. Put your `.iso`, `.gcm` or `.ciso` on a USB drive or a folder outside the
   application, for example `/data/dusklight/PPSA99305/images/your-disc.iso`.
   Subdirectories are supported. No internal copy is needed for USB play.
4. Start Dusklight and open **Select Disc Image**. Navigate from **Locations** to
   your disc, select it and let normal disc verification finish. The browser
   stays over the illustrated menu, with cancelable folder-reading feedback.
   With PAL, the pre-launch game-language setting offers German and the other
   PAL languages. A changed disc/language can require closing and reopening.

If an ISO is already beside `eboot.bin`, the browser offers **Move and use ISO**.
Only this explicit action moves that selected disc to the persistent images
folder. A same-filesystem rename needs no duplicate allocation. Across filesystems
a temporary copy is byte-verified before removing the selected original, with
copy/verification progress. Cancel/error retains the source. Other images are
never moved. Different same-name images get numbered names without overwriting.
No launch or directory scan bulk-copies ISOs or restores deleted copies.

Saves/settings live in `/data/dusklight/PPSA99305/user/`. Existing
`userdata/TwilitRealm/Dusklight/` files, legacy/portable user data and matching
Store-backup user data are imported without deleting originals. Protected current
files take priority. This user-data migration does not import ISO images.

**Before the first upgrade from an old build, preserve images and userdata.**
An installer can erase the app folder before the new code gets to run. Move an
app-local ISO outside that folder before any later update, or select one directly
from USB. A deliberately app-local ISO cannot survive replacement there. Files
deleted by an older update cannot be recovered without a surviving backup.

Earlier separate test builds passed manual PAL selection and startup.
The new combined UI/progress candidate still needs its own console test and
a real Store update has not been tested. Earlier USA runtime observations in the Status table describe the
unmodified release, not proof of this patch's runtime behavior.

**The disc image.** Dusklight's own terms apply: dump your own copy of the game
([how](https://wiki.dolphin-emu.org/index.php?title=Ripping_Games)). If your dump
is RVZ or another compressed format, convert it to `.iso` with
[Dolphin](https://dolphin-emu.org/) or `nodtool` first.

## Build

The build runs on Linux (x86-64 or arm64; on a Mac, in a Linux VM) with Mihawk's
stack beside this repository:

```text
somewhere/
  PS5_Dusklight/     this repository
  PS5_Vulkan/        https://github.com/mihawk-99/PS5_Vulkan   (with its RADV release archive built)
  PS5_Mesa/          https://github.com/mihawk-99/PS5_Mesa
  PS5_PayloadSDK/    https://github.com/mihawk-99/PS5_PayloadSDK
```

Set that stack up first, by its own instructions, until `PS5_Vulkan` has
`.deps/native/radv-release/lib/libvulkan_radeon.ps5.a` and
`build/host/ps5-native-tool`. It needs **LLVM 22**: RADV built with an older clang
does not link into a title. Then:

```sh
git clone https://github.com/griches/PS5_Dusklight.git
cd PS5_Dusklight
ps5/tools/build.sh
```

`build.sh` does the rest, and the first run takes a while:

1. checks out Dusklight (`vendor/dusklight`) with Aurora and Borealis, and applies
   `ps5/patches/` to them;
2. fetches Dawn and SDL3 at the revisions Aurora pins into `.deps/`, and patches
   them for the console;
3. installs the payload SDK at this port's pin;
4. configures Dusklight's own CMake build with the SDK's toolchain and
   `ps5/cmake/ps5-game.cmake`, compiles about 3,000 files, links with RADV and
   writes `dist/PPSA99305/`.

Run the standalone synthetic storage/disc tests on Linux with:

```sh
python3 ps5/tools/test-storage.py
```

They use this port's actual ISO/CISO reader with ASan/UBSan and cover all three
GameCube regions, retained USB choices, old userdata layouts, fresh nested USB browsing, no automatic ISO copies,
+explicit moves, copy/verify cancellation across filesystems, same-name conflicts
+and replacement of the complete app folder. No game data is
needed. These tests do not establish console sandbox/daemon behavior or gameplay.

Other tools, all in `ps5/tools/`:

| Tool | What it does |
| --- | --- |
| `deploy.sh` | Uploads `dist/PPSA99305/` over FTP (the console's address is `PS5_HOST` in `PS5_Vulkan/.env`). It never touches the disc image or `userdata/`. |
| `run.sh` | Launches the title through PS5_Vulkan's control payload and follows its log; symbolises a crash. |
| `package-release.sh VERSION` | Packs `dist/PPSA99305/` as a release zip with `SOURCE.txt`, the revision of every part. Refuses if a disc image or a save is in the folder. |
| `build-triangle.sh` | Builds a one-triangle WebGPU test in the game's place: the first thing to run when Dawn or the driver changes. |
| `vm.sh TOOL` | From macOS, runs one of the above inside a Lima VM named `ps5`. |
| `update-dusklight.sh` | Moves to upstream Dusklight's latest revision and re-applies the patches. |
| `check-patches.sh` | Says whether the Dawn and SDL3 patches apply to what Aurora now pins. |

## Keeping up with Dusklight

`vendor/dusklight` is a submodule at an upstream revision; nothing of Dusklight is
copied or forked here. What the console needs changed in Dusklight, Aurora and
Borealis is three small patches in `ps5/patches/`; Dawn and SDL3 have theirs
there too.

A [scheduled workflow](.github/workflows/track-dusklight.yml) runs
`update-dusklight.sh` every day. If the patches still apply to upstream's newest
revision, it commits that revision, so a fresh clone builds against the latest
Dusklight the patches fit. If one does not, it commits nothing and opens an issue.
It cannot build the game, so a revision it commits is not known to compile or
run: the Status table above is for the revision it was tested at
(`34a144a493`).

## How it works

```text
  Dusklight (the game's code)                     vendor/dusklight
        |
  Aurora ........ GameCube GX, pads, cards, DVD   vendor/dusklight/extern/aurora
        |              |               |
      Dawn           SDL3             nod
   (WebGPU)     ps5/sdl drivers    ps5/nod: .iso and .ciso
        |
  Vulkan: RADV + PS5 winsys, VK_KHR_display       PS5_Mesa, PS5_Vulkan
        |
  PS5 GPU
```

- **Dawn.** The fork Aurora uses already had a console port (Nintendo Switch):
  a Vulkan driver linked into the program and a native-window surface.
  `ps5/patches/dawn.patch` adds the PS5 beside it: RADV's entry point in place of
  a Vulkan library, and the console's one output as a `VK_KHR_display` surface.
- **SDL3.** Threads, time and files are FreeBSD's. `ps5/sdl/` adds a video driver
  (one display, a window that is the screen), an audio driver (AudioOut, 48 kHz
  stereo) and a joystick driver that presents each controller as a DualSense.
- **nod.** Aurora reads discs through nod, a Rust library. There is no Rust
  toolchain for the console, so `ps5/nod/nod.cpp` implements the part of nod's C
  API that is called, for plain and CISO GameCube images.
- **The console's quirks**, each found the hard way and explained where it is
  handled: constructors that ran in reverse (`ps5/tools/cc-init-array.sh`), an
  `lstat` that does not work for a title and other missing libc functions
  (`ps5/src/shims.c`), and where a title may write (`ps5/src/startup.c`).

## Credits

- [Dusklight](https://github.com/TwilitRealm/dusklight) by Twilit Realm and its
  contributors, on the [Twilight Princess decompilation](https://github.com/zeldaret/tp).
- [Aurora](https://github.com/encounter/aurora), [Borealis](https://github.com/encounter/borealis),
  [nod](https://github.com/encounter/nod) and the Dawn fork by Luke Street (encounter) and contributors.
- [PS5_Vulkan](https://github.com/mihawk-99/PS5_Vulkan), [PS5_Mesa](https://github.com/mihawk-99/PS5_Mesa),
  [PS5_PayloadSDK](https://github.com/mihawk-99/PS5_PayloadSDK) and the
  [PS5 Vulkan Template](https://github.com/mihawk-99/PS5_VulkanTemplate) by Mihawk:
  the driver, the platform layer and the tools this is built with.
- [ps5-payload-dev/sdk](https://github.com/ps5-payload-dev/sdk) by John Törnblom.
- Mesa and RADV, Dawn, SDL, and the libraries listed in [LICENSING.md](LICENSING.md).
- Kenney (www.kenney.nl) for the button symbols, from Input Prompts (CC0).

## Licence

See [LICENSING.md](LICENSING.md). In short: the port's own files are MIT or Zlib,
one tool is GPL-3.0, and a built title is GPL-3.0 because of what it links. The
game itself is Nintendo's and is not part of this.

# TexturePacker Importer

This is a plugin for [Godot Engine](https://godotengine.org) to import sprite sheets
generated with [TexturePacker](https://www.codeandweb.com/) as 
Godot `AtlasTexture`.

**Note:** This plugin version is compatible with Godot 4.0 and newer.
Use the version from the **godot-3** branch if your are using Godot 3.


## Installation

Simply download it from [Godot Asset Library](https://godotengine.org/asset-library/asset/1503)

Alternatively, download or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder.

**Important**: Enable the plugin on the Project Settings.

## Features

* Import sprite sheets as AtlasTextures
* Supports trimmed sprites (margin)
* Supports MultiPack
* Supports normal maps
* Generates an AnimationLibrary for AnimationPlayer from the animations
  detected by TexturePacker

## Usage (once the plugin is enabled)

1. Create a sprite sheet in TexturePacker
2. Save the image and .tpsheet file in the godot asset folder
3. Watch Godot import it automatically.

## Using the generated animations (AnimationPlayer + Sprite2D)

Enable **Detect animations** in TexturePacker (8.2.0 or newer): sprites whose
file names end in a frame number (e.g. `run-right/RunRight_0001.png` …
`RunRight_0006.png`) are grouped into animation sequences and written to the
.tpsheet. The importer
saves one `AnimationLibrary` per sheet to `<sheet>.animations.tres`, containing
one looping animation per sequence (10 fps), named after the sprite path
(`Character-run-right-RunRight` — `/` is not allowed in Godot animation names).
Each animation drives the `atlas`, `region` and `margin` of a single
`AtlasTexture` — trimmed sprites play with the correct size and offset, without
one texture resource per frame, and multipack sheets work since the atlas is
keyframed too.

To use it in your scene:

1. Add a `Sprite2D` and assign it any `AtlasTexture`
   (make it unique — the animation modifies it).
2. Add an `AnimationPlayer` as a **child of the Sprite2D** and set its
   **Root Node** to `..` (the Sprite2D). The animation tracks use the paths
   `.:texture:region` etc., so no node names are baked in.
3. In the AnimationPlayer's animation list, choose **Manage Animations… →
   Load Library** and select `<sheet>.animations.tres`. Load it under the
   empty library name (the default) — otherwise animations must be addressed
   as `"libraryname/animation"`.
4. Play any of the generated animations, e.g. from code:
   `$Sprite2D/AnimationPlayer.play("Character-run-right-RunRight")`

Sprites without a trailing frame number are treated as static poses and get no
animation.

The frame tracks are regenerated on every import, but **loop mode and playback
speed you change in the editor are preserved**, matched by animation name.
Changing an animation's length changes its per-frame speed, and that per-frame
speed is what survives reimports — if the frame count changes, the total
length scales with it. Renaming a sequence in TexturePacker resets its
settings to the defaults (10 fps, looping), and custom tracks added to a
generated animation are discarded on reimport. For playback-only speed changes
you don't need to touch the library at all:
`play("Character-run-right-RunRight", -1, 1.5)` or `speed_scale`.


## Known issues

- TileSet import no longer supported: Godot 3 had an API where a tile could be
  retrieved by its name. This is no longer available in Godot 4.


# Release notes

### 4.8.0 (unreleased)

* Generate an `AnimationLibrary` per sheet (`<sheet>.animations.tres`) from the
  animations exported by TexturePacker (requires TexturePacker 8.2.0 or newer
  with **Detect animations** enabled)
* Animations drive `atlas`, `region` and `margin` of a single `AtlasTexture`
  for AnimationPlayer + Sprite2D — trimmed sprites and multipack sheets work
* Loop mode and speed changed in the Godot editor are preserved on reimport
* An existing `<sheet>.animations.tres` is never deleted
* Fixed: with normal maps, generated resources embedded duplicate copies of
  the `CanvasTexture` instead of referencing the generated `.tres` file

### 4.7.1 (2026-07-07)

* Minor repository cleanup

### 4.7.0 (2026-06-23)

* Compatibility with Godot 4.7 import pipeline
* Register sheet images as import dependencies via `append_import_external_resource()`
* Reload imported textures with `CACHE_MODE_REPLACE_DEEP` so fresh imports are picked up
* Added fallback return in `_get_preset_name()` (required by Godot 4.7 parser)
* Guard recursive sprite cleanup against missing directories
* Clarified minimum supported Godot version as 4.3

### 4.3.0 (2025-12-08)

* Support sprites with normal map (use CanvasTexture if normal map is present)

### 4.2.0 (2025-06-11)

* Remove sprites no longer present on a sheet
* Refresh Godot UI after import

### 4.1.0 (2023-08-28)

* Fixed problem when sprite sheet was updated
* Improved error handling
* Removed TileSet importer code

### 4.0.1 (2022-10-13)

* The plugin now works with Godot 4 beta 2

### 4.0.0 (2022-10-04)

* The plugin now works with Godot 4
* The old version working with Godot 3 is now on the godot-3 branch

### 1.0.5 (2020-06-16)

* Fixed syntax to support Godot 3.2.2
* Fixed memory leak (thanks @2shady4u)
* Support additional image formats: webp, pvr, tga (thanks @AntonSalazar)
* Renamed **master** branch to **main**

### 1.0.4 (2018-12-11)

* Fixed syntax to support Godot 3.1

### 1.0.3 (2018-10-05)

* Reduced memory usage during import

### 1.0.2 (2018-04-18)

* Sprite sheets can now be placed in sub folders

### 1.0.1 (2018-03-14)

* Fixed order of import to prevent "No loader found on resources" error

### 1.0.0 (2018-03-12)

* Initial release


## License

[MIT License](LICENSE). Copyright (c) 2018 Andreas Loew / CodeAndWeb GmbH

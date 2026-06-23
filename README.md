# TexturePacker Importer

This is a plugin for [Godot Engine](https://godotengine.org) to import sprite sheets
generated with [TexturePacker](https://www.codeandweb.com/texturepacker) as
Godot `AtlasTexture` resources.

**Note:** This plugin version is compatible with Godot 4.3 and newer.
Use the version from the **godot-3** branch if you are using Godot 3.


## Installation

Download it from the [Godot Asset Store](https://store.godotengine.org/asset/codeandweb/texturepacker-importer).

Alternatively, download or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder.

**Important:** Enable the plugin in Project Settings → Plugins.


## Features

* Imports sprite sheets as native Godot `AtlasTexture` resources
* Supports trimmed sprites (margin)
* Supports MultiPack — multiple atlases per `.tpsheet`
* Supports normal maps — auto-generates a `CanvasTexture` pairing diffuse + normal for 2D dynamic lighting
* Each sheet generates a `<name>.sprites/` folder, one `.tres` per sprite — drag-and-drop ready in the FileSystem dock
* Removes stale sprite resources automatically when sprites disappear from the sheet
* Atlas images go through Godot's standard texture import pipeline, so every compression format Godot supports (ASTC, ETC1/ETC2, DXT1/DXT5, Basis Universal) works out of the box


## Usage (once the plugin is enabled)

1. Create a sprite sheet in TexturePacker
2. Save the image and `.tpsheet` file into your Godot project's asset folder
3. Godot picks them up automatically and imports each sprite as an `AtlasTexture`


## Known issues

- TileSet import is no longer supported: Godot 3 had an API where a tile could be
  retrieved by its name. This is no longer available in Godot 4.


# Release notes

### 4.7.0 (2026-06-23)

* Compatibility with Godot 4.7 import pipeline
* Register sheet images as import dependencies via `append_import_external_resource()`
* Reload imported textures with `CACHE_MODE_REPLACE_DEEP` so fresh imports are picked up
* Added fallback return in `_get_preset_name()` (required by Godot 4.7 parser)
* Guard recursive sprite cleanup against missing directories
* Clarified minimum supported Godot version as 4.3

### 4.3.0 (2025-12-08)

* Support sprites with normal map (use `CanvasTexture` if normal map is present)

### 4.2.0 (2025-06-11)

* Remove sprites no longer present on a sheet
* Refresh Godot UI after import

### 4.1.0 (2023-08-28)

* Fixed problem when sprite sheet was updated
* Improved error handling
* Removed TileSet importer code

## 4.0.1 (2022-10-13)

* The plugin now works with Godot 4 beta 2

## 4.0.0 (2022-10-04)

* The plugin now works with Godot 4
* The old version working with Godot 3 is now on the godot-3 branch

## 1.0.5 (2020-06-16)

* Fixed syntax to support Godot 3.2.2
* Fixed memory leak (thanks @2shady4u)
* Support additional image formats: webp, pvr, tga (thanks @AntonSalazar)
* Renamed **master** branch to **main**

## 1.0.4 (2018-12-11)

* Fixed syntax to support Godot 3.1

## 1.0.3 (2018-10-05)

* Reduced memory usage during import

## 1.0.2 (2018-04-18)

* Sprite sheets can now be placed in sub folders

## 1.0.1 (2018-03-14)

* Fixed order of import to prevent "No loader found on resources" error

## 1.0.0 (2018-03-12)

* Initial release


## License

[MIT License](LICENSE). Copyright (c) 2018 Andreas Loew / CodeAndWeb GmbH

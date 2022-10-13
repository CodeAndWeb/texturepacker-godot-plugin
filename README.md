# TexturePacker Importer

This is a plugin for [Godot Engine](https://godotengine.org) to import
`TileSet`s and `AtlasTexture`s from the [TexturePacker](https://www.codeandweb.com/texturepacker)

**Note: This is compatible with Godot 4.0 beta 2 and newer.**

Use the version from the **godot-3** branch if your are usin g Godot 3.


## Installation

Simply download it from [Godot Asset Library](https://godotengine.org/asset-library/asset/169)

Alternatively, download or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder.

**Important**: Enable the plugin on the Project Settings.

## Features

* Import sprite sheets as AtlasTextures / Sprite sheets
* Supports trimmed sprites (margin)
* Supports MultiPack

## Usage (once the plugin is enabled)

1. Create a sprite sheet in TexturePacker
2. Save the image and .tpsheet file in the godot asset folder
3. Watch Godot import it automatically.


## Known issues

### Currently no TileSet support

The importer does currently not work with TileSets. Godot 3 had an API where a tile could be retrieved by its name. This is no longer supported in Godot 4.

An option might be to create a file containing the name -> ID resolution. With this, it would be possible to update tile coordinates in the atlas.


# Release notes

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

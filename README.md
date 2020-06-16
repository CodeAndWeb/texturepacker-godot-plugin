# TexturePacker Importer

This is a plugin for [Godot Engine](https://godotengine.org) to import
`TileSet`s and `AtlasTexture`s from the [TexturePacker](https://www.codeandweb.com/texturepacker)

**Note: This is compatible only with Godot 3.0 or later.**


## Installation

Simply download it from [Godot Asset Library](https://godotengine.org/asset-library/asset/169)

Alternatively, download or clone this repository and copy the contents of the
`addons` folder to your own project's `addons` folder.

Important: Enable the plugin on the Project Settings.

## Features

* Import sprite sheets as AtlasTextures
* Import sprite sheets as TileSets
* Supports trimmed sprites (margin)
* Supports MultiPack

## Usage (once the plugin is enabled)

1. Save your sprite sheets / tile maps in your project folder
2. Watch Godot import it automatically.


# Release notes

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

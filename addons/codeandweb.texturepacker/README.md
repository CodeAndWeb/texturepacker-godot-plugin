# TexturePacker Importer

This is a plugin for [Godot Engine](https://godotengine.org) to import sprite sheets
generated with [TexturePacker](https://www.codeandweb.com/texturepacker) as
Godot `AtlasTexture` resources.

**Note:** This plugin version is compatible with Godot 4.3 and newer.
Use the version from the **godot-3** branch if you are using Godot 3.

**Requires TexturePacker 8.2.0 or newer** to import animations: that is the first
version whose **Godot SpriteSheet** exporter writes the `animations` block into
the `.tpsheet`. Sprite sheets exported by older versions still import as
`AtlasTexture` resources, they just produce no `AnimationLibrary`.


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
* Generates an `AnimationLibrary` for AnimationPlayer from the animations detected by TexturePacker
* Multi-sprite rigs can be hand-animated from the generated per-sprite resources — see [Animating several sprites in one AnimationPlayer](#animating-several-sprites-in-one-animationplayer)


## Usage (once the plugin is enabled)

1. Create a sprite sheet in TexturePacker
2. Save the image and `.tpsheet` file into your Godot project's asset folder
3. Godot picks them up automatically and imports each sprite as an `AtlasTexture`


## Using the generated animations (AnimationPlayer + Sprite2D)

Enable **Auto-detect animations** in TexturePacker (8.2.0 or newer): sprites whose
file names end in a frame number (e.g. `run-right/RunRight_0001.png` …
`RunRight_0006.png`) are grouped into animation sequences and written to the
.tpsheet. The importer saves one `AnimationLibrary` per sheet to
`<sheet>.animations.tres`, containing one looping animation per sequence
(10 fps), named after the sprite path (`Character-run-right-RunRight` — `/` is
not allowed in Godot animation names). Each animation drives the `atlas`,
`region` and `margin` of a single `AtlasTexture` — trimmed sprites play with
the correct size and offset, without one texture resource per frame, and
multipack sheets work since the atlas is keyframed too.

To use it in your scene:

1. Add a `Sprite2D` and assign it any `AtlasTexture`
   (make it unique — the animation modifies it).
2. Add an `AnimationPlayer` and point its **Root Node** at that `Sprite2D`.
   The tracks are written as `.:texture:region` etc., where `.` means the
   AnimationPlayer's **Root Node** — no node names are baked in, so the same
   library drives any sprite.

   The simplest arrangement is to make the `AnimationPlayer` a **child of the
   Sprite2D**: `root_node` already defaults to `..`, so it works with no
   configuration at all. The AnimationPlayer can live anywhere else in the
   scene as long as `root_node` resolves to the sprite, e.g.

   ```gdscript
   $UI/AnimationPlayer.root_node = $UI/AnimationPlayer.get_path_to($Sprite2D)
   ```
3. In the AnimationPlayer's animation list, choose **Manage Animations… →
   Load Library** and select `<sheet>.animations.tres`. Load it under the
   empty library name (the default) — otherwise animations must be addressed
   as `"libraryname/animation"`.
4. Play any of the generated animations, e.g. from code:
   `$Sprite2D/AnimationPlayer.play("Character-run-right-RunRight")`

Sprites without a trailing frame number are treated as static poses and get no
animation.

### Retiming: the importer owns the frames, you own the timing

Reimporting rebuilds what each frame *shows* — its atlas page, region and margin
— from the sheet. **When** each frame plays is yours. Drag the keys in the
animation editor and they stay where you put them, reimport after reimport,
including non-uniform timing (holding one frame longer than the rest).

Matched by animation name, and kept as long as the frame list is unchanged:
your **key times**, the animation's **length**, its **loop mode**, and the
editor's **step** (the snap grid, which new animations get frame-aligned).

Timing goes back to even spacing at the previous per-frame speed when:

* the frames **change in TexturePacker** — one added, removed, renamed or
  reordered. Timing describes a specific list of frames; once that list changes
  there is nothing to map it onto.
* you **add or delete a key** on a generated track. The region track carries one
  key per frame, and that is what tells the next import your timing still
  describes the frames. To hold a frame longer, drag the *next* key later
  instead of duplicating one.

Each reset prints a warning naming the animation and the reason, so it never
happens silently. It is per animation — the rest of the library keeps its
timing. Renaming a sequence in TexturePacker resets it to the defaults
(10 fps, looping), since settings are matched by name.

Still regenerated, always:

* **Custom tracks** added to a generated animation are discarded.
* **Frame order** comes from the sheet. Dragging a key past its neighbour moves
  the *time*, not the frame — Godot re-sorts the track and the importer re-keys
  the sheet-order frames onto the sorted times.
* The **first key stays at 0**. Dragged later, it would leave the sprite showing
  whatever the previously played animation left behind, so that animation is
  regenerated instead.

**Length is not a speed knob.** Stretching an animation's length adds dead time
at the end; it does not slow playback, in the editor or after a reimport. Retime
by dragging keys, or leave the library alone and change speed at playback:
`play("Character-run-right-RunRight", -1, 1.5)` or `speed_scale`.

**Commit `<sheet>.animations.tres` to version control.** It is no longer pure
build output — it holds the timing you tuned by hand. A project that ignores it
loses every tuning on a fresh checkout. To throw your timing away and start over
from the sheet defaults, delete the file and reimport.


## Using an AnimationTree

The generated library works with `AnimationTree` as well — same library, either
assigned directly or through the `AnimationPlayer` its **Anim Player** property
points at. Use it for state logic (idle → run → jump) rather than for blending:
there is nothing meaningful between frame 3 and frame 4 of a sprite animation.

**Set the tree's Callback Mode Discrete to `Dominant`.** It defaults to
`Force Continuous`, which interpolates discrete tracks while two states are
blending — and since a `Rect2` region *is* interpolatable, a crossfade hands the
Sprite2D a rectangle that crops nothing in particular, e.g.
`[P: (645.75, 736.25), S: (185.25, 220.5)]`, showing a sliver of two frames at
once. `Dominant` lets only the highest-weighted animation write those tracks, so
transitions switch cleanly instead:

```gdscript
$AnimationTree.callback_mode_discrete = AnimationMixer.ANIMATION_CALLBACK_MODE_DISCRETE_DOMINANT
```

## Animating several sprites in one AnimationPlayer

The generated `AnimationLibrary` drives **one** sprite. Its tracks are written as
`.:texture:region`, where `.` is the AnimationPlayer's **Root Node**, and an
AnimationPlayer has only one Root Node. So a character built from several
Sprite2D nodes — body, head, weapon, muzzle flash — cannot be animated from a
single generated animation.

For rigs like that, keyframe the **`texture`** property with the per-sprite
`AtlasTexture` resources the plugin already generates in `<sheet>.sprites/`,
instead of using the generated library:

1. Add an `AnimationPlayer` anywhere above your sprites and set its **Root
   Node** to their common parent.
2. Add a value track per sprite, with the node path of that sprite and the
   property `texture` — e.g. `Body:texture`, `Head:texture`, `Weapon:texture`.
3. Set each track's update mode to **Discrete** (frames should snap, not blend).
4. Drop the `.tres` file for each frame from `<sheet>.sprites/` onto the track
   at the time you want it shown.

This is the same idea as animating the `frame` property of a sprite sheet with
`hframes`/`vframes`, except each key holds a whole `AtlasTexture`. Trimmed
sprites still render correctly, because every `AtlasTexture` carries its own
region and margin.

You get full manual control in exchange: your own frame rate, your own node
paths, several sprites on one timeline, and non-uniform timing (holding a frame
longer than the rest). The cost is one resource reference per key rather than
the shared texture the generated library uses, which is not a concern at
character-rig sizes.


## Known issues

- TileSet import is no longer supported: Godot 3 had an API where a tile could be
  retrieved by its name. This is no longer available in Godot 4.


# Release notes

### 4.8.0 (2026-07-29)

* Generates an `AnimationLibrary` per sheet (`<sheet>.animations.tres`) from
  TexturePacker's auto-detected animations, requires [TexturePacker](https://www.codeandweb.com/texturepacker) 8.2.0 or
  newer. Drives `atlas`, `region` and `margin` of one `AtlasTexture`, so trimmed
  sprites, multipack sheets and reverse playback all work
* Timing set in the Godot editor survives reimports — key times, length, loop
  mode and snap step — as long as the frame list from the sheet is unchanged.
  Otherwise that one animation resets to even spacing at its previous speed and
  warns. The file now holds hand-authored data: commit it, delete it to start
  over, and note the importer never deletes it for you
* Reimports update the library in place, so open scenes pick up sheet changes
  without a reload
* Driving it from an `AnimationTree` needs **Callback Mode Discrete** set to
  `Dominant`, otherwise a crossfade interpolates the region rectangle
* A malformed `.tpsheet` is rejected with one message naming the offending
  element; animations with no frames, or naming sprites absent from the sheet,
  are skipped with a warning and the rest still imports
* Fixed: with normal maps, generated resources embedded duplicate copies of the
  `CanvasTexture` instead of referencing the generated `.tres`
* Verified against Godot 4.3, 4.7.1 and 4.8-dev2

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

* Support sprites with normal map (use `CanvasTexture` if normal map is present)

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

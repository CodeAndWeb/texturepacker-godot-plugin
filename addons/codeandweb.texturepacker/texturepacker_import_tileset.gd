# The MIT License (MIT)
#
# Copyright (c) 2018 Andreas Loew / CodeAndWeb GmbH www.codeandweb.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends EditorImportPlugin

var imageLoader = preload("res://addons/codeandweb.texturepacker/image_loader.gd").new()

enum Preset { PRESET_DEFAULT }

# const TiledMapReader = preload("tiled_map_reader.gd")

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		imageLoader.free()

func _get_importer_name():
	return "codeandweb.texturepacker_import_tileset"


func _get_visible_name():
	return "TileSet from TexturePacker"


func _get_recognized_extensions():
	return ["tpset"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Preset.size()


func get_preset_name(preset):
	match preset:
		Preset.PRESET_DEFAULT: return "Default"


func _get_import_options(path, preset_index):
	return []


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 200

func _get_priority():
	return 1.0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):

	print("Importing tile set from "+source_file)

	var sheets = read_sprite_sheet(source_file)
	var sheetFolder = source_file.get_basename()+".sprites";
	create_folder(sheetFolder)

	var fileName = "%s.%s" % [source_file.get_basename(), "res"]

	var tileSet
	if FileAccess.file_exists(fileName):
		tileSet = ResourceLoader.load(fileName, "TileSet")
	else:
		tileSet = TileSet.new()

	var usedIds = []
	for sheet in sheets.textures:
		var sheetFile = source_file.get_base_dir()+"/"+sheet.image
		var image = load_image(sheetFile, "ImageTexture", [])
		r_gen_files.push_back(sheet.image)
		create_tiles(tileSet, sheet, image, usedIds)
	
	prune_tileset(tileSet, usedIds)	

	r_gen_files.push_back(fileName)
	ResourceSaver.save(tileSet, fileName)

	return ResourceSaver.save(Resource.new(), "%s.%s" % [save_path, _get_save_extension()])

func prune_tileset(tileSet, usedIds):
	usedIds.sort()
	for id in tileSet.get_tiles_ids():
		if !usedIds.has(id):
			tileSet.remove_tile(id)


func create_folder(folder):
	var dir := DirAccess.open("res://")
	if !dir.dir_exists(folder):
		if dir.make_dir_recursive(folder) != OK:
			printerr("Failed to create folder: " + folder)


func create_tiles(tileSet, sheet, image, r_usedIds):
	for sprite in sheet.sprites:
		r_usedIds.push_back(create_tile(tileSet, sprite, image))


func create_tile(tileSet, sprite, image):
	var tileName = sprite.filename.get_basename()
	
	var id = tileSet.find_tile_by_name(tileName)
	if id==-1:
		id = tileSet.get_last_unused_tile_id()
		tileSet.create_tile(id)
		tileSet.tile_set_name(id, tileName)

	tileSet.tile_set_texture(id, image)
	tileSet.tile_set_region(id, Rect2(sprite.region.x,sprite.region.y,sprite.region.w,sprite.region.h))
	tileSet.tile_set_texture_offset(id, Vector2(sprite.margin.x, sprite.margin.y))
	return id


func save_resource(name, texture):
	create_folder(name.get_base_dir())
	
	var status = ResourceSaver.save(texture, name)
	if status != OK:
		printerr("Failed to save resource "+name)
		return false
	return true


func read_sprite_sheet(fileName):
	var file = FileAccess.open(fileName, FileAccess.READ)
	if not file:
		printerr("Failed to load "+fileName)
	var text = file.get_as_text()
	var dict = JSON.parse_string(text)
	if dict == null:
		printerr("Invalid json data in "+fileName)
	return dict


func load_image(rel_path, source_path, options):
	return imageLoader.load_image(rel_path, source_path, options)
	

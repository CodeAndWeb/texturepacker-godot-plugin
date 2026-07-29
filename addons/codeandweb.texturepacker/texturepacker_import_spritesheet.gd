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


enum Preset { PRESET_DEFAULT }

const ANIMATION_LIBRARY_SUFFIX := ".animations.tres"
const AnimationLibraryBuilder := preload("animation_library_builder.gd")
const SpriteSheetValidator := preload("sprite_sheet_validator.gd")


func _get_importer_name():
	return "codeandweb.texturepacker_import_spritesheet"


func _get_visible_name():
	return "SpriteSheet from TexturePacker"


func _get_recognized_extensions():
	return ["tpsheet"]


func _get_save_extension():
	return "res"


func _get_resource_type():
	return "Resource"


func _get_preset_count():
	return Preset.size()


func _get_preset_name(preset):
	match preset:
		Preset.PRESET_DEFAULT: return "Default"
	return ""


func _get_import_options(path, preset_index):
	return []


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 200

func _get_priority():
	return 1.0

func _import(source_file, save_path, options, r_platform_variants, r_gen_files):
	print("Importing sprite sheet from "+source_file);
	
	var sheets = read_sprite_sheet(source_file)
	if not sheets:
		return ERR_PARSE_ERROR

	var sheetFolder = source_file.get_basename()+".sprites"
	create_folder(sheetFolder)

	var spriteFrames = {}
	for sheet in sheets.textures:
		var sheetFile = source_file.get_base_dir()+"/"+sheet.image
		var image = load_imported_texture(sheetFile)
		if not image:
			printerr("Failed to load image file: " + sheetFile)
			return ERR_FILE_NOT_FOUND

		if sheet.has("normalMap"):
			var normalFile = source_file.get_base_dir()+"/"+sheet.normalMap
			var normalImage = load_imported_texture(normalFile)
			if not normalImage:
				printerr("Failed to load normal map file: " + normalFile)
				return ERR_FILE_NOT_FOUND

			image = create_canvas_texture(sheetFolder, sheet, image, normalImage, r_gen_files)
			if not image:
				return ERR_CANT_CREATE

		create_atlas_textures(sheetFolder, sheet, image, r_gen_files)
		register_sprite_frames(spriteFrames, sheet, image)

	if not create_animation_library(source_file.get_basename() + ANIMATION_LIBRARY_SUFFIX,
			sheets.get("animations", []), spriteFrames, r_gen_files):
		return ERR_CANT_CREATE

	delete_no_longer_existing_sprite_files(sheetFolder, r_gen_files)
	
	EditorInterface.get_resource_filesystem().scan_sources();

	return ResourceSaver.save(Resource.new(), "%s.%s" % [save_path, _get_save_extension()])


func load_imported_texture(path: String):
	var err = append_import_external_resource(path)
	if err != OK and err != ERR_FILE_ALREADY_IN_USE:
		printerr("Failed to import texture file: " + path)
		return null

	return ResourceLoader.load(path, "ImageTexture", ResourceLoader.CACHE_MODE_REPLACE_DEEP)


func create_folder(folder):
	var dir := DirAccess.open("res://")
	if !dir.dir_exists(folder):
		if dir.make_dir_recursive(folder) != OK:
			printerr("Failed to create folder: " + folder)


func create_canvas_texture(sheetFolder, sheet, diffuseTex, normalTex, r_gen_files):
	var canvasTex = CanvasTexture.new()
	canvasTex.diffuse_texture = diffuseTex
	canvasTex.normal_texture = normalTex
	var canvasTexFolder = sheetFolder+"/CanvasTexture"
	var canvasTexResource = canvasTexFolder+"/"+sheet.image.get_basename()+".tres"
	if not save_resource(canvasTexResource, canvasTex):
		return null
	canvasTex.take_over_path(canvasTexResource)
	r_gen_files.push_back(canvasTexResource)
	return canvasTex


func create_atlas_textures(sheetFolder, sheet, image, r_gen_files):
	for sprite in sheet.sprites:
		if !create_atlas_texture(sheetFolder, sprite, image, r_gen_files):
			return false
	return true


func create_atlas_texture(sheetFolder, sprite, image, r_gen_files):
	var name = sheetFolder+"/"+sprite.filename.get_basename()+".tres"
	var texture
	if ResourceLoader.exists(name, "AtlasTexture"):
		texture = ResourceLoader.load(name, "AtlasTexture", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	else:
		texture = AtlasTexture.new()

	texture.atlas = image
	texture.region = region_rect(sprite)
	texture.margin = margin_rect(sprite)
	r_gen_files.push_back(name)
	return save_resource(name, texture)


func register_sprite_frames(spriteFrames, sheet, image):
	for sprite in sheet.sprites:
		spriteFrames[sprite.filename] = {
			"texture": image,
			"region": region_rect(sprite),
			"margin": margin_rect(sprite)
		}


func region_rect(sprite):
	return Rect2(sprite.region.x, sprite.region.y, sprite.region.w, sprite.region.h)


func margin_rect(sprite):
	return Rect2(sprite.margin.x, sprite.margin.y, sprite.margin.w, sprite.margin.h)


func create_animation_library(libraryFile, animations, spriteFrames, r_gen_files):
	var importable = importable_animations(animations, spriteFrames)
	if importable.is_empty():
		return true

	if not AnimationLibraryBuilder.new().build(libraryFile, importable, spriteFrames):
		return false
	r_gen_files.push_back(libraryFile)
	return true


func importable_animations(animations, spriteFrames):
	var result = []
	for animation in animations:
		var missing = animation.frames.filter(func(frameName): return not spriteFrames.has(frameName))
		if missing.is_empty():
			result.append(animation)
		else:
			printerr("Skipping animation \"%s\": no sprite named \"%s\" in this sheet" % [animation.name, missing[0]])
	return result


func save_resource(name, resource):
	create_folder(name.get_base_dir())

	var status = ResourceSaver.save(resource, name)
	if status != OK:
		printerr("Failed to save resource "+name)
		return false
	return true


func read_sprite_sheet(fileName):
	var file = FileAccess.open(fileName, FileAccess.READ)
	if not file:
		printerr("Failed to load "+fileName)
		return null

	var text = file.get_as_text()
	file.close()

	var sheet = JSON.parse_string(text)
	if sheet == null:
		printerr("Invalid json data in "+fileName)
		return null

	var validator = SpriteSheetValidator.new()
	var formatError = validator.format_error(sheet)
	if formatError != "":
		printerr("%s: %s. %s" % [fileName, formatError, validator.exporter_hint(sheet)])
		return null

	return sheet


func get_all_tres_files_recursive(folder_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(folder_path)
	if dir == null:
		return result

	var files = dir.get_files()
	for file_name in files:
		if file_name.ends_with(".tres"):
			result.append(folder_path + "/" + file_name)

	var subdirs = dir.get_directories()
	for subdir_name in subdirs:
		var subdir_path = folder_path + "/" + subdir_name
		result.append_array(get_all_tres_files_recursive(subdir_path))

	return result


func delete_no_longer_existing_sprite_files(sheetFolder: String, generated_files: PackedStringArray) -> void:
	var generated_set := {}
	for path in generated_files:
		generated_set[path] = true

	var dir := DirAccess.open(sheetFolder)
	if dir == null:
		printerr("Failed to open directory for deletion: " + sheetFolder)
		return

	var existing_files = get_all_tres_files_recursive(sheetFolder)
	for file_path in existing_files:
		if not generated_set.has(file_path):
			var err = dir.remove(file_path)
			if err != OK:
				printerr("Failed to delete obsolete sprite: " + file_path)
			else:
				print("Deleted obsolete sprite: " + file_path)

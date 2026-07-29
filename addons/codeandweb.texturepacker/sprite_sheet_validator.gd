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


extends RefCounted

const PRODUCT_URL := "https://www.codeandweb.com/texturepacker"
const EXPORTER_NAME := "Godot SpriteSheet"
const MINIMUM_TEXTUREPACKER_VERSION := "8.2.0"


func format_error(sheet):
	if not sheet is Dictionary:
		return "is not a JSON object"
	if not sheet.get("textures") is Array:
		return "missing top-level \"textures\" array"
	for textureIndex in sheet.textures.size():
		var textureError = texture_format_error(sheet.textures[textureIndex])
		if textureError != "":
			return "textures[%d] %s" % [textureIndex, textureError]
	return animations_format_error(sheet)


func texture_format_error(texture):
	if not texture is Dictionary:
		return "is not a JSON object"
	if not texture.get("image") is String:
		return "is missing the \"image\" file name"
	if texture.has("normalMap") and not texture.normalMap is String:
		return "has an invalid \"normalMap\" file name"
	if not texture.get("sprites") is Array:
		return "is missing the \"sprites\" array"
	for spriteIndex in texture.sprites.size():
		var spriteError = sprite_format_error(texture.sprites[spriteIndex])
		if spriteError != "":
			return "sprites[%d] %s" % [spriteIndex, spriteError]
	return ""


func sprite_format_error(sprite):
	if not sprite is Dictionary:
		return "is not a JSON object"
	if not sprite.get("filename") is String:
		return "is missing the \"filename\" key"
	for rectKey in ["region", "margin"]:
		var rectError = rect_format_error(sprite.get(rectKey))
		if rectError != "":
			return "\"%s\" %s" % [rectKey, rectError]
	return ""


func rect_format_error(rect):
	if not rect is Dictionary:
		return "is not a rectangle object"
	for key in ["x", "y", "w", "h"]:
		if not (rect.get(key) is float or rect.get(key) is int):
			return "is missing a numeric \"%s\"" % key
	return ""


func animations_format_error(sheet):
	if not sheet.has("animations"):
		return ""
	if not sheet.animations is Array:
		return "\"animations\" must be an array"
	for animationIndex in sheet.animations.size():
		var animationError = animation_format_error(sheet.animations[animationIndex])
		if animationError != "":
			return "animations[%d] %s" % [animationIndex, animationError]
	return ""


func animation_format_error(animation):
	if not animation is Dictionary:
		return "is not a JSON object"
	if not animation.get("name") is String:
		return "is missing the \"name\" key"
	if not animation.get("frames") is Array:
		return "is missing the \"frames\" array"
	return ""


func exporter_hint(sheet):
	var writtenBy = written_by(sheet)
	var reExport = "Re-export it with the \"%s\" exporter of TexturePacker %s or newer (%s)." % [
		EXPORTER_NAME, MINIMUM_TEXTUREPACKER_VERSION, PRODUCT_URL]
	if writtenBy != "":
		return "The file reports it was written by %s. %s" % [writtenBy, reExport]
	return "The file does not look like it was written by TexturePacker. %s" % reExport


func written_by(sheet):
	if sheet is Dictionary and sheet.get("meta") is Dictionary and sheet.meta.get("app") is String:
		return sheet.meta.app
	return ""

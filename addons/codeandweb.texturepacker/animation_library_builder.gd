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

const ANIMATION_FPS := 10
const ANIMATION_FRAME_DURATION := 1.0 / ANIMATION_FPS

const ATLAS_TRACK := ".:texture:atlas"
const REGION_TRACK := ".:texture:region"
const MARGIN_TRACK := ".:texture:margin"

const FRAME_COUNT_META := "texturepacker_frame_count"

const FRAMES_META := "texturepacker_frames"

const MINIMUM_KEY_DISTANCE := 1e-5


func build(libraryFile, animations, spriteFrames) -> bool:
	var library = load_existing_library(libraryFile)
	var usable = animations_with_frames(animations)
	remove_deleted_animations(library, usable)
	for animation in usable:
		var frames = animation.frames.map(func(frameName): return spriteFrames[frameName])
		var timing = timing_for(library, animation.name, animation.frames)
		library.add_animation(animation.name, create_animation(frames, animation.frames, timing))

	if ResourceSaver.save(library, libraryFile) != OK:
		printerr("Failed to save resource " + libraryFile)
		return false
	library.take_over_path(libraryFile)
	return true


func load_existing_library(libraryFile):
	if ResourceLoader.exists(libraryFile, "AnimationLibrary"):
		var library = ResourceLoader.load(libraryFile, "AnimationLibrary", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
		if library is AnimationLibrary:
			return library
	return AnimationLibrary.new()


func animations_with_frames(animations):
	var usable = []
	for animation in animations:
		if animation.frames.is_empty():
			push_warning("TexturePacker: skipping animation \"%s\" — it has no frames." % animation.name)
		else:
			usable.append(animation)
	return usable


func remove_deleted_animations(library, animations):
	var currentNames = animations.map(func(animation): return animation.name)
	for existingName in library.get_animation_list():
		if not currentNames.has(String(existingName)):
			library.remove_animation(existingName)


func timing_for(library, animationName, frameNames):
	if not library.has_animation(animationName):
		return even_timing(Animation.LOOP_LINEAR, frameNames.size(), ANIMATION_FRAME_DURATION)

	var previous = library.get_animation(animationName)
	if not previous.has_meta(FRAMES_META):
		return regenerated_timing(previous, animationName, frameNames, "")
	if Array(previous.get_meta(FRAMES_META)) != Array(frameNames):
		return regenerated_timing(previous, animationName, frameNames,
			"the frames changed in TexturePacker")

	var times = reusable_times(previous, frameNames.size())
	if times == null:
		return regenerated_timing(previous, animationName, frameNames,
			"a key was added to or removed from a generated track")

	return {
		"loop_mode": previous.loop_mode,
		"step": previous.step,
		"length": previous.length,
		"times": times,
	}


func reusable_times(previous, frameCount):
	var track = previous.find_track(REGION_TRACK, Animation.TYPE_VALUE)
	if track == -1 or previous.track_get_key_count(track) != frameCount:
		return null

	var times = []
	for index in frameCount:
		times.append(previous.track_get_key_time(track, index))
	return times if usable_times(times) else null


func usable_times(times) -> bool:
	if times[0] != 0.0:
		return false

	var previousTime := -INF
	for time in times:
		if not is_finite(time) or time < 0.0:
			return false
		if time - previousTime <= MINIMUM_KEY_DISTANCE:
			return false
		previousTime = time
	return true


func regenerated_timing(previous, animationName, frameNames, reason):
	var frameDuration = ANIMATION_FRAME_DURATION
	var previousFrameCount = frame_count_of(previous)
	if previousFrameCount > 0:
		frameDuration = previous.length / previousFrameCount

	if reason != "":
		push_warning("TexturePacker: custom key timing for \"%s\" was reset to %.3fs per frame — %s." \
			% [animationName, frameDuration, reason])
	return even_timing(previous.loop_mode, frameNames.size(), frameDuration)


func even_timing(loopMode, frameCount, frameDuration):
	var times = []
	for index in frameCount:
		times.append(index * frameDuration)
	return {
		"loop_mode": loopMode,
		"step": frameDuration,
		"length": frameCount * frameDuration,
		"times": times,
	}


func frame_count_of(animation) -> int:
	if animation.has_meta(FRAME_COUNT_META):
		return int(animation.get_meta(FRAME_COUNT_META))

	var regionTrack = animation.find_track(REGION_TRACK, Animation.TYPE_VALUE)
	if regionTrack == -1:
		return 0
	return animation.track_get_key_count(regionTrack)


func create_animation(frames, frameNames, timing):
	var animation = Animation.new()
	animation.loop_mode = timing.loop_mode
	animation.step = timing.step
	animation.length = timing.length
	animation.set_meta(FRAME_COUNT_META, frames.size())
	animation.set_meta(FRAMES_META, PackedStringArray(frameNames))
	add_animation_track(animation, ATLAS_TRACK, keys_at_run_boundaries(frames.map(func(frame): return frame.texture)), timing.times)
	add_animation_track(animation, REGION_TRACK, keys_per_frame(frames.map(func(frame): return frame.region)), timing.times)
	add_animation_track(animation, MARGIN_TRACK, keys_at_run_boundaries(frames.map(func(frame): return frame.margin)), timing.times)
	return animation


func keys_per_frame(values):
	var keys = []
	for index in values.size():
		keys.append({"index": index, "value": values[index]})
	return keys


func keys_at_run_boundaries(values):
	var keys = []
	for index in values.size():
		var startsRun = index == 0 or values[index] != values[index - 1]
		var endsRun = index == values.size() - 1 or values[index] != values[index + 1]
		if startsRun or endsRun:
			keys.append({"index": index, "value": values[index]})
	return keys


func add_animation_track(animation, trackPath, keys, times):
	var track = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, trackPath)
	animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	for key in keys:
		animation.track_insert_key(track, times[key.index], key.value)

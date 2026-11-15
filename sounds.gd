class_name Sounds
extends RefCounted
## Audio catalog (static data only), same idea as Buildings.DATA.
##
## Always refer to a sound by its constant (Sounds.CLICK), never by a raw string.
## Each entry: "path" (file) and "volume_db" (0 = original volume, negative = quieter).
##
## To add a sound: add a constant, an entry in DATA, and call
## AudioManager.play_sfx(Sounds.YOUR_SOUND) wherever it should play.
##
## Files are loaded at runtime (not preload), so a wrong path or a missing file
## only prints ONE warning and the sound is skipped; the game keeps running.

const CLICK := "click"
const PLACE := "place"
const CONSTRUCTION_LOOP := "construction_loop"
const MUSIC_MAIN := "music_main"

const DATA := {
	CLICK: {"path": "res://sounds and music/click_sf.mp3", "volume_db": -6.0},
	PLACE: {"path": "res://sounds and music/placing_oXGypbso.mp3", "volume_db": 20.0},
	CONSTRUCTION_LOOP: {"path": "res://audio/sfx/construction_loop.ogg", "volume_db": -8.0},
	MUSIC_MAIN: {"path": "res://sounds and music/main_theme.mp3", "volume_db": -12.0},
}

## Ids already warned about, so a missing file does not spam the console.
static var _warned := {}


## Returns the stream of `id`, or null if the id or the file does not exist.
static func get_stream(id: String) -> AudioStream:
	var path: String = DATA.get(id, {}).get("path", "")
	if path == "" or not ResourceLoader.exists(path):
		if not _warned.has(id):
			_warned[id] = true
			push_warning("Sound '%s' not found (path: '%s')" % [id, path])
		return null
	return load(path) as AudioStream


static func volume_db(id: String) -> float:
	return DATA.get(id, {}).get("volume_db", 0.0)

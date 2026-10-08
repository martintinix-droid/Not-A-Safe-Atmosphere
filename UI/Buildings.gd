class_name Buildings
extends Node
## Catalog of the buildings the player can construct (static data only).
##
## Each key is a building id. It is what the UI sends in
## SignalManager.spawn_building and what ui.gd uses to map buttons to buildings.
##
## Entry format:
##   "scene":      PackedScene of the building. Its root script must expose a
##                 `build_time` variable and a `state_changed` signal
##                 (see generator.gd); main.gd relies on both.
##   "materials":  Cost, as {Inventory resource id: amount}.
##   "build_time": Construction time in seconds (starts when a rover arrives).
##
## To add a building: add an entry here, plus a button and an entry in
## ui.gd (_building_buttons).

const DATA := {
	"energy": {
		"scene": preload("uid://b7ux8e48tnrv3"),
		"materials": {"mineral 1": 3, "mineral 2": 4, "rock 1": 2},
		"build_time": 6.0,
	},
	"water": {
		"scene": preload("uid://cv1m1r8gxkird"),
		"materials": {"mineral 1": 3, "mineral 2": 4, "rock 1": 2},
		"build_time": 6.0,
	},
}

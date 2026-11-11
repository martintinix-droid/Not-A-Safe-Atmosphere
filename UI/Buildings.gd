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

##build_time for the thingies
##E:8, W:10, B:5, R:20
const DATA := {
	"energy": {
		"scene": preload("uid://b7ux8e48tnrv3"),
		"materials": {"Basalt rock": 10, "Regolith": 2, "rock 1": 2},
		"build_time": 1.0,
	},
	"water": {
		"scene": preload("uid://cv1m1r8gxkird"),
		"materials": {"Basalt rock": 15, "Regolith": 10, "rock 1": 4},
		"build_time": 1.0,
	},
	"Basalt Rock": {
		"scene": preload("uid://di17c2btd7sur"),
		"materials": {"energy": 10, "water": 10, "Basalt Rock": 15},
		"build_time": 1.0,
	},
	"Regolith": {
		"scene": preload("uid://cpwyv4m8w6jd0"),
		"materials": {"energy": 15, "water": 15, "rock 1": 20, "Regolith": 5},
		"build_time": 1.0,
	},
	
}

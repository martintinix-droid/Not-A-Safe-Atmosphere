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

## Costs and build times come from the balance model (target: 10-15 min per game).
## Rock 1 only comes from rocks on the map, so its costs are what limits expansion.
const DATA := {
	"energy": {
		"scene": preload("uid://b7ux8e48tnrv3"),
		"materials": {Resources.BASALT_ROCK: 6, Resources.REGOLITH: 2, Resources.ROCK_1: 2},
		"build_time": 8.0,
	},
	"water": {
		"scene": preload("uid://cv1m1r8gxkird"),
		"materials": {Resources.BASALT_ROCK: 8, Resources.REGOLITH: 4, Resources.ROCK_1: 2},
		"build_time": 15.0,
	},
	"Basalt Rock": {
		"scene": preload("uid://di17c2btd7sur"),
		"materials": {Resources.ENERGY: 10, Resources.WATER: 10, Resources.BASALT_ROCK: 8, Resources.ROCK_1: 2},
		"build_time": 5.0,
	},
	"Regolith": {
		"scene": preload("uid://cpwyv4m8w6jd0"),
		"materials": {Resources.ENERGY: 12, Resources.WATER: 12, Resources.BASALT_ROCK: 10, Resources.REGOLITH: 3, Resources.ROCK_1: 2},
		"build_time": 10.0,
	},
	"Research Lab": {
		"scene": preload("uid://cabh0jrbk6l7u"),
		"materials": {Resources.ENERGY: 40, Resources.WATER: 40, Resources.BASALT_ROCK: 25, Resources.REGOLITH: 10, Resources.ROCK_1: 4},
		"build_time": 10.0,
	},
	"Iron_Ore": {
		##Revisit to make it logical in game
		"scene": preload("uid://dkq6dc5387vd"),
		"materials": {Resources.ENERGY: 12, Resources.WATER: 12, Resources.BASALT_ROCK: 12, Resources.ROCK_1: 2},
		"build_time": 7.5,
	},
	"Ice": {
		##PlaceHolder Image
		"scene": preload("uid://bbsnx2ivayv5r"),
		"materials": {Resources.ENERGY: 15, Resources.WATER: 15, Resources.BASALT_ROCK: 15, Resources.REGOLITH: 5, Resources.ROCK_1: 2},
		"build_time": 15.0,
	},
	"Titanium": {
		##PlaceHolder Image
		"scene": preload("uid://cjgnr4alsge2n"),
		"materials": {Resources.ENERGY: 20, Resources.WATER: 20, Resources.BASALT_ROCK: 20, Resources.REGOLITH: 8, Resources.ROCK_1: 3},
		"build_time": 10.0,
	},
	"Aluminum": {
		##PlaceHolder Image
		"scene": preload("uid://cw3vfrpecpoib"),
		"materials": {Resources.ENERGY: 20, Resources.WATER: 20, Resources.BASALT_ROCK: 20, Resources.REGOLITH: 8, Resources.ROCK_1: 3},
		"build_time": 10.0,
	},
}

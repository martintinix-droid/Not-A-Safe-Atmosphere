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
##
## BALANCE (tools/balance_sim.py reads this file): target 10-15 min per game.
## Tech chain, every resource ends up in the Research Lab recipe:
##   Basalt + Regolith (map rocks, then miners) -> Iron -> Ice -> Titanium / Aluminum
##   -> Nickel (Iron + Titanium) / Sulfur (Ice + Aluminum)
##   -> Gypsum (Ice + Nickel) -> Soluble Salts (Sulfur + Gypsum) -> Research Lab

const DATA := {
	"energy": {
		"scene": preload("uid://b7ux8e48tnrv3"),
		"materials": {Resources.BASALT_ROCK: 8, Resources.REGOLITH: 3},
		"build_time": 8.0,
	},
	"water": {
		"scene": preload("uid://cv1m1r8gxkird"),
		"materials": {Resources.BASALT_ROCK: 8, Resources.REGOLITH: 3},
		"build_time": 10.0,
	},
	"Basalt Rock": {
		"scene": preload("uid://di17c2btd7sur"),
		"materials": {Resources.ENERGY: 10, Resources.WATER: 10, Resources.BASALT_ROCK: 8},
		"build_time": 6.0,
	},
	"Regolith": {
		"scene": preload("uid://cpwyv4m8w6jd0"),
		"materials": {Resources.ENERGY: 12, Resources.WATER: 12, Resources.BASALT_ROCK: 10, Resources.REGOLITH: 2},
		"build_time": 8.0,
	},
	"Iron_Ore": {
		"scene": preload("uid://dkq6dc5387vd"),
		"materials": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 45, Resources.REGOLITH: 15},
		"build_time": 10.0,
	},
	"Ice": {
		"scene": preload("uid://bbsnx2ivayv5r"),
		"materials": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 50, Resources.REGOLITH: 20, Resources.IRON_ORE: 25},
		"build_time": 12.0,
	},
	"Titanium": {
		"scene": preload("uid://cjgnr4alsge2n"),
		"materials": {Resources.ENERGY: 45, Resources.WATER: 45, Resources.BASALT_ROCK: 70, Resources.REGOLITH: 30, Resources.IRON_ORE: 40, Resources.ICE: 25},
		"build_time": 12.0,
	},
	"Aluminum": {
		"scene": preload("uid://cw3vfrpecpoib"),
		"materials": {Resources.ENERGY: 45, Resources.WATER: 45, Resources.BASALT_ROCK: 70, Resources.REGOLITH: 30, Resources.IRON_ORE: 40, Resources.ICE: 25},
		"build_time": 12.0,
	},
	"Nickel": {
		"scene": preload("uid://c7c3j0mr7mt4e"),
		"materials": {Resources.ENERGY: 55, Resources.WATER: 55, Resources.BASALT_ROCK: 90, Resources.REGOLITH: 40, Resources.IRON_ORE: 50, Resources.TITANIUM: 35},
		"build_time": 14.0,
	},
	"Sulfur": {
		"scene": preload("uid://5qoyxyo6xm4q"),
		"materials": {Resources.ENERGY: 55, Resources.WATER: 55, Resources.BASALT_ROCK: 90, Resources.REGOLITH: 40, Resources.ICE: 40, Resources.ALUMINUM: 35},
		"build_time": 14.0,
	},
	"Gypsum": {
		"scene": preload("uid://b683kq5pykl37"),
		"materials": {Resources.ENERGY: 65, Resources.WATER: 65, Resources.BASALT_ROCK: 110, Resources.REGOLITH: 50, Resources.ICE: 50, Resources.NICKEL: 30},
		"build_time": 14.0,
	},
	"Soluble Salts": {
		"scene": preload("uid://de1va0voehns5"),
		"materials": {Resources.ENERGY: 65, Resources.WATER: 65, Resources.BASALT_ROCK: 110, Resources.REGOLITH: 50, Resources.SULFUR: 30, Resources.GYPSUM: 30},
		"build_time": 14.0,
	},
	"Research Lab": {
		"scene": preload("uid://cabh0jrbk6l7u"),
		"materials": {Resources.ENERGY: 400, Resources.WATER: 400, Resources.BASALT_ROCK: 500, Resources.REGOLITH: 250, Resources.IRON_ORE: 150, Resources.ICE: 100, Resources.TITANIUM: 80, Resources.ALUMINUM: 80, Resources.NICKEL: 60, Resources.SULFUR: 45, Resources.GYPSUM: 45, Resources.SOLUBLE_SALTS: 35},
		"build_time": 12.0,
	},
}

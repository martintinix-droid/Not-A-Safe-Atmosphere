class_name Resources
extends RefCounted
## Resource directory: the single place that defines every resource in the game.
## To add a resource: add a constant, add an entry in DATA.

const ENERGY := "energy"
const WATER := "water"
const BASALT_ROCK := "Basalt Rock"
const REGOLITH := "Regolith"
const ROCK_1 := "rock 1"

const PLACEHOLDER_DIR := "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/"

## id -> { "name": UI text, "icon": texture path, "start": starting amount }
const DATA := {
	ENERGY: {"name": "Energy", "icon": PLACEHOLDER_DIR + "thunder.jpg", "start": 100},
	WATER: {"name": "Water", "icon": PLACEHOLDER_DIR + "water.png", "start": 100},
	BASALT_ROCK: {"name": "Basalt Rock", "icon": PLACEHOLDER_DIR + "mineral1.jpg", "start": 10000},
	REGOLITH: {"name": "Regolith", "icon": PLACEHOLDER_DIR + "mineral2.jpg", "start": 10000},
	ROCK_1: {"name": "Rock 1", "icon": PLACEHOLDER_DIR + "rock1.jpg", "start": 10000},
}

static func ids() -> Array:
	return DATA.keys()

static func exists(id: String) -> bool:
	return DATA.has(id)

static func display_name(id: String) -> String:
	if not DATA.has(id):
		return id
	return DATA[id]["name"]

static func icon_path(id: String) -> String:
	if not DATA.has(id):
		return ""
	return DATA[id]["icon"]

static func load_icon(id: String) -> Texture2D:
	var path := icon_path(id)
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func starting_amount(id: String) -> int:
	if not DATA.has(id):
		return 0
	return DATA[id]["start"]

static func starting_stock() -> Dictionary:
	var stock := {}
	for id in DATA:
		stock[id] = DATA[id]["start"]
	return stock

## Ids in `cost` that are not defined resources (catches typos).
static func unknown_ids(cost: Dictionary) -> Array:
	var bad := []
	for id in cost:
		if not DATA.has(id):
			bad.append(id)
	return bad

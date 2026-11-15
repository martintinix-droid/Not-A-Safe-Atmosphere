class_name Resources
extends RefCounted
## Resource directory: the single place that defines every resource in the game.
## To add a resource: add a constant, add an entry in DATA.

const ENERGY := "energy"
const WATER := "water"
const BASALT_ROCK := "Basalt Rock"
const REGOLITH := "Regolith"
const ROCK_1 := "rock 1"
const IRON_ORE := "Iron Ore"
const ICE := "Ice"
const SILICA := "Silica"
const TITANIUM := "Titanium"
const ALUMINUM := "Aluminum"
const COPPER := "Copper"
const NICKEL := "Nickel"
const SULFUR := "Sulfur"
const GYPSUM := "Gypsum"
const SOLUBLE_SALTS := "Soluble Salts"

const PLACEHOLDER_DIR := "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/"
const SPRITES_DIR := "res://Resources Sprites/"
## id -> { "name": UI text, "icon": texture path, "start": starting amount }
const DATA := {
	ENERGY: {"name": "Energy", "icon": PLACEHOLDER_DIR + "thunder.jpg", "start": 100},
	WATER: {"name": "Water", "icon": PLACEHOLDER_DIR + "water.png", "start": 100},
	BASALT_ROCK: {"name": "Basalt Rock", "icon": SPRITES_DIR + "basalt.png", "start": 0},
	REGOLITH: {"name": "Regolith", "icon": SPRITES_DIR + "regolith.png", "start": 0},
	ROCK_1: {"name": "Rock 1", "icon": PLACEHOLDER_DIR + "rock1.jpg", "start": 0},
	# New resources: they start at 0 and need a generator/event to produce them.
	IRON_ORE: {"name": "Iron Ore", "icon": PLACEHOLDER_DIR + "iron_ore.png", "start": 0},
	ICE: {"name": "Ice", "icon": SPRITES_DIR + "Martian_ice.png", "start": 0},
	# Volcanic and hydrothermal minerals.
	TITANIUM: {"name": "Titanium", "icon": PLACEHOLDER_DIR + "titanium.png", "start": 0},
	ALUMINUM: {"name": "Aluminum", "icon": PLACEHOLDER_DIR + "aluminum.png", "start": 0},
	NICKEL: {"name": "Nickel", "icon": PLACEHOLDER_DIR + "nickel.png", "start": 0},
	SULFUR: {"name": "Sulfur", "icon": SPRITES_DIR + "sulfur.png", "start": 0},
	GYPSUM: {"name": "Gypsum", "icon": PLACEHOLDER_DIR + "gypsum.png", "start": 0},
	SOLUBLE_SALTS: {"name": "Soluble Salts", "icon": SPRITES_DIR + "Soluble_Salts.png", "start": 0},
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

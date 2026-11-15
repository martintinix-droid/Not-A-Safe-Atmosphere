class_name UpgradesInfo
extends RefCounted
## Upgrade catalog (static data only), same idea as Buildings.DATA.
##
## Key = building id (key of Buildings.DATA) or "base".
## "levels"[i] is what you get by going from level i+1 to level i+2:
##   "cost":  {resource id: amount}, paid with Inventory.spend().
##            Resource ids are ALWAYS Resources.* constants, never raw strings.
##   "stats": {stat name: NEW absolute value}. Stats not listed keep their value.
## Level 1 values come from the node itself (generator.gd: its exported output /
## energy_used / water_consumed; base.gd: max_rovers, multiplier).
## Max level = levels.size() + 1.
##
## To make something upgradable: add an entry here and give the node an
## `upgrade: UpgradeState` and an upgrade_requested emit (see generator.gd).
##
## BALANCE: level 1 values the scenes must use (tools/balance_sim.py assumes them):
##   energy gen 4/tick, water gen 4/tick (no upkeep), Basalt miner 2/tick (1 Energy + 1 Water),
##   Regolith miner 1/tick (1 Energy + 1 Water), every other miner 1/tick (1 Energy + 1 Water),
##   production Timer = 1.0 s everywhere. An upgrade costs about two fresh miners, but needs no
##   rover trip, so it is the better buy once rovers are the bottleneck. The base upgrades are the
##   big mid-game goal: +1 rover and faster construction each.

const STAT_NAMES := {
	"output": "Production",
	"energy_used": "Energy use",
	"water_consumed": "Water use",
	"max_rovers": "Max rovers",
	"build_time_multiplier": "Build time",
}

const DATA := {
	"energy": {
		"name": "Energy generator",
		"levels": [
			{
				"cost": {Resources.BASALT_ROCK: 20, Resources.REGOLITH: 10},
				"stats": {"output": 8},
			},
			{
				"cost": {Resources.BASALT_ROCK: 40, Resources.REGOLITH: 20, Resources.IRON_ORE: 15},
				"stats": {"output": 12},
			},
		],
	},
	"water": {
		"name": "Water generator",
		"levels": [
			{
				"cost": {Resources.BASALT_ROCK: 20, Resources.REGOLITH: 10},
				"stats": {"output": 8},
			},
			{
				"cost": {Resources.BASALT_ROCK: 40, Resources.REGOLITH: 20, Resources.IRON_ORE: 15},
				"stats": {"output": 12},
			},
		],
	},
	"Basalt Rock": {
		"name": "Basalt miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 40, Resources.REGOLITH: 10},
				"stats": {"output": 4, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 30, Resources.IRON_ORE: 20},
				"stats": {"output": 7, "energy_used": 3},
			},
		],
	},
	"Regolith": {
		"name": "Regolith miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 40, Resources.REGOLITH: 15},
				"stats": {"output": 4, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 40, Resources.IRON_ORE: 20},
				"stats": {"output": 7, "energy_used": 3},
			},
		],
	},
	"Iron_Ore": {
		"name": "Iron miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 50, Resources.WATER: 50, Resources.BASALT_ROCK: 100, Resources.REGOLITH: 50},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 40, Resources.IRON_ORE: 20},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Ice": {
		"name": "Ice miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 40, Resources.WATER: 50, Resources.IRON_ORE: 100, Resources.REGOLITH: 50},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 40, Resources.IRON_ORE: 20, Resources.ICE: 10},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Titanium": {
		"name": "Titanium miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 90, Resources.REGOLITH: 40, Resources.IRON_ORE: 50, Resources.ICE: 35},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 90, Resources.WATER: 90, Resources.BASALT_ROCK: 120, Resources.REGOLITH: 60, Resources.IRON_ORE: 70, Resources.ICE: 50, Resources.TITANIUM: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Aluminum": {
		"name": "Aluminum miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 90, Resources.REGOLITH: 40, Resources.IRON_ORE: 50, Resources.ICE: 35},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 90, Resources.WATER: 90, Resources.BASALT_ROCK: 120, Resources.REGOLITH: 60, Resources.IRON_ORE: 70, Resources.ICE: 50, Resources.ALUMINUM: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Nickel": {
		"name": "Nickel miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 75, Resources.WATER: 75, Resources.BASALT_ROCK: 120, Resources.REGOLITH: 55, Resources.IRON_ORE: 65, Resources.TITANIUM: 45},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 110, Resources.WATER: 110, Resources.BASALT_ROCK: 160, Resources.REGOLITH: 80, Resources.IRON_ORE: 90, Resources.TITANIUM: 65, Resources.NICKEL: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Sulfur": {
		"name": "Sulfur miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 75, Resources.WATER: 75, Resources.BASALT_ROCK: 120, Resources.REGOLITH: 55, Resources.ICE: 55, Resources.ALUMINUM: 45},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 110, Resources.WATER: 110, Resources.BASALT_ROCK: 160, Resources.REGOLITH: 80, Resources.ICE: 80, Resources.ALUMINUM: 65, Resources.SULFUR: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Gypsum": {
		"name": "Gypsum miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 90, Resources.WATER: 90, Resources.BASALT_ROCK: 150, Resources.REGOLITH: 70, Resources.ICE: 70, Resources.NICKEL: 40},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 130, Resources.WATER: 130, Resources.BASALT_ROCK: 200, Resources.REGOLITH: 100, Resources.ICE: 100, Resources.NICKEL: 60, Resources.GYPSUM: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"Soluble Salts": {
		"name": "Soluble Salts miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 90, Resources.WATER: 90, Resources.BASALT_ROCK: 150, Resources.REGOLITH: 70, Resources.SULFUR: 40, Resources.GYPSUM: 40},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 130, Resources.WATER: 130, Resources.BASALT_ROCK: 200, Resources.REGOLITH: 100, Resources.SULFUR: 60, Resources.GYPSUM: 60, Resources.SOLUBLE_SALTS: 15},
				"stats": {"output": 5, "energy_used": 3},
			},
		],
	},
	"base": {
		"name": "Base",
		"levels": [
			{
				"cost": {Resources.ENERGY: 50, Resources.WATER: 50, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 30, Resources.IRON_ORE: 20},
				"stats": {"max_rovers": 6, "build_time_multiplier": 0.8},
			},
			{
				"cost": {Resources.ENERGY: 120, Resources.WATER: 120, Resources.BASALT_ROCK: 200, Resources.REGOLITH: 100, Resources.IRON_ORE: 60, Resources.ICE: 40, Resources.TITANIUM: 20},
				"stats": {"max_rovers": 10, "build_time_multiplier": 0.65},
			},
		],
	},
}


static func levels(id: String) -> Array:
	return DATA.get(id, {}).get("levels", [])


static func display_name(id: String) -> String:
	return DATA.get(id, {}).get("name", id)


static func stat_name(stat: String) -> String:
	return STAT_NAMES.get(stat, stat)


## Text for a stat value (the multiplier is shown as a percentage of normal time).
static func format_stat(stat: String, value) -> String:
	if stat == "build_time_multiplier":
		return "%d%%" % roundi(float(value) * 100.0)
	return str(value)

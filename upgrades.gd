class_name Upgrades_info
extends RefCounted
## Upgrade catalog (static data only), same idea as Buildings.DATA.
##
## Key = building id (key of Buildings.DATA) or "base".
## "levels"[i] is what you get by going from level i+1 to level i+2:
##   "cost":  {resource id: amount}, paid with Inventory.spend().
##            Resource ids are ALWAYS Resources.* constants, never raw strings.
##   "stats": {stat name: NEW absolute value}. Stats not listed keep their value.
## Level 1 values come from the node itself (generator.gd: output = 1 and its
## exported energy_used / water_consumed; base.gd: max_rovers, multiplier).
## Max level = levels.size() + 1.
##
## To make something upgradable: add an entry here and give the node an
## `upgrade: UpgradeState` and an upgrade_requested emit (see generator.gd).

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
				"cost": {Resources.BASALT_ROCK: 20, Resources.REGOLITH: 10, Resources.ROCK_1: 4},
				"stats": {"output": 2},
			},
			{
				"cost": {Resources.BASALT_ROCK: 40, Resources.REGOLITH: 25, Resources.ROCK_1: 10},
				"stats": {"output": 3},
			},
		],
	},
	"water": {
		"name": "Water generator",
		"levels": [
			{
				"cost": {Resources.BASALT_ROCK: 30, Resources.REGOLITH: 20, Resources.ROCK_1: 8},
				"stats": {"output": 2},
			},
			{
				"cost": {Resources.BASALT_ROCK: 60, Resources.REGOLITH: 40, Resources.ROCK_1: 16},
				"stats": {"output": 3},
			},
		],
	},
	# Mining: more output, but it also eats more energy (adjust to your level-1 energy_used).
	"Basalt Rock": {
		"name": "Basalt miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 20, Resources.WATER: 20, Resources.BASALT_ROCK: 30},
				"stats": {"output": 2, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 40, Resources.WATER: 40, Resources.BASALT_ROCK: 60},
				"stats": {"output": 3, "energy_used": 4},
			},
		],
	},
	"Regolith": {
		"name": "Regolith miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.ROCK_1: 30},
				"stats": {"output": 2, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.ROCK_1: 60},
				"stats": {"output": 3, "energy_used": 4},
			},
		],
	},
	"base": {
		"name": "Base",
		"levels": [
			{
				"cost": {
					Resources.ENERGY: 40, Resources.WATER: 40,
					Resources.BASALT_ROCK: 40, Resources.REGOLITH: 20,
				},
				"stats": {"max_rovers": 4, "build_time_multiplier": 0.8},
			},
			{
				"cost": {
					Resources.ENERGY: 80, Resources.WATER: 80,
					Resources.BASALT_ROCK: 80, Resources.REGOLITH: 40,
				},
				"stats": {"max_rovers": 5, "build_time_multiplier": 0.6},
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

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
				"stats": {"output": 6},
			},
			{
				"cost": {Resources.BASALT_ROCK: 40, Resources.REGOLITH: 20, Resources.IRON_ORE: 15},
				"stats": {"output": 8},
			},
		],
	},
	"water": {
		"name": "Water generator",
		"levels": [
			{
				"cost": {Resources.BASALT_ROCK: 20, Resources.REGOLITH: 10},
				"stats": {"output": 6},
			},
			{
				"cost": {Resources.BASALT_ROCK: 40, Resources.REGOLITH: 20, Resources.IRON_ORE: 15},
				"stats": {"output": 8},
			},
		],
	},
	"Basalt Rock": {
		"name": "Basalt miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 40, Resources.REGOLITH: 10},
				"stats": {"output": 3, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 30, Resources.IRON_ORE: 20},
				"stats": {"output": 4, "energy_used": 3},
			},
		],
	},
	"Regolith": {
		"name": "Regolith miner",
		"levels": [
			{
				"cost": {Resources.ENERGY: 30, Resources.WATER: 30, Resources.BASALT_ROCK: 40, Resources.REGOLITH: 15},
				"stats": {"output": 2, "energy_used": 2},
			},
			{
				"cost": {Resources.ENERGY: 60, Resources.WATER: 60, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 40, Resources.IRON_ORE: 20},
				"stats": {"output": 3, "energy_used": 3},
			},
		],
	},
	"base": {
		"name": "Base",
		"levels": [
			{
				"cost": {Resources.ENERGY: 50, Resources.WATER: 50, Resources.BASALT_ROCK: 80, Resources.REGOLITH: 30, Resources.IRON_ORE: 20},
				"stats": {"max_rovers": 4, "build_time_multiplier": 0.8},
			},
			{
				"cost": {Resources.ENERGY: 120, Resources.WATER: 120, Resources.BASALT_ROCK: 200, Resources.REGOLITH: 100, Resources.IRON_ORE: 60, Resources.ICE: 40, Resources.TITANIUM: 20},
				"stats": {"max_rovers": 5, "build_time_multiplier": 0.65},
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

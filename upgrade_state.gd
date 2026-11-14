class_name UpgradeState
extends RefCounted
## Level and current stats of one upgradable object (a generator or the base).
## The object creates it with its catalog id and its level-1 stats, reads
## `stats` when it needs a value, and the UI calls try_upgrade().

signal leveled_up(new_level: int)

var upgrade_id: String
var level := 1
## Current value of every stat. Starts as the level-1 stats.
var stats: Dictionary


func _init(id: String, base_stats: Dictionary) -> void:
	upgrade_id = id
	stats = base_stats.duplicate()


func max_level() -> int:
	return UpgradesInfo.levels(upgrade_id).size() + 1


func is_max() -> bool:
	return level >= max_level()


## Data of the next level ({"cost", "stats"}), or {} at max level.
func next() -> Dictionary:
	if is_max():
		return {}
	return UpgradesInfo.levels(upgrade_id)[level - 1]


func can_afford() -> bool:
	return not is_max() and Inventory.can_afford(next()["cost"])


## Pays the cost and applies the next level. False if max level or not affordable.
func try_upgrade() -> bool:
	if is_max() or not Inventory.spend(next()["cost"]):
		return false
	stats.merge(next()["stats"], true)  # Before level += 1: next() depends on level.
	level += 1
	leveled_up.emit(level)
	return true

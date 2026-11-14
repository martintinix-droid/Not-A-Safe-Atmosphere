extends Node
## Autoload (singleton) that stores how much of each resource the player has.
## Single source of truth for resource amounts: generators add to it, building
## costs are paid from it, and inventory_display.gd listens to it to refresh the UI.
##
## Resources are identified by a String id (e.g. "energy", "Basalt rock"). The
## same ids are used in Buildings.DATA (costs), generator.gd (resource_id) and
## inventory_display.gd (icons and names).

## Emitted whenever an amount changes. `amount` is the NEW total for that id.
signal changed(id: String, amount: int)

## id -> current amount. Starting stock comes from Resources.DATA ("start").
var _amounts := Resources.starting_stock()


## Returns the amount stored for `id` (0 if the id is unknown).
func get_amount(id: String) -> int:
	return _amounts.get(id, 0)


## Returns every known resource id.
func get_ids() -> Array:
	return _amounts.keys()


## Adds `amount` to `id` (negative values subtract) and emits `changed`.
## Unknown ids are created. It does not check for negative totals: use spend()
## when paying a cost.
func add(id: String, amount: int = 1) -> void:
	_amounts[id] = get_amount(id) + amount
	changed.emit(id, _amounts[id])

func substract(id: String, amount: int = 1) -> void:
	_amounts[id] = get_amount(id) - amount
	changed.emit(id, _amounts[id])

## True if every resource in `cost` ({id: amount}) is available.
func can_afford(cost: Dictionary) -> bool:
	for id in cost:
		if get_amount(id) < cost[id]:
			return false
	return true


## Pays `cost` ({id: amount}). All-or-nothing: if anything is missing, nothing
## is deducted and false is returned.
func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for id in cost:
		add(id, -cost[id])
	return true

## Starting stock, copied once at startup so reset() can restore it.
var _starting_amounts := {}

func _ready() -> void:
	_starting_amounts = _amounts.duplicate()

## Puts every resource back to its starting amount (used by "Play Again").
func reset() -> void:
	_amounts = _starting_amounts.duplicate()
	for id in _amounts:
		changed.emit(id, _amounts[id])

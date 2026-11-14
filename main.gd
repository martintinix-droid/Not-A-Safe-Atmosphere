extends Node2D
## Main game controller: instantiates the buildings requested by the UI and is
## the only node that listens for the player's input.
##
## Centralizing clicks here (instead of every object running its own _input)
## makes it possible to tell "you clicked an interactable" apart from "you
## clicked the ground" without each system's handlers competing with each other.
##
## Resource amounts live in the Inventory autoload and the building catalog
## lives in Buildings.DATA.

## Group that every clickable node joins (see generator.gd and ground_resource.gd).
const INTERACTABLE_GROUP := "interactables"
@onready var game_time: Timer = %game_time

## Building currently in "ghost" mode (spawned but not placed yet), if any.
## Prevents spawning a second building before the first one is placed, and
## gives the ghost priority when resolving a click.
var _placing_building: Node = null


func _ready() -> void:
	NodeRefs.main_ref = self
	SignalManager.spawn_building.connect(_on_spawn_building)
	game_time.timeout.connect(func()-> void:
		SignalManager.game_lost.emit()
		)
	_validate_resource_ids()

# _unhandled_input (not _input): if a UI Control (e.g. a button) consumes the
# click, it never reaches this function, so no rover is sent to the ground
# behind the UI.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		_handle_click(get_global_mouse_position())
	elif event.is_action_pressed("inventory"):
		# ui.gd listens to this signal and slides the inventory panel in/out.
		SignalManager.inventory_actioned.emit()
		print("inventory opened")  # Debug print (it also fires when closing).


# --- Click handling ---

## Single entry point for "something was clicked". If there is an interactable
## under the click, emits its "clicked" signal and notifies the other systems
## (e.g. the base, which decides whether to send a rover). Otherwise the click
## was on free ground.
func _handle_click(click_position: Vector2) -> void:
	var target := _find_clicked_interactable(click_position)
	if target == null:
		SignalManager.ground_clicked.emit(click_position)
		return

	target.clicked.emit()
	SignalManager.interactable_clicked.emit(target)


## Finds which interactable is under click_position. The ghost building (if
## there is one) has priority: it is the one following the mouse.
func _find_clicked_interactable(click_position: Vector2) -> Node:
	if is_instance_valid(_placing_building) and _is_click_on(_placing_building, click_position):
		return _placing_building

	for node in get_tree().get_nodes_in_group(INTERACTABLE_GROUP):
		if node != _placing_building and _is_click_on(node, click_position):
			return node

	return null


## The hit-test is sprite-accurate (transparent pixels are ignored), not based
## on the bounding box. For now only Sprite2D interactables are supported.
func _is_click_on(node: Node, click_position: Vector2) -> bool:
	var sprite := node as Sprite2D
	if sprite == null:
		return false
	return sprite.is_pixel_opaque(sprite.to_local(click_position))


# --- Building placement ---

## Handles SignalManager.spawn_building: pays the cost and spawns the building
## as a ghost that follows the mouse until the player places it.
func _on_spawn_building(building_id: String) -> void:
	# If a ghost is still waiting to be placed, don't create another one:
	# they would overlap.
	if is_instance_valid(_placing_building):
		return
	if not Buildings.DATA.has(building_id):
		push_warning("Unknown building: %s" % building_id)
		return

	var info: Dictionary = Buildings.DATA[building_id]

	# Materials are charged up front, when the ghost spawns (not when placed).
	if not Inventory.spend(info["materials"]):
		print("not enough materials")  # TODO: show an on-screen "not enough materials" message
		return

	var new_building: Node = info["scene"].instantiate()
	# Set before add_child(): generator.gd reads building_id in _ready().
	new_building.building_id = building_id
	new_building.build_time = float(info["build_time"]) * _build_time_multiplier()
	add_child(new_building)
	_placing_building = new_building
	new_building.state_changed.connect(_on_placing_finished, CONNECT_ONE_SHOT)

## Base upgrade: shorter construction. Rover and building timer both use the result.
func _build_time_multiplier() -> float:
	if is_instance_valid(NodeRefs.base_ref):
		return NodeRefs.base_ref.build_time_multiplier
	return 1.0

## The ghost was placed: release the placement lock.
func _on_placing_finished() -> void:
	_placing_building = null


func _validate_resource_ids() -> void:
	if not OS.is_debug_build():
		return
	for building_id in Buildings.DATA:
		for bad_id in Resources.unknown_ids(Buildings.DATA[building_id]["materials"]):
			push_warning("Building '%s' costs unknown resource '%s'" % [building_id, bad_id])
	for event_id in EventsData.DATA:
		for option in EventsData.DATA[event_id]["options"]:
			for bad_id in Resources.unknown_ids(option["requires"]):
				push_warning("Event '%s' requires unknown resource '%s'" % [event_id, bad_id])
	for upgrade_id in UpgradesInfo.DATA:
		for level_data in UpgradesInfo.levels(upgrade_id):
			for bad_id in Resources.unknown_ids(level_data["cost"]):
				push_warning("Upgrade '%s' costs unknown resource '%s'" % [upgrade_id, bad_id])
	for event_id in EventsData.DATA:
		for option in EventsData.DATA[event_id]["options"]:
			for effect in option["effects"]:
				if effect["type"] == "resource" and not Resources.exists(effect["id"]):
					push_warning("Event '%s' changes unknown resource '%s'" % [event_id, effect["id"]])

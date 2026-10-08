extends Control
## In-game HUD. Manages two sliding panels:
##   - Building panel: the "building" button slides out and the list of
##     buildable structures slides in. Each building button asks main.gd to
##     spawn that building (through SignalManager.spawn_building).
##   - Inventory panel: slides up from the bottom of the screen (and back down)
##     when the inventory key is pressed (SignalManager.invenotry_actioned).


# --- Constants ---

## Horizontal distance the building button / building list slide.
const SWAP_OFFSET_X := 300.0
## Duration, in seconds, of every slide animation.
const SWAP_DURATION := 0.5


# --- Node references ---

@onready var building_button: Button = %"building button"
@onready var energy: Button = %energy
@onready var water: Button = $HBoxContainer/VBoxContainer/water
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var back_button: Button = $"HBoxContainer/VBoxContainer2/Back Button"
## Inventory background. The resource grid is its child, so it moves with it.
@onready var inventory_panel: NinePatchRect = %NinePatchRect

## Building id (key of Buildings.DATA) -> its button.
## To add a building: add its button and an entry here.
## (Keep it declared after `energy` and `water`: @onready vars are initialized in order.)
@onready var _building_buttons := {
	"energy": energy,
	"water": water,
}


# --- Building panel state ---

# Original positions, saved once at startup. Always animating to/from these
# values avoids adding/subtracting offsets by hand.
var _building_button_start_pos: Vector2
var _h_box_container_start_pos: Vector2

var _current_building_tween: Tween


# --- Inventory panel state ---

# Panel position when visible (as placed in the editor) and when hidden just
# below the bottom edge of the screen.
var _inventory_open_pos: Vector2
var _inventory_closed_pos: Vector2
# Target state (open or closed), not the panel's actual position mid-animation.
var _inventory_open := false
var _inventory_tween: Tween


func _ready() -> void:
	# This panel covers the whole screen; if the root Control absorbed clicks,
	# main.gd would never receive them. The buttons still consume their own clicks.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_building_panel()
	_setup_inventory_panel()


func _setup_building_panel() -> void:
	_building_button_start_pos = building_button.position
	_h_box_container_start_pos = h_box_container.position

	building_button.pressed.connect(_swap_building_ui)
	back_button.pressed.connect(_reset_building_ui)
	for building_id in _building_buttons:
		var button: Button = _building_buttons[building_id]
		button.pressed.connect(_request_building.bind(building_id))
		button.tooltip_text = _get_cost_tooltip(building_id)


func _setup_inventory_panel() -> void:
	# The panel is placed in the editor where it should appear when OPEN.
	# Here we compute the closed position (just below the bottom edge of the
	# screen) and start with the panel hidden.
	_inventory_open_pos = inventory_panel.position
	_inventory_closed_pos = _inventory_open_pos + Vector2(
		0, get_viewport_rect().size.y - inventory_panel.global_position.y
	)
	inventory_panel.position = _inventory_closed_pos
	inventory_panel.visible = false

	SignalManager.invenotry_actioned.connect(swap_inventory)


# --- Building panel ---

func _request_building(building_id: String) -> void:
	SignalManager.spawn_building.emit(building_id)


## Tooltip text for a building button: one "resource: amount" line per material it costs.
func _get_cost_tooltip(building_id: String) -> String:
	var lines: Array[String] = []
	var cost: Dictionary = Buildings.DATA[building_id]["materials"]
	for id in cost:
		lines.append("%s: %d" % [id, cost[id]])
	return "\n".join(lines)


## Slides building_button out and h_box_container in.
func _swap_building_ui() -> void:
	h_box_container.position = _h_box_container_start_pos + Vector2(SWAP_OFFSET_X, 0)
	h_box_container.visible = true

	_animate_swap(
		_building_button_start_pos + Vector2(SWAP_OFFSET_X, 0),
		_h_box_container_start_pos
	)


## Inverse of _swap_building_ui: puts everything back in its original position.
func _reset_building_ui() -> void:
	_animate_swap(
		_building_button_start_pos,
		_h_box_container_start_pos + Vector2(SWAP_OFFSET_X, 0),
		func() -> void:
			h_box_container.visible = false
	)


## Animates building_button and h_box_container in parallel towards the given
## positions. The buttons are disabled while it runs and re-enabled at the end
## (running on_finished right before, if one was given).
func _animate_swap(
	building_button_target: Vector2,
	h_box_container_target: Vector2,
	on_finished: Callable = Callable()
) -> void:
	if _current_building_tween and _current_building_tween.is_valid():
		_current_building_tween.kill()

	_set_buttons_interactable(false)

	_current_building_tween = create_tween()
	_current_building_tween.set_trans(Tween.TRANS_QUAD)
	_current_building_tween.set_parallel(true)
	_current_building_tween.tween_property(
		building_button, "position", building_button_target, SWAP_DURATION
	)
	_current_building_tween.tween_property(
		h_box_container, "position", h_box_container_target, SWAP_DURATION
	)

	_current_building_tween.finished.connect(func() -> void:
		if on_finished.is_valid():
			on_finished.call()
		_set_buttons_interactable(true)
	)


func _set_buttons_interactable(interactable: bool) -> void:
	building_button.disabled = not interactable
	back_button.disabled = not interactable
	for button in _building_buttons.values():
		button.disabled = not interactable


# --- Inventory panel ---

## Toggles the inventory between shown and hidden (triggered by
## SignalManager.invenotry_actioned).
## Unlike the building panel, it does not lock anything: if it is called
## mid-animation, it cancels it and starts the opposite one from wherever the
## panel currently is.
func swap_inventory() -> void:
	_inventory_open = not _inventory_open
	var target := _inventory_open_pos if _inventory_open else _inventory_closed_pos

	if _inventory_tween and _inventory_tween.is_valid():
		_inventory_tween.kill()

	if _inventory_open:
		inventory_panel.visible = true

	# Duration is proportional to the distance left to travel: reversing
	# halfway takes half the time, not the full duration.
	var full_distance := maxf(absf(_inventory_closed_pos.y - _inventory_open_pos.y), 1.0)
	var remaining := absf(target.y - inventory_panel.position.y)

	_inventory_tween = create_tween()
	_inventory_tween.set_trans(Tween.TRANS_QUAD)
	_inventory_tween.tween_property(
		inventory_panel, "position", target, SWAP_DURATION * remaining / full_distance
	)

	# "finished" is only emitted if the animation ends on its own; if it gets
	# cancelled by another key press, the panel is not hidden halfway.
	if not _inventory_open:
		_inventory_tween.finished.connect(func() -> void:
			inventory_panel.visible = false
		)

extends CanvasLayer
## Quick interactive tutorial. Built entirely in code (no scene needed): ui.gd
## adds it as a child at startup, like win_screen.gd.
##
## Each step shows a short instruction at the top of the screen and waits for
## the player to actually do it (click the ground, open the inventory, build a
## generator...). Steps listen to the same SignalManager signals the game uses,
## so nothing else in the game had to change.
##
## While the tutorial runs the 100 second game_time timer is stopped, and the
## research bar is held at 0 so the tutorial itself can't end the game.
## When the player finishes it, the game restarts from scratch (fresh
## inventory, no buildings, full 100 seconds). Skipping just starts the timer.
## It only appears the first time: "Play Again" does not show it again.
##
## To change the tutorial, edit STEPS below.

## Set to false to turn the tutorial off completely.
const ENABLED := true

## "wait" says what finishes the step:
##   "next"      the Next button
##   "ground"    click free ground (a rover is sent)
##   "rock"      click a gatherable rock
##   "inventory" press the inventory key twice (open + close)
##   "menu"      press the Building button
##   "spawn"     pick the building named in "building"
##   "place"     put the ghost building down
##   "built"     wait until "count" buildings are finished
## "highlight" (optional) pulses a border around a UI control.
const STEPS := [
	{
		"text": "Welcome to Not A Safe Atmosphere!\n\nYour goal: build a Research Lab and fill the research bar to 100% before the 100 second timer runs out. Let's learn the basics. You can hold the right mouse button and drag to pan the camera, and scroll to zoom.",
		"wait": "next",
	},
	{
		"text": "Click anywhere on the ground. Your base will send a rover to that spot.",
		"wait": "ground",
	},
	{
		"text": "Rovers can also gather resources. Click the rock to send a rover to mine it. (Can't see it? Pan the camera around.)",
		"wait": "rock",
	},
	{
		"text": "Press {key} to open your inventory and see what you have. Press {key} again to close it.",
		"wait": "inventory",
	},
	{
		"text": "Now let's build something. Click the Building button to open the build menu.",
		"wait": "menu",
		"highlight": "building_button",
	},
	{
		"text": "Choose Energy to build an energy generator. Hover over any building button to see its cost; it is paid as soon as you pick it.",
		"wait": "spawn",
		"building": "energy",
		"highlight": "energy",
	},
	{
		"text": "The building follows your mouse. Green means you can place it, red means something is in the way. Click on a free spot to place it.",
		"wait": "place",
	},
	{
		"text": "A rover is flying out to construct it. Wait until it turns white: that means it is finished and producing.",
		"wait": "built",
		"count": 1,
	},
	{
		"text": "Now build the Research Lab. It is how you win, and it costs 50 energy and 50 water. (Reopen the build menu if it closed.)",
		"wait": "spawn",
		"building": "Research Lab",
		"highlight": "lab",
	},
	{
		"text": "Place the Research Lab on a free spot, the same way as before.",
		"wait": "place",
	},
	{
		"text": "Research Labs take longer to build. Wait for the rover to finish it.",
		"wait": "built",
		"count": 2,
	},
	{
		"text": "Done! Each research tick fills the research bar a little. Fill it to 100% before the timer runs out, or you lose. Labs use energy and water, so keep your generators running. Random events can also shake things up.\n\nPress Start Game to begin for real. The 100 seconds start now!",
		"wait": "next",
		"highlight": "research_bar",
	},
]

const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.2)

## Remembered between scene reloads (static), so "Play Again" skips the tutorial.
static var already_shown := false

var _ui  # The HUD (ui.gd). Untyped on purpose: we read its @onready buttons.
var _root: Control
var _panel: PanelContainer
var _step_label: Label
var _text_label: Label
var _next_button: Button
var _highlight: Panel

var _step := -1
var _inventory_presses := 0
var _ghost_seen := false   # The ghost building appeared (so we can tell when it is placed).
var _place_wait := 0.0     # Time waiting for the ghost to appear (spawn can fail).
var _finished := false


func _init() -> void:
	layer = 90  # Above the HUD, below the win/lose screen (100).


func _ready() -> void:
	if not ENABLED or already_shown:
		queue_free()
		return
	_ui = get_parent()
	_build()

	SignalManager.ground_clicked.connect(_on_ground_clicked)
	SignalManager.interactable_clicked.connect(_on_interactable_clicked)
	SignalManager.inventory_actioned.connect(_on_inventory_actioned)
	SignalManager.spawn_building.connect(_on_spawn_building)
	_ui.building_button.pressed.connect(_on_building_button_pressed)

	# main.gd registers itself in NodeRefs AFTER the HUD is ready, so wait a frame.
	_begin.call_deferred()


func _begin() -> void:
	var main = NodeRefs.main_ref
	if main != null:
		main.game_time.stop()  # The 100 seconds start when the tutorial ends.
	_ui.research_progerss.value = 0  # So the tutorial can't win the game.
	_go_to(0)


# --- UI ---

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE  # The game stays clickable.
	if _ui is Control:
		_root.theme = _ui.theme
	add_child(_root)

	# Pulsing border around the control the current step is about.
	_highlight = Panel.new()
	var border := StyleBoxFlat.new()
	border.bg_color = Color(0, 0, 0, 0)
	border.border_color = HIGHLIGHT_COLOR
	border.set_border_width_all(4)
	border.set_corner_radius_all(8)
	_highlight.add_theme_stylebox_override("panel", border)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.hide()
	_root.add_child(_highlight)
	var pulse := create_tween().set_loops()
	pulse.tween_property(_highlight, "modulate:a", 0.35, 0.5)
	pulse.tween_property(_highlight, "modulate:a", 1.0, 0.5)

	# Instruction panel, top center.
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.1, 0.92)
	style.border_color = HIGHLIGHT_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size.x = 640.0
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 24)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_panel.add_child(box)

	_step_label = Label.new()
	_step_label.add_theme_font_size_override("font_size", 18)
	_step_label.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	box.add_child(_step_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 24)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size.x = 592.0
	box.add_child(_text_label)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)

	var skip_button := Button.new()
	skip_button.text = "Skip Tutorial"
	skip_button.pressed.connect(_on_skip_pressed)
	buttons.add_child(skip_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)

	_next_button = Button.new()
	_next_button.custom_minimum_size = Vector2(160, 0)
	_next_button.pressed.connect(_on_next_pressed)
	buttons.add_child(_next_button)


# --- Step flow ---

func _go_to(index: int) -> void:
	_step = index
	_inventory_presses = 0
	_ghost_seen = false
	_place_wait = 0.0
	var data: Dictionary = STEPS[index]
	_step_label.text = "Tutorial  %d / %d" % [index + 1, STEPS.size()]
	_text_label.text = String(data["text"]).format({"key": _inventory_key_name()})
	_next_button.visible = data["wait"] == "next"
	_next_button.text = "Start Game" if index == STEPS.size() - 1 else "Next"


func _advance() -> void:
	if _step + 1 < STEPS.size():
		_go_to(_step + 1)


func _wait() -> String:
	return STEPS[_step]["wait"]


func _on_next_pressed() -> void:
	if _step >= STEPS.size() - 1:
		_finish(true)
	else:
		_advance()


func _on_skip_pressed() -> void:
	_finish(false)


## restart_game = true: fresh game (like "Play Again"). false (skip): keep
## whatever the player built and just start the timer.
func _finish(restart_game: bool) -> void:
	if _finished:
		return
	_finished = true
	already_shown = true
	if restart_game:
		for child in get_tree().root.get_children():
			if child is OutpostRover:
				child.queue_free()
		Inventory.reset()
		get_tree().reload_current_scene()
	else:
		NodeRefs.main_ref.game_time.start()
		queue_free()


# --- Detecting what the player did ---

func _on_ground_clicked(_click_position: Vector2) -> void:
	if _step >= 0 and _wait() == "ground":
		_advance()


func _on_interactable_clicked(target: Node) -> void:
	if _step < 0 or _wait() != "rock":
		return
	# Anything clickable that is not the base or a building is a gatherable.
	if is_instance_valid(target) and target != NodeRefs.base_ref \
			and not target.is_in_group("buildings"):
		_advance()


func _on_inventory_actioned() -> void:
	if _step >= 0 and _wait() == "inventory":
		_inventory_presses += 1
		if _inventory_presses >= 2:
			_advance()


func _on_building_button_pressed() -> void:
	if _step >= 0 and _wait() == "menu":
		_advance()


func _on_spawn_building(building_id: String) -> void:
	if _step >= 0 and _wait() == "spawn" and building_id == STEPS[_step]["building"]:
		_advance()


func _process(delta: float) -> void:
	if _step < 0 or _finished:
		return
	_update_highlight()
	match _wait():
		"place":
			_check_placing(delta)
		"built":
			if _active_buildings() >= int(STEPS[_step]["count"]):
				_advance()


## The ghost exists while the player is placing it. When it disappears it was
## placed. If it never shows up, the spawn failed (not enough materials).
func _check_placing(delta: float) -> void:
	var main = NodeRefs.main_ref
	var ghost = main.get("_placing_building") if main != null else null
	if is_instance_valid(ghost):
		_ghost_seen = true
	elif _ghost_seen:
		_advance()
	else:
		_place_wait += delta
		if _place_wait > 0.6:
			_go_to(_step - 1)
			_text_label.text = "Not enough materials. Check the cost and try again.\n\n" + _text_label.text


func _active_buildings() -> int:
	var count := 0
	for building in get_tree().get_nodes_in_group("buildings"):
		if building.has_method("is_active") and building.is_active():
			count += 1
	return count


# --- Helpers ---

func _update_highlight() -> void:
	var target := _highlight_target()
	if target == null or not target.is_visible_in_tree():
		_highlight.hide()
		return
	var rect := target.get_global_rect().grow(6.0)
	_highlight.position = rect.position
	_highlight.size = rect.size
	_highlight.show()


func _highlight_target() -> Control:
	match STEPS[_step].get("highlight", ""):
		"building_button":
			return _ui.building_button
		"energy":
			return _ui.energy
		"lab":
			return _ui.research_lab
		"research_bar":
			return _ui.research_progerss
	return null


## Name of the key bound to the "inventory" action (e.g. "Tab").
func _inventory_key_name() -> String:
	for event in InputMap.action_get_events("inventory"):
		if event is InputEventKey:
			var code: Key = event.physical_keycode
			if code == KEY_NONE:
				code = event.keycode
			return OS.get_keycode_string(code)
	return "the inventory key"


extends CanvasLayer
## First-run interactive tutorial for Not A Safe Atmosphere.
## The tutorial pauses the game clock and random-event schedule until the player
## starts or skips the real game. Completing the tutorial restarts with a clean
## colony; skipping keeps anything the player has already built.

const ENABLED := true
const HIGHLIGHT_COLOR := Color(1.0, 0.85, 0.2)

## Starter production buildings each cost 8 Basalt Rock + 3 Regolith.
## Collect enough for one Energy Generator and one Water Generator.
const STARTER_RESOURCE_REQUIREMENTS := {
	Resources.BASALT_ROCK: 16,
	Resources.REGOLITH: 6,
}

## "wait" controls how a step completes:
##   "next"      - the player presses Next
##   "resources" - the inventory reaches the required starting stock
##   "inventory" - the player opens and closes the inventory
##   "menu"      - the player opens the Build menu
##   "spawn"     - the player chooses the named building
##   "place"     - the selected ghost building is placed
##   "built"     - the named building finishes construction
## "highlight" optionally pulses a border around a HUD control.

const STEPS := [
	{
		"text": "Welcome to Not A Safe Atmosphere!\n\nYour mission is to establish a working Martian outpost, construct a Research Lab, and fill the research bar to 100% before the {duration} game timer expires. Energy and Water must stay above zero or the colony is lost.\n\nThis tutorial walks through the opening setup and explains the full production chain.",
		"wait": "next",
	},
	{
		"text": "CAMERA AND ROVERS\n\nHold the RIGHT mouse button and drag to pan around the map. Use the mouse wheel to zoom in and out.\n\nLeft-clicking an open area sends a rover to that location and back. Clicking a resource deposit sends a rover to collect it. The base can have up to 3 rovers active at once; additional resource jobs wait until a rover is free.",
		"wait": "next",
	},
	{
		"text": "GATHER THE STARTING MATERIALS\n\nFind Basalt Rock and Regolith deposits around the map and left-click them. A rover travels to each deposit, gathers its resources, and returns them to your inventory.\n\nCollect at least 16 Basalt Rock and 6 Regolith. That is enough to build one Energy Generator and one Water Generator. The counters below update as each rover finishes its job.",
		"wait": "resources",
		"requirements": STARTER_RESOURCE_REQUIREMENTS,
	},
	{
		"text": "CHECK YOUR INVENTORY\n\nPress {key} to open the inventory and review your resource totals. Press {key} again to close it. Resource amounts update automatically as rovers gather materials and buildings produce resources.",
		"wait": "inventory",
	},
	{
		"text": "OPEN THE BUILD MENU\n\nClick the Build button to reveal the available production buildings. Hover over a building button to read its material cost before choosing it.",
		"wait": "menu",
		"highlight": "building_button",
	},
	{
		"text": "SELECT AN ENERGY GENERATOR\n\nChoose Energy from the build menu. The cost is deducted as soon as you select the building, not when you place it. Hover over the button to review the cost again.",
		"wait": "spawn",
		"building": "energy",
		"highlight": "energy",
	},
	{
		"text": "PLACE THE ENERGY GENERATOR\n\nThe building preview follows your mouse. GREEN means the location is clear; RED means it overlaps another object. Move it to an open area and left-click to place it.",
		"wait": "place",
	},
	{
		"text": "WAIT FOR CONSTRUCTION\n\nAfter placement, the building turns BLUE while it is under construction. A rover travels to it and starts the construction timer when it arrives. Wait until the building turns WHITE; it is now active and producing Energy.",
		"wait": "built",
		"building": "energy",
	},
	{
		"text": "SELECT A WATER GENERATOR\n\nChoose Water from the build menu. It also costs 8 Basalt Rock and 3 Regolith. The menu may still be open; otherwise click Build again. The cost is paid immediately when you select it.",
		"wait": "spawn",
		"building": "water",
		"highlight": "water",
	},
	{
		"text": "PLACE THE WATER GENERATOR\n\nMove the green building preview to a clear spot and left-click to place it. Avoid overlapping the base, resource deposits, or other buildings.",
		"wait": "place",
	},
	{
		"text": "WAIT FOR THE WATER GENERATOR\n\nWait for the rover to finish construction. When the building turns WHITE, it is active. The Energy Generator produces 4 Energy every 2 seconds without upkeep. The Water Generator produces 4 Water every 2 seconds and consumes 1 Energy per cycle.",
		"wait": "built",
		"building": "water",
	},
	{
		"text": "UPGRADES AND RANDOM EVENTS\n\nClick the main Base or an active, upgradeable production building to open its upgrade panel. Base upgrades add rover capacity and reduce construction time. Energy, Water, Basalt Rock, and Regolith producers can also be upgraded.\n\nRandom events occur during the game, usually about every 90–120 seconds. The game pauses while an event is on screen. Read each option carefully: its requirements are shown, and some choices can disable or destroy production buildings.",
		"wait": "next",
	},
	{
		"text": "THE RESOURCE PRODUCTION CHAIN\n\nBuild Basalt Rock and Regolith producers to automate your starting materials. Then expand through the technology chain:\n\nIron Ore → Ice → Titanium and Aluminum\nTitanium + Iron Ore → Nickel\nAluminum + Ice → Sulfur\nNickel + Ice → Gypsum\nSulfur + Gypsum → Soluble Salts\n\nThese resources, together with Energy, Water, Basalt Rock, and Regolith, are required to construct the Research Lab.",
		"wait": "next",
	},
	{
		"text": "THE RESEARCH LAB\n\nThe current Research Lab construction cost is:\n{lab_cost}\n\nOnce active, the Lab completes a research cycle every 2 seconds. Each cycle adds 0.5% to the research bar and consumes 2 Energy and 3 Water. Keep your generators running and protect your supplies while research progresses.",
		"wait": "next",
	},
	{
		"text": "YOU ARE READY\n\nWin by filling the research bar to 100% before the {duration} timer runs out. You lose if time expires or Energy or Water reaches zero.\n\nThe tutorial has not kept any of your practice buildings. Press Start Game to begin a fresh colony with the full timer. Good luck on Mars!",
		"wait": "next",
		"highlight": "research_bar",
	},
]

## Static so Play Again / a tutorial restart does not show it a second time.
static var already_shown := false

var _ui
var _root: Control
var _panel: PanelContainer
var _step_label: Label
var _text_label: Label
var _progress_label: Label
var _next_button: Button
var _highlight: Panel

var _step := -1
var _inventory_presses := 0
var _ghost_seen := false
var _place_wait := 0.0
var _finished := false


func _init() -> void:
	layer = 90


func _ready() -> void:
	if not ENABLED or already_shown:
		queue_free()
		return

	_ui = get_parent()
	_build()

	SignalManager.inventory_actioned.connect(_on_inventory_actioned)
	SignalManager.spawn_building.connect(_on_spawn_building)
	_ui.building_button.pressed.connect(_on_building_button_pressed)

	_begin.call_deferred()


func _begin() -> void:
	var main = NodeRefs.main_ref
	if main != null:
		main.game_time.stop()
		_set_event_schedule_paused(true)

	if _ui != null and _ui.research_progerss != null:
		_ui.research_progerss.value = 0

	_go_to(0)


# --------------------------------------------------
# UI
# --------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _ui is Control:
		_root.theme = _ui.theme

	add_child(_root)

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

	_panel = PanelContainer.new()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.1, 0.94)
	style.border_color = HIGHLIGHT_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)

	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16

	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size.x = 700.0

	_panel.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_TOP,
		Control.PRESET_MODE_MINSIZE,
		24
	)

	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	_step_label = Label.new()
	_step_label.add_theme_font_size_override("font_size", 18)
	_step_label.add_theme_color_override(
		"font_color",
		HIGHLIGHT_COLOR
	)
	box.add_child(_step_label)

	_text_label = Label.new()
	_text_label.add_theme_font_size_override("font_size", 21)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size.x = 652.0
	box.add_child(_text_label)

	_progress_label = Label.new()
	_progress_label.add_theme_font_size_override("font_size", 18)
	_progress_label.add_theme_color_override(
		"font_color",
		Color(0.65, 0.9, 1.0)
	)
	_progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_progress_label.hide()
	box.add_child(_progress_label)

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


# --------------------------------------------------
# Step flow
# --------------------------------------------------

func _go_to(index: int) -> void:
	if index < 0 or index >= STEPS.size():
		return

	_step = index
	_inventory_presses = 0
	_ghost_seen = false
	_place_wait = 0.0

	var data: Dictionary = STEPS[index]

	_step_label.text = "Tutorial  %d / %d" % [
		index + 1,
		STEPS.size()
	]

	_text_label.text = String(data["text"]).format({
		"key": _inventory_key_name(),
		"duration": _game_duration_text(),
		"lab_cost": _lab_cost_text(),
	})

	_progress_label.visible = data["wait"] == "resources"

	if _progress_label.visible:
		_update_resource_progress()

	_next_button.visible = data["wait"] == "next"

	_next_button.text = (
		"Start Game"
		if index == STEPS.size() - 1
		else "Next"
	)


func _advance() -> void:
	if _step + 1 < STEPS.size():
		_go_to(_step + 1)


func _wait() -> String:
	return String(STEPS[_step]["wait"])


func _on_next_pressed() -> void:
	if _step >= STEPS.size() - 1:
		_finish(true)
	else:
		_advance()


func _on_skip_pressed() -> void:
	_finish(false)


## restart_game=true: start clean, as with Play Again.
## restart_game=false: preserve the tutorial session and start its game clock.

func _finish(restart_game: bool) -> void:
	if _finished:
		return

	_finished = true
	already_shown = true
	GameSettings.tutorial_completed = true

	if restart_game:
		# This reload clears the tutorial's practice colony. Keep the chosen
		# duration and bypass the selector for this one internal reload.
		GameSettings.skip_duration_selection_once = true
		for child in get_tree().root.get_children():
			if child is OutpostRover:
				child.queue_free()

		Inventory.reset()
		get_tree().reload_current_scene()

	else:
		_set_event_schedule_paused(false)

		var main = NodeRefs.main_ref
		if main != null:
			main.start_game_timer()

		queue_free()


func _set_event_schedule_paused(paused: bool) -> void:
	var main = NodeRefs.main_ref

	if main == null:
		return

	var event_manager = main.get_node_or_null("Event Manager")

	if event_manager != null \
			and event_manager.has_method("set_tutorial_active"):
		event_manager.set_tutorial_active(paused)


# --------------------------------------------------
# Detecting player actions
# --------------------------------------------------

func _on_inventory_actioned() -> void:
	if _step >= 0 and _wait() == "inventory":
		_inventory_presses += 1

		if _inventory_presses >= 2:
			_advance()


func _on_building_button_pressed() -> void:
	if _step >= 0 and _wait() == "menu":
		_advance()


func _on_spawn_building(building_id: String) -> void:
	if _step >= 0 \
			and _wait() == "spawn" \
			and building_id == STEPS[_step]["building"]:
		_advance()


func _process(delta: float) -> void:
	if _step < 0 or _finished:
		return

	_update_highlight()

	match _wait():
		"resources":
			if _update_resource_progress():
				_advance()

		"place":
			_check_placing(delta)

		"built":
			if _is_building_active(
				String(STEPS[_step]["building"])
			):
				_advance()


## Updates live material counters and checks requirements.

func _update_resource_progress() -> bool:
	var requirements: Dictionary = STEPS[_step].get(
		"requirements",
		{}
	)

	var lines: Array[String] = []
	var complete := true

	for id in requirements:
		var required: int = int(requirements[id])
		var current: int = Inventory.get_amount(id)

		lines.append(
			"%s: %d / %d" % [
				Resources.display_name(id),
				current,
				required
			]
		)

		if current < required:
			complete = false

	_progress_label.text = (
		"Materials collected\n"
		+ "     ".join(lines)
	)

	return complete


## Checks whether the selected building has been placed.

func _check_placing(delta: float) -> void:
	var main = NodeRefs.main_ref

	var ghost = (
		main.get("_placing_building")
		if main != null
		else null
	)

	if is_instance_valid(ghost):
		_ghost_seen = true

	elif _ghost_seen:
		_advance()

	else:
		_place_wait += delta

		if _place_wait > 0.6:
			_go_to(_step - 1)

			_text_label.text = (
				"The building could not be created. "
				+ "Check the inventory and try again.\n\n"
				+ _text_label.text
			)


## Checks whether a building is active.

func _is_building_active(building_id: String) -> bool:
	for building in get_tree().get_nodes_in_group("buildings"):

		if String(building.get("building_id")) == building_id \
				and building.has_method("is_active") \
				and building.is_active():

			return true

	return false


# --------------------------------------------------
# UI highlights
# --------------------------------------------------

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

		"water":
			return _ui.water

		"research_bar":
			return _ui.research_progerss

	return null


# --------------------------------------------------
# Dynamic game information
# --------------------------------------------------

## Reads the actual scene timer.

func _game_duration_text() -> String:
	var main = NodeRefs.main_ref
	var total_seconds := 900

	if main != null and main.game_time != null:
		total_seconds = roundi(main.game_time.wait_time)

	var minutes := floori(total_seconds / 60.0)
	var seconds := total_seconds % 60

	if minutes > 0 and seconds == 0:
		return "%d minutes" % minutes

	if minutes > 0:
		return "%d minutes %d seconds" % [
			minutes,
			seconds
		]

	return "%d seconds" % total_seconds


## Gets the Research Lab cost directly from the building catalog.

func _lab_cost_text() -> String:
	var cost: Dictionary = Buildings.DATA["Research Lab"]["materials"]

	var parts: Array[String] = []

	for id in cost:
		parts.append(
			"%s: %d" % [
				Resources.display_name(id),
				int(cost[id])
			]
		)

	return ", ".join(parts)


## Gets the inventory key from the Input Map.

func _inventory_key_name() -> String:
	for event in InputMap.action_get_events("inventory"):

		if event is InputEventKey:
			var code: Key = event.physical_keycode

			if code == KEY_NONE:
				code = event.keycode

			return OS.get_keycode_string(code)

	return "the inventory key"

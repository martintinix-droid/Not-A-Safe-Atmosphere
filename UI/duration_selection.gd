extends CanvasLayer
## Start-of-run screen for selecting the colony's countdown duration.
## The previous duration is preselected, but the player can change it every run.

signal duration_selected(duration_seconds: int)

const OPTIONS_MINUTES := [15,  20, 25, 30, 35, 40]

var _selected_minutes: int = 15
var _button_group: ButtonGroup
var _option_buttons: Dictionary = {}
var _selection_label: Label
var _start_button: Button


func _init() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_selected_minutes = int(GameSettings.selected_duration_seconds / 60)
	if not OPTIONS_MINUTES.has(_selected_minutes):
		_selected_minutes = 15

	get_tree().paused = true
	_build()
	_refresh_selection()


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var parent_control := get_parent() as Control
	if parent_control != null:
		root.theme = parent_control.theme
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.045, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 470)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.055, 0.075, 0.10, 0.98)
	panel_style.border_color = Color(0.32, 0.72, 0.88, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 38
	panel_style.content_margin_right = 38
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	var title := Label.new()
	title.text = "CHOOSE YOUR MISSION LENGTH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	column.add_child(title)

	var description := Label.new()
	description.text = "How much time will your colony have to complete its research?"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size", 19)
	column.add_child(description)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)

	_button_group = ButtonGroup.new()
	_button_group.allow_unpress = false

	for minutes in OPTIONS_MINUTES:
		var option_button := Button.new()
		option_button.text = "%d MINUTES" % minutes
		option_button.custom_minimum_size = Vector2(190, 76)
		option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_button.toggle_mode = true
		option_button.button_group = _button_group
		option_button.add_theme_font_size_override("font_size", 22)
		option_button.pressed.connect(_on_duration_pressed.bind(minutes))
		grid.add_child(option_button)
		_option_buttons[minutes] = option_button

	_selection_label = Label.new()
	_selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_label.add_theme_font_size_override("font_size", 20)
	_selection_label.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95))
	column.add_child(_selection_label)

	_start_button = Button.new()
	_start_button.text = "START MISSION"
	_start_button.custom_minimum_size = Vector2(250, 62)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start_button.add_theme_font_size_override("font_size", 24)
	_start_button.pressed.connect(_on_start_pressed)
	column.add_child(_start_button)


func _on_duration_pressed(minutes: int) -> void:
	_selected_minutes = minutes
	_refresh_selection()


func _refresh_selection() -> void:
	for minutes in _option_buttons:
		var option_button: Button = _option_buttons[minutes]
		option_button.button_pressed = int(minutes) == _selected_minutes

	if _selection_label != null:
		_selection_label.text = "Selected mission length: %d minutes" % _selected_minutes


func _on_start_pressed() -> void:
	var duration_seconds := _selected_minutes * 60
	if not GameSettings.set_duration_seconds(duration_seconds):
		push_error("Invalid mission duration selected: %d seconds" % duration_seconds)
		return

	duration_selected.emit(duration_seconds)
	queue_free()

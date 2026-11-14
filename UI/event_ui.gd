extends Control
## Event HUD: a panel that pops up in the middle of the screen with the event
## title and description, the options (built from EventsData) side by side
## underneath, then the result text with an Accept button.
## Runs while the game is paused (process_mode = Always).
##
## AUTO_OPEN = true shows the panel as soon as the event fires. Set it to false
## to go back to the old flow (corner alert button first, panel after pressing it).

const AUTO_OPEN := true
const OPTION_MIN_SIZE := Vector2(200, 80)
const PANEL_WIDTH := 700.0

@onready var alert_button: Button = %AlertButton
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var options_container: HBoxContainer = %OptionsContainer

var _event_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't swallow clicks meant for the game.
	alert_button.hide()
	_setup_panel_layout()
	panel.hide()

	alert_button.pressed.connect(_on_alert_pressed)
	SignalManager.event_available.connect(_on_event_available)
	SignalManager.event_resolved.connect(_on_event_resolved)


## Centers the panel on the screen and lays the texts out above the options.
## Done in code (as well as in ui.tscn) so it stays centered even if the scene
## layout is changed or reset in the editor.
func _setup_panel_layout() -> void:
	# Anchor to the screen center and grow equally in every direction, so the
	# panel stays centered whatever its content size is.
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size.x = PANEL_WIDTH

	# Title and description on top, centered and wrapped to the panel width.
	for label in [title_label, description_label]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_container.alignment = BoxContainer.ALIGNMENT_CENTER


func _on_event_available(event_id: String) -> void:
	_event_id = event_id
	if AUTO_OPEN:
		_on_alert_pressed()
	else:
		alert_button.show()


func _on_alert_pressed() -> void:
	alert_button.hide()
	SignalManager.event_open_requested.emit()

	var info: Dictionary = EventsData.DATA[_event_id]
	title_label.text = info["title"]
	description_label.text = info["description"]

	_clear_options()
	var options: Array = info["options"]
	for i in options.size():
		var option: Dictionary = options[i]
		var button := Button.new()
		button.text = option["text"]
		# Options sit side by side, share the width equally and wrap long text.
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = OPTION_MIN_SIZE
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not Inventory.can_afford(option["requires"])
		button.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(button)
	panel.show()


func _on_option_pressed(index: int) -> void:
	_clear_options()  # Prevents a double click from choosing twice.
	SignalManager.event_option_chosen.emit(index)


func _on_event_resolved(result_text: String) -> void:
	description_label.text = result_text
	var ok := Button.new()
	ok.text = "Accept"
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 50)
	ok.pressed.connect(_on_ok_pressed)
	options_container.add_child(ok)


func _on_ok_pressed() -> void:
	panel.hide()
	SignalManager.event_dismissed.emit()


func _clear_options() -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

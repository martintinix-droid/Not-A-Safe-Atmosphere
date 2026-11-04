extends Control
## Event HUD: corner alert button, then a panel with the description and the
## options (built from EventsData), then the result text with an OK button.
## Runs while the game is paused (process_mode = Always).

@onready var alert_button: Button = %AlertButton
@onready var panel: PanelContainer = %Panel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var options_container: VBoxContainer = %OptionsContainer

var _event_id := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't swallow clicks meant for the game.
	alert_button.hide()
	panel.hide()

	alert_button.pressed.connect(_on_alert_pressed)
	SignalManager.event_available.connect(_on_event_available)
	SignalManager.event_resolved.connect(_on_event_resolved)


func _on_event_available(event_id: String) -> void:
	_event_id = event_id
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
	ok.pressed.connect(_on_ok_pressed)
	options_container.add_child(ok)


func _on_ok_pressed() -> void:
	panel.hide()
	SignalManager.event_dismissed.emit()


func _clear_options() -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()

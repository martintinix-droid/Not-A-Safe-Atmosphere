extends CanvasLayer
## "You Win!" / "You Lose!" screen. Built entirely in code (no scene needed):
## ui.gd adds it as a child at startup and it stays hidden until
## SignalManager.game_won (research bar hit 100%) or SignalManager.game_lost
## (the 100 second game_time timer in main.tscn ran out).
##
## When shown it PAUSES the whole game (rovers, generators, timers, events)
## and only this screen keeps running (process_mode = Always).
## "Play Again" restarts the entire game: resources back to the start, rovers
## removed, main scene reloaded (research bar, buildings, events all reset).

const TITLE_TEXT := "You Win!"
const MESSAGE_TEXT := "Thank you for playing our game!"
const LOSE_TITLE_TEXT := "You Lose!"
const LOSE_MESSAGE_TEXT := "Time ran out before the research was finished."
const BUTTON_TEXT := "Play Again"

const WIN_TITLE_COLOR := Color(1, 1, 1)
const LOSE_TITLE_COLOR := Color(1.0, 0.3, 0.3)

var _root: Control
var _title_label: Label
var _message_label: Label
var _play_again_button: Button


func _init() -> void:
	layer = 100  # Above the HUD and the event panel.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build()
	_root.hide()
	SignalManager.game_won.connect(_on_game_won)
	SignalManager.game_lost.connect(_on_game_lost)


## Creates: dark overlay -> centered panel -> title, message and button.
func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # Blocks clicks to the game behind.
	# Reuse the HUD theme so the fonts/buttons match the rest of the UI.
	var ui := get_parent() as Control
	if ui != null:
		_root.theme = ui.theme
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.1, 0.95)
	style.border_color = Color(0.85, 0.85, 0.9, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 36
	style.content_margin_bottom = 36
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	panel.add_child(box)

	_title_label = Label.new()
	_title_label.text = TITLE_TEXT
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 64)
	box.add_child(_title_label)

	_message_label = Label.new()
	_message_label.text = MESSAGE_TEXT
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 28)
	box.add_child(_message_label)

	_play_again_button = Button.new()
	_play_again_button.text = BUTTON_TEXT
	_play_again_button.custom_minimum_size = Vector2(240, 64)
	_play_again_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play_again_button.pressed.connect(_on_play_again_pressed)
	box.add_child(_play_again_button)


## Research hit 100%: freeze the game and show the "You Win!" screen.
func _on_game_won() -> void:
	_show_screen(TITLE_TEXT, MESSAGE_TEXT, WIN_TITLE_COLOR)


## The 100 second timer ran out: freeze the game and show "You Lose!".
func _on_game_lost() -> void:
	_show_screen(LOSE_TITLE_TEXT, LOSE_MESSAGE_TEXT, LOSE_TITLE_COLOR)


## Shared by win and lose. The first one to arrive wins: if the screen is
## already showing, any later signal is ignored.
func _show_screen(title: String, message: String, title_color: Color) -> void:
	if _root.visible:
		return
	_title_label.text = title
	_title_label.add_theme_color_override("font_color", title_color)
	_message_label.text = message
	get_tree().paused = true
	_root.show()
	_play_again_button.grab_focus()


## Restarts the entire game.
func _on_play_again_pressed() -> void:
	# Rovers are added to the root (not to the main scene), so reloading the
	# scene would leave them behind: remove them by hand.
	for child in get_tree().root.get_children():
		if child is OutpostRover:
			child.queue_free()

	Inventory.reset()               # Autoload: it survives a scene reload.
	get_tree().paused = false
	get_tree().reload_current_scene()
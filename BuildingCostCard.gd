class_name BuildingCostCard
extends PanelContainer
## Small card that lists what a building costs, one material per line:
##
##   Research Lab
##   [icon] Energy         100 / 40
##   [icon] Basalt Rock     12 / 25     <- red: not enough yet
##
## It is shown while the mouse is over a building button and sits just to the
## LEFT of the build panel, aligned with its top edge. The amounts update live
## with the Inventory. It never blocks the mouse.
##
## Usage (see ui.gd):
##   card.setup(font_size)
##   card.show_for(building_id, "Research Lab", build_panel)   # on mouse_entered
##   card.hide_card()                                           # on mouse_exited
##   BuildingCostCard.mark_button(button, can_afford)           # red text on the button

## Same red as the numbers on the production popups.
const COLOR_MISSING := Color(1.0, 0.35, 0.35)
## Space between the card and the build panel.
const GAP := 12.0
## Button colors that are overridden to show "can't afford" in every state.
const BUTTON_FONT_COLORS: Array[String] = [
	"font_color", "font_hover_color", "font_pressed_color",
	"font_hover_pressed_color", "font_focus_color", "font_disabled_color",
]

var _font_size := 16
var _title: Label
var _grid: GridContainer
## resource id -> amount needed, for the building being shown.
var _cost: Dictionary = {}
## resource id -> Label with "have / need".
var _amount_labels := {}
## The build panel the card is attached to (to the left of it).
var _panel: Control


## Red text on a building button while the player cannot pay for it. Removes the
## override when they can, so the theme's own colors come back.
static func mark_button(button: Button, can_afford: bool) -> void:
	for color_name in BUTTON_FONT_COLORS:
		if can_afford:
			button.remove_theme_color_override(color_name)
		else:
			button.add_theme_color_override(color_name, COLOR_MISSING)


## `font_size`: text size of the card (the build buttons' size is a good choice).
## The colors and the background come from the UI theme this node inherits.
func setup(font_size: int) -> void:
	_font_size = font_size
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never steal the hover from the buttons.

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_title = Label.new()
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("font_size", font_size)
	box.add_child(_title)

	_grid = GridContainer.new()
	_grid.columns = 3  # icon | name | have / need
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid.add_theme_constant_override("h_separation", roundi(font_size * 0.6))
	_grid.add_theme_constant_override("v_separation", roundi(font_size * 0.25))
	box.add_child(_grid)

	Inventory.changed.connect(_on_inventory_changed)


## Shows the cost of `building_id` next to `panel` (the build panel).
func show_for(building_id: String, title: String, panel: Control) -> void:
	if not Buildings.DATA.has(building_id):
		return
	_panel = panel
	_cost = Buildings.DATA[building_id]["materials"]
	_title.text = title
	_rebuild_rows()
	visible = true
	_reposition()


func hide_card() -> void:
	visible = false


func _rebuild_rows() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_amount_labels.clear()

	for id in _cost:
		var icon_texture := Resources.load_icon(id)
		if icon_texture != null:
			var icon := TextureRect.new()
			icon.texture = icon_texture
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2.ONE * _font_size * 1.2
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			_grid.add_child(icon)
		else:
			_grid.add_child(Control.new())  # Keeps the 3 columns aligned.

		var name_label := _make_label(Resources.display_name(id))
		_grid.add_child(name_label)

		var amount_label := _make_label("")
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_grid.add_child(amount_label)
		_amount_labels[id] = amount_label
	_refresh_amounts()


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", _font_size)
	return label


## "have / need", red while there is not enough.
func _refresh_amounts() -> void:
	for id in _cost:
		var label: Label = _amount_labels[id]
		var have := Inventory.get_amount(id)
		label.text = "%d / %d" % [have, _cost[id]]
		if have >= _cost[id]:
			label.remove_theme_color_override("font_color")
		else:
			label.add_theme_color_override("font_color", COLOR_MISSING)


## Left of the panel, top edges aligned. The right edge stays put if the card
## grows (e.g. an amount going from 99 to 100).
func _reposition() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	size = get_combined_minimum_size()
	global_position = Vector2(maxf(_panel.global_position.x - size.x - GAP, 0.0), _panel.global_position.y)


func _on_inventory_changed(id: String, _amount: int) -> void:
	if visible and _amount_labels.has(id):
		_refresh_amounts()
		_reposition()

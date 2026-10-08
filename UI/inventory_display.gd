extends GridContainer
## Resource grid: one slot per resource, showing its icon with the amount in
## the bottom-right corner. It builds itself from Inventory: the slot for each
## id is created the first time that id appears.
##
## The number of columns is set in the inspector (the "Columns" property).

## Resource id -> icon path. If the id is missing or the file does not exist,
## the slot is shown without an icon (only the amount).
## NOTE: these are AI-generated placeholder icons; replace them before release.
const ICON_PATHS := {
	"energy": "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/thunder.jpg",
	"water": "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/water.png",
	"mineral 1": "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/mineral1.jpg",
	"mineral 2": "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/mineral2.jpg",
	"rock 1": "res://AI place holders (DO NOT IMPLEMENT FOR FINAL)/Items/rock1.jpg",
}

## Resource id -> name shown in the tooltip. If missing, the id itself is used.
const NAMES := {
	"energy": "Energy",
	"water": "Water",
	"mineral 1": "Mineral 1",
	"mineral 2": "Mineral 2",
	"rock 1": "Rock 1",
}

@export var slot_size := Vector2(100, 100)

## Resource id -> Label showing that slot's amount.
var _labels := {}


func _ready() -> void:
	# The gaps between slots must not swallow the clicks main.gd needs.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Build a slot for every resource that already exists, then keep them updated.
	for id in Inventory.get_ids():
		_refresh(id, Inventory.get_amount(id))
	Inventory.changed.connect(_refresh)


## Shows `amount` for `id`, creating its slot the first time it is seen.
## Used both for the initial fill and as the Inventory.changed callback.
func _refresh(id: String, amount: int) -> void:
	if not _labels.has(id):
		_labels[id] = _create_slot(id)
	_labels[id].text = str(amount)


## Creates the resource's TextureRect with its amount Label and returns the Label.
func _create_slot(id: String) -> Label:
	var slot := TextureRect.new()
	slot.custom_minimum_size = slot_size
	slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.texture = _load_icon(id)
	slot.tooltip_text = NAMES.get(id, id)
	# STOP: without it the tooltip does not appear, and as a side effect a click
	# on the icon is not forwarded to the world (no rover is sent by clicking the UI).
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(slot)

	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	slot.add_child(label)
	# Fills the whole slot; with the alignment above, the text ends up in the
	# bottom-right corner.
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 2)
	return label


## Loads the icon for `id`, or returns null if there is none (or the file is missing).
func _load_icon(id: String) -> Texture2D:
	var path: String = ICON_PATHS.get(id, "")
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

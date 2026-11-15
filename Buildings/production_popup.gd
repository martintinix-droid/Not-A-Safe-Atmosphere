class_name ProductionPopup
extends HBoxContainer
## Floating notice that a generator shows on every production tick: a row of
## "+N [icon]" for what it produced and "-N [icon]" in red for what it consumed.
## It rises for DURATION seconds while fading out, then frees itself.
##
## It is added to the SOURCE'S PARENT, not to the source: that way it does not
## inherit the building's scale (the font size is always in world pixels) nor its
## tint (grey when disabled, blue under construction...).
##
## Usage (see generator.gd):
##   ProductionPopup.spawn(self, [{"id": Resources.WATER, "amount": -1}], popup_theme, popup_font_size)

const GAIN_COLOR := Color.WHITE
const LOSS_COLOR := Color(1.0, 0.25, 0.25)
const OUTLINE_COLOR := Color.BLACK
## Seconds it takes to rise and fade out.
const DURATION := 1.0
## Automatic font size (when font_size is 0): this fraction of the sprite's height.
const AUTO_FONT_FRACTION := 0.08
## How far it rises, in font sizes.
const RISE_IN_FONT_SIZES := 1.5
## Drawn above buildings and rovers.
const Z_INDEX := 100


## Shows a popup above `source` (a Sprite2D that is inside the scene tree).
## `entries`: Array of {"id": resource id, "amount": int}; positive = produced,
## negative = consumed (red). Zero amounts are skipped.
## `font_size` 0 = automatic (see AUTO_FONT_FRACTION). `theme` may be null.
static func spawn(source: Sprite2D, entries: Array, theme: Theme = null, font_size: int = 0) -> void:
	var parent := source.get_parent()
	if parent == null:
		return
	var visible_entries := entries.filter(func(e): return e["amount"] != 0)
	if visible_entries.is_empty():
		return

	var rect := source.get_rect()  # Local rect, already includes `centered` and `offset`.
	if font_size <= 0:
		var world_height := rect.size.y * absf(source.global_scale.y)
		font_size = maxi(roundi(world_height * AUTO_FONT_FRACTION), 16)

	var popup := ProductionPopup.new()
	popup._build(visible_entries, theme, font_size)
	parent.add_child(popup)

	# Bottom-centre of the popup rests just above the top-centre of the sprite.
	var top_centre := source.to_global(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y))
	var popup_size := popup.get_combined_minimum_size()
	popup.size = popup_size
	popup.global_position = top_centre - Vector2(popup_size.x * 0.5, popup_size.y + font_size * 0.3)
	popup._animate(font_size)


func _build(entries: Array, theme_to_use: Theme, font_size: int) -> void:
	theme = theme_to_use
	z_index = Z_INDEX
	z_as_relative = false
	# Never swallow clicks meant for the map while it is visible.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", roundi(font_size * 0.8))

	for entry in entries:
		var amount: int = entry["amount"]
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", roundi(font_size * 0.15))

		var label := Label.new()
		label.text = "%+d" % amount  # "+2" / "-1"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", GAIN_COLOR if amount > 0 else LOSS_COLOR)
		label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
		label.add_theme_constant_override("outline_size", roundi(font_size * 0.15))
		row.add_child(label)

		var icon_texture := Resources.load_icon(entry["id"])
		if icon_texture != null:
			var icon := TextureRect.new()
			icon.texture = icon_texture
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(font_size, font_size)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		add_child(row)


func _animate(font_size: int) -> void:
	# The tween belongs to this node, so it pauses with the game (events) and resumes.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - font_size * RISE_IN_FONT_SIZES, DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, DURATION) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)

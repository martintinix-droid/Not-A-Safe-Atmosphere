extends Node2D
## Camera controller: pans while the "panning" action is held and zooms toward
## the mouse cursor. Panning moves this node, so the Camera2D must follow it
## (e.g. be its child).
##
## The camera is kept inside the background map: it can't pan past the map's
## edges and can't zoom out far enough to show the empty (grey) area around it.

const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
## How much the zoom changes per zoom_in / zoom_out input.
const ZOOM_STEP := 0.25
## Largest size the game window can have (in pixels).
const MAX_WINDOW_SIZE := Vector2i(1920, 1080)
## The background Sprite2D joins this group (see the "map" node in main.tscn).
const MAP_GROUP := "map_bounds"

@onready var camera_2d: Camera2D = %Camera2D

## True while the panning action is held down.
var is_panning := false

## World-space rectangle covered by the background map. Empty (size 0) if the
## scene has no map, in which case no limits are applied.
var _map_rect := Rect2()


func _ready() -> void:
	_limit_window_size()
	_find_map_rect()
	# The visible area changes when the window is resized, so re-apply the limits.
	get_viewport().size_changed.connect(_apply_limits)
	_apply_limits()


## Caps the game window at MAX_WINDOW_SIZE: it can't be resized or maximized
## past it, and if it starts larger than that it is shrunk to fit.
func _limit_window_size() -> void:
	var window := get_window()
	window.max_size = MAX_WINDOW_SIZE
	window.size = window.size.min(MAX_WINDOW_SIZE)


## Reads the world-space bounds of the background sprite (in the "map_bounds"
## group), taking its position, texture size and scale into account.
func _find_map_rect() -> void:
	var map := get_tree().get_first_node_in_group(MAP_GROUP) as Sprite2D
	if map == null or map.texture == null:
		push_warning("CameraManager: no Sprite2D in group '%s'; map limits disabled." % MAP_GROUP)
		return
	var local_rect := map.get_rect()
	var top_left := map.to_global(local_rect.position)
	var bottom_right := map.to_global(local_rect.end)
	_map_rect = Rect2(top_left, bottom_right - top_left).abs()


func _unhandled_input(event: InputEvent) -> void:
	# Pan: drag the camera while panning is active.
	# Dividing by the zoom converts screen pixels to world units.
	if event is InputEventMouseMotion and is_panning:
		global_position -= event.relative / camera_2d.zoom
		_clamp_to_map()

	# is_action() is true for both press and release, so is_panning follows
	# whether the action is currently held.
	if event.is_action("panning"):
		is_panning = event.is_action_pressed("panning")

	# Zoom
	if event.is_action_pressed("zoom_in"):
		_zoom_at_mouse(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_zoom_at_mouse(-ZOOM_STEP)


## Changes the zoom by `delta` (clamped to _get_min_zoom()..ZOOM_MAX) while
## keeping the world point under the mouse in the same screen position.
func _zoom_at_mouse(delta: float) -> void:
	var old_zoom := camera_2d.zoom
	var new_value := clampf(old_zoom.x + delta, _get_min_zoom(), ZOOM_MAX)

	# Already at the zoom limit: nothing to do.
	if is_equal_approx(new_value, old_zoom.x):
		return

	var new_zoom := Vector2(new_value, new_value)

	# World point under the mouse BEFORE changing the zoom.
	var mouse_world := get_global_mouse_position()

	camera_2d.zoom = new_zoom

	# Move the camera so that same world point stays under the mouse.
	global_position = mouse_world - (mouse_world - global_position) * (old_zoom / new_zoom)
	_clamp_to_map()


# --- Map limits ---

## Smallest zoom allowed: ZOOM_MIN, or higher if needed so the visible area
## never becomes larger than the map (which would show the grey background).
func _get_min_zoom() -> float:
	if _map_rect.size == Vector2.ZERO:
		return ZOOM_MIN
	var view_size := get_viewport_rect().size
	var fit_zoom := maxf(view_size.x / _map_rect.size.x, view_size.y / _map_rect.size.y)
	return maxf(ZOOM_MIN, fit_zoom)


## Re-applies the zoom and position limits (also used after the window is resized).
func _apply_limits() -> void:
	var min_zoom := _get_min_zoom()
	if camera_2d.zoom.x < min_zoom:
		camera_2d.zoom = Vector2(min_zoom, min_zoom)
	_clamp_to_map()


## Keeps the whole visible area inside the map. The camera is centered on this
## node, so its center can move within the map shrunk by half the visible size.
func _clamp_to_map() -> void:
	if _map_rect.size == Vector2.ZERO:
		return
		
	var half_view := get_viewport_rect().size / (camera_2d.zoom * 2.0)
	var center := _map_rect.get_center()
	
	# Eje X
	var min_pos_x := _map_rect.position.x + half_view.x
	var max_pos_x := _map_rect.end.x - half_view.x
	if min_pos_x <= max_pos_x:
		global_position.x = clampf(global_position.x, min_pos_x, max_pos_x)
	else:
		global_position.x = center.x

	# Eje Y
	var min_pos_y := _map_rect.position.y + half_view.y
	var max_pos_y := _map_rect.end.y - half_view.y
	if min_pos_y <= max_pos_y:
		global_position.y = clampf(global_position.y, min_pos_y, max_pos_y)
	else:
		global_position.y = center.y

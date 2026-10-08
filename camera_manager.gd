extends Node2D
## Camera controller: pans while the "panning" action is held and zooms toward
## the mouse cursor. Panning moves this node, so the Camera2D must follow it
## (e.g. be its child).

const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
## How much the zoom changes per zoom_in / zoom_out input.
const ZOOM_STEP := 0.25

@onready var camera_2d: Camera2D = %Camera2D

## True while the panning action is held down.
var is_panning := false


func _unhandled_input(event: InputEvent) -> void:
	# Pan: drag the camera while panning is active.
	# Dividing by the zoom converts screen pixels to world units.
	if event is InputEventMouseMotion and is_panning:
		global_position -= event.relative / camera_2d.zoom

	# is_action() is true for both press and release, so is_panning follows
	# whether the action is currently held.
	if event.is_action("panning"):
		is_panning = event.is_action_pressed("panning")

	# Zoom
	if event.is_action_pressed("zoom_in"):
		_zoom_at_mouse(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_zoom_at_mouse(-ZOOM_STEP)


## Changes the zoom by `delta` (clamped to ZOOM_MIN..ZOOM_MAX) while keeping
## the world point under the mouse in the same screen position.
func _zoom_at_mouse(delta: float) -> void:
	var old_zoom := camera_2d.zoom
	var new_value := clampf(old_zoom.x + delta, ZOOM_MIN, ZOOM_MAX)

	# Already at the zoom limit: nothing to do.
	if is_equal_approx(new_value, old_zoom.x):
		return

	var new_zoom := Vector2(new_value, new_value)

	# World point under the mouse BEFORE changing the zoom.
	var mouse_world := get_global_mouse_position()

	camera_2d.zoom = new_zoom

	# Move the camera so that same world point stays under the mouse.
	global_position = mouse_world - (mouse_world - global_position) * (old_zoom / new_zoom)

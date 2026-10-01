extends Node2D

@onready var camera_2d: Camera2D = %Camera2D

const ZOOM_MIN := 0.25
const ZOOM_MAX := 4.0
const ZOOM_STEP := 0.25

var is_panning := false

func _unhandled_input(event: InputEvent) -> void:
	# Paneo
	if event is InputEventMouseMotion and is_panning:
		global_position -= event.relative / camera_2d.zoom

	if event.is_action("panning"):
		is_panning = event.is_action_pressed("panning")

	# Zoom
	if event.is_action_pressed("zoom_in"):
		_zoom_at_mouse(ZOOM_STEP)
	elif event.is_action_pressed("zoom_out"):
		_zoom_at_mouse(-ZOOM_STEP)


func _zoom_at_mouse(delta: float) -> void:
	var old_zoom := camera_2d.zoom
	var new_value := clampf(old_zoom.x + delta, ZOOM_MIN, ZOOM_MAX)

	if is_equal_approx(new_value, old_zoom.x):
		return

	var new_zoom := Vector2(new_value, new_value)

	# Punto del mundo bajo el mouse ANTES de cambiar el zoom
	var mouse_world := get_global_mouse_position()

	camera_2d.zoom = new_zoom

	# Mover la cámara para que ese mismo punto siga bajo el mouse
	global_position = mouse_world - (mouse_world - global_position) * (old_zoom / new_zoom)

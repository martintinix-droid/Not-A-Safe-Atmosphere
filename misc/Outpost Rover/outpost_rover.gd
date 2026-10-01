class_name OutpostRover
extends CharacterBody2D
## Rover independiente: sale de la base hacia target_position, interactúa con
## target (si hay), y vuelve a la base; al llegar, despawnea. No sabe cuántos
## rovers hay activos: eso lo maneja base.gd escuchando "returned_to_base".
##
## Interfaz de un interactuable (cualquier nodo al que el rover pueda ir):
##   func request_rover() -> bool        - base.gd la llama al clickearlo; true = "mándame un rover"
##                                         (debe devolver true una sola vez por rover necesitado)
##   func start_rover_interaction()      - la llama el rover al llegar
##   signal rover_interaction_finished   - el rover espera esto para volver
## Si target es null (click al suelo), el rover solo va y vuelve.

signal returned_to_base  # justo antes de destruirse, para que la base libere el cupo

enum State { GOING_TO_TARGET, INTERACTING_WITH_TARGET, RETURNING_TO_BASE }

## Distancia a la que se considera que llegó al destino.
const ARRIVAL_DISTANCE := 3.0

var max_speed := 300.0
var acceleration := 10.0
var friction := 40.0
var stopping_distance := 50.0

var target: Node             # interactuable con el que interactúa al llegar (puede ser null)
var target_position: Vector2 # a dónde va primero
var base_position: Vector2   # a dónde vuelve después

var current_speed := 0.0
var _state: State = State.GOING_TO_TARGET


func _physics_process(_delta: float) -> void:
	# Mientras interactúa, el rover se queda quieto hasta que el target avise que terminó.
	if _state == State.INTERACTING_WITH_TARGET:
		return

	var destination := target_position if _state == State.GOING_TO_TARGET else base_position
	var distance := position.distance_to(destination)

	if distance > ARRIVAL_DISTANCE:
		_move_towards(destination, distance)
	else:
		current_speed = 0.0

	# Llegó cuando se detuvo por completo.
	if current_speed == 0.0:
		_on_reached_destination()


func _move_towards(destination: Vector2, distance: float) -> void:
	if distance > stopping_distance:
		current_speed += acceleration
	else:
		current_speed = maxf(current_speed - friction, 0.0)
	current_speed = minf(current_speed, max_speed)

	velocity = (destination - position).normalized() * current_speed
	move_and_slide()


func _on_reached_destination() -> void:
	match _state:
		State.GOING_TO_TARGET:
			_start_interaction()
		State.RETURNING_TO_BASE:
			returned_to_base.emit()
			queue_free()


func _start_interaction() -> void:
	_state = State.INTERACTING_WITH_TARGET

	if is_instance_valid(target) and target.has_method("start_rover_interaction"):
		# Se conecta ANTES de empezar, por si el target termina al instante.
		target.rover_interaction_finished.connect(_finish_interaction, CONNECT_ONE_SHOT)
		target.start_rover_interaction()
	else:
		_finish_interaction()


func _finish_interaction() -> void:
	_state = State.RETURNING_TO_BASE

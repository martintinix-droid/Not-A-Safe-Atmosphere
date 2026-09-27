extends CharacterBody2D
## Rover independiente: sale de la base hacia target_position, y cuando
## llega, da la vuelta solo hacia base_position; al llegar ahí, despawnea.
## No sabe nada de otros rovers ni de cuántos hay activos - eso lo maneja
## quien lo crea (base.gd) escuchando "returned_to_base".

signal returned_to_base  # emitida justo antes de destruirse, para que quien lo creó libere el cupo

enum State { GOING_TO_TARGET, RETURNING_TO_BASE }

var max_speed := 300.0
var acceleration := 10.0
var friction := 40.0
var stopping_distance := 50.0

var target_position: Vector2  # a dónde va primero (el punto clickeado)
var base_position: Vector2    # a dónde vuelve después

var current_speed := 0.0
var _state: State = State.GOING_TO_TARGET

func _physics_process(_delta: float) -> void:
	var destination := target_position if _state == State.GOING_TO_TARGET else base_position
	var distance := position.distance_to(destination)

	if distance > 3.0:
		var direction := (destination - position).normalized()
		if distance > stopping_distance:
			current_speed += acceleration
		else:
			current_speed -= friction
			current_speed = max(current_speed, 0.0)
		current_speed = min(current_speed, max_speed)
		velocity = direction * current_speed
		move_and_slide()
	if current_speed==0:
		_on_reached_destination()

func _on_reached_destination() -> void:
	match _state:
		State.GOING_TO_TARGET:
			# Llegó al punto clickeado: ahora el destino pasa a ser la base.
			_state = State.RETURNING_TO_BASE
		State.RETURNING_TO_BASE:
			# Llegó de vuelta a la base: avisa y desaparece.
			returned_to_base.emit()
			queue_free()

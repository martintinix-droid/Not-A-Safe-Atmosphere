class_name OutpostRover
extends CharacterBody2D
## Independent rover: leaves the base for target_position, interacts with
## target (if any), returns to the base and despawns on arrival. It does not
## know how many rovers are active: base.gd tracks that by listening to
## "returned_to_base".
##
## Interactable interface (any node the rover can be sent to):
##   func request_rover() -> bool        - base.gd calls it when the node is clicked;
##                                         true = "send me a rover" (must return true
##                                         only once per rover needed)
##   func start_rover_interaction()      - called by the rover when it arrives
##   signal rover_interaction_finished   - the rover waits for this before heading back
## If target is null (ground click), the rover just goes there and comes back.

## Emitted right before the rover frees itself, so the base can release its slot.
signal returned_to_base

## Trip phases, in order. The rover despawns after RETURNING_TO_BASE.
enum State { GOING_TO_TARGET, INTERACTING_WITH_TARGET, RETURNING_TO_BASE }

## Distance at which the rover counts as having reached its destination.
const ARRIVAL_DISTANCE := 3.0

# --- Movement tuning ---
var max_speed := 300.0
var acceleration := 10.0       # Speed gained per physics frame while far from the destination.
var friction := 40.0           # Speed lost per physics frame while braking.
var stopping_distance := 50.0  # Starts braking when closer than this to the destination.

# --- Trip data (set by base.gd right after instantiating the rover) ---
var target: Node              # Interactable to interact with on arrival (may be null).
var target_position: Vector2  # Where the rover goes first.
var base_position: Vector2    # Where the rover returns to afterwards.

# --- Runtime state ---
var current_speed := 0.0
var _state: State = State.GOING_TO_TARGET


func _physics_process(_delta: float) -> void:
	# While interacting, the rover stays still until the target says it is done.
	if _state == State.INTERACTING_WITH_TARGET:
		return

	var destination := target_position if _state == State.GOING_TO_TARGET else base_position
	var distance := position.distance_to(destination)

	if distance > ARRIVAL_DISTANCE:
		_move_towards(destination, distance)
	else:
		current_speed = 0.0

	# Arrived once it has come to a complete stop.
	if current_speed == 0.0:
		_on_reached_destination()


## Accelerates towards the destination, braking when it gets close.
func _move_towards(destination: Vector2, distance: float) -> void:
	if distance > stopping_distance:
		current_speed += acceleration
	else:
		current_speed = maxf(current_speed - friction, 0.0)
	current_speed = minf(current_speed, max_speed)

	velocity = (destination - position).normalized() * current_speed
	move_and_slide()


## Moves the rover to the next phase of its trip.
func _on_reached_destination() -> void:
	match _state:
		State.GOING_TO_TARGET:
			_start_interaction()
		State.RETURNING_TO_BASE:
			returned_to_base.emit()
			queue_free()


## Starts interacting with the target (if it supports it) and waits for it to
## finish. With no valid target, it skips straight to heading back.
func _start_interaction() -> void:
	_state = State.INTERACTING_WITH_TARGET

	if is_instance_valid(target) and target.has_method("start_rover_interaction"):
		# Connect BEFORE starting, in case the target finishes instantly.
		target.rover_interaction_finished.connect(_finish_interaction, CONNECT_ONE_SHOT)
		target.start_rover_interaction()
	else:
		_finish_interaction()


func _finish_interaction() -> void:
	_state = State.RETURNING_TO_BASE

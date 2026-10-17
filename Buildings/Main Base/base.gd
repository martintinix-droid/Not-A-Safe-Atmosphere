extends Sprite2D
## Main base: dispatches rovers to a clicked ground point or to an interactable
## that asks for one (up to MAX_ROVERS active at the same time).
##
## It does not know what the rover does at its destination or when it finishes:
## it only counts how many are alive to know whether it can send another one.
##
## An interactable "asks for a rover" by implementing request_rover(); the rest
## of the interface (start_rover_interaction, rover_interaction_finished) is
## used by the rover itself. See outpost_rover.gd.

## Maximum number of rovers active at the same time.
const MAX_ROVERS := 3
const ROVER_SCENE := preload("uid://np2aojdufexy")

## Rovers currently out (going, interacting or returning).
var _active_rovers := 0
## Interactables that asked for a rover when none was available (FIFO queue).
var _pending_targets: Array = []


func _ready() -> void:
	SignalManager.ground_clicked.connect(_on_ground_clicked)
	SignalManager.interactable_clicked.connect(_on_interactable_clicked)


# --- Click handling ---

func _on_ground_clicked(click_position: Vector2) -> void:
	# Ground clicks with no free rover are discarded (not queued).
	if _has_free_rover():
		_spawn_rover(click_position)


func _on_interactable_clicked(target: Node) -> void:
	# request_rover() is what decides (and remembers) whether the target wants
	# a rover, so the same target is never queued or served twice by re-clicks.
	if not target.has_method("request_rover") or not target.request_rover():
		return

	if _has_free_rover():
		_spawn_rover(target.global_position, target)
	else:
		_pending_targets.append(target)


# --- Rover management ---

func _has_free_rover() -> bool:
	return _active_rovers < MAX_ROVERS


## Sends a rover to `destination`. If `target` is given, the rover interacts
## with it on arrival.
func _spawn_rover(destination: Vector2, target: Node = null) -> void:
	var rover: OutpostRover = ROVER_SCENE.instantiate()
	rover.position = global_position
	rover.base_position = global_position
	rover.target_position = destination
	rover.target = target

	# CONNECT_ONE_SHOT: when the rover comes back and frees itself, the base
	# releases its slot. There is no need to keep a list of rovers.
	rover.returned_to_base.connect(_on_rover_returned, CONNECT_ONE_SHOT)

	_active_rovers += 1
	get_tree().root.add_child(rover)


## A rover is back: free its slot and serve the queue.
func _on_rover_returned() -> void:
	_active_rovers -= 1
	_dispatch_pending()


## Sends rovers to the queued interactables while there are free slots.
func _dispatch_pending() -> void:
	while not _pending_targets.is_empty() and _has_free_rover():
		var target = _pending_targets.pop_front()
		# The queued target may have been freed in the meantime; skip it if so.
		if is_instance_valid(target):
			_spawn_rover(target.global_position, target)

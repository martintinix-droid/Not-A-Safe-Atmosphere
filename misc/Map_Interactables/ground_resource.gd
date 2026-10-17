extends Sprite2D
## Gatherable resource placed on the map (e.g. a Basalt rock). The player
## clicks it, a rover is sent over, and after `interaction_time` seconds the
## rock gives one unit of `resource_id` to the Inventory and removes itself.
##
## It implements the interactable interface that base.gd and outpost_rover.gd
## expect (see outpost_rover.gd): request_rover(), start_rover_interaction()
## and the rover_interaction_finished signal.
##
## Requirements for main.gd to detect clicks on it: it must be a Sprite2D and
## belong to the "interactables" group (done in _ready).
## The scene also needs a Timer with a unique name (%Timer).

## Gathering finished: the rover waits for this before heading back to the base.
signal rover_interaction_finished
## Emitted by main.gd when this node is clicked.
signal clicked

## Id of the resource it gives (see Inventory). Set per scene.
@export var resource_id := "Basalt rock"
## Seconds the rover spends gathering once it arrives.
@export var interaction_time := 5

@onready var timer: Timer = %Timer  # Gathering countdown.

## Already asked for a rover; avoids sending a second one on every re-click.
var _rover_requested := false


func _ready() -> void:
	# "interactables": main.gd looks them up for the click hit-test.
	add_to_group("interactables")
	timer.timeout.connect(_on_interaction_finished)
	clicked.connect(_on_clicked)


# --- Rover interface ---

## base.gd calls it when this node is clicked. Returns true only the first
## time, so the same resource never gets more than one rover.
func request_rover() -> bool:
	if _rover_requested:
		return false
	_rover_requested = true
	return true


## The rover arrived: start gathering.
func start_rover_interaction() -> void:
	timer.start(interaction_time)


# --- Callbacks ---

func _on_clicked() -> void:
	# TODO: give some visual feedback that it was clicked (e.g. make it wiggle).
	pass


## Gathering finished: give the resource, let the rover head back, and remove
## this node from the map.
func _on_interaction_finished() -> void:
	Inventory.add(resource_id)
	rover_interaction_finished.emit()
	queue_free()

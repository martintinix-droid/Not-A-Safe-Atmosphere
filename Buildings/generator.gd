extends Sprite2D
## Resource generator building (energy, water, minerals...). Which resource it
## produces is chosen with `resource_id` in each scene's inspector, so this one
## script serves every generator.
##
## Life cycle:
##   1. Ghost: follows the mouse; green/red depending on whether the spot is valid.
##   2. Valid click: it is placed, under construction (blue), and requests a rover.
##   3. When the rover arrives, building_timer starts. When it finishes, the
##      building becomes active and adds its resource to the Inventory every
##      time `timer` times out.
##
## The click is NOT detected here: main.gd decides what was clicked and emits
## "clicked". Rover interface (see outpost_rover.gd): request_rover(),
## start_rover_interaction() and rover_interaction_finished.

## The ghost was placed.
signal state_changed
## Emitted by main.gd when this building is the one that was clicked.
signal clicked
## Construction finished: the rover can head back.
signal rover_interaction_finished

const COLOR_GHOST_VALID := Color(0, 1, 0, 0.5)
const COLOR_GHOST_INVALID := Color(1, 0, 0, 0.5)
const COLOR_UNDER_CONSTRUCTION := Color(0, 0.5, 1, 0.5)
const COLOR_ACTIVE := Color(1, 1, 1, 1)

## Id of the resource it produces (see Inventory). Set per scene.
@export var resource_id := "energy"

@onready var building_timer: Timer = $building_timer  # Construction duration.
@onready var timer: Timer = %Timer                    # Production interval.
@onready var area_2d: Area2D = %Area2D                # Detects overlaps while placing.

var is_placing := true              # Ghost mode (not placed yet).
var is_under_construction := false  # Placed, waiting for / receiving the rover.
var overlap_count := 0              # Bodies/areas currently touching the Area2D.

# Construction duration in seconds. main.gd sets it from Buildings.DATA.
# If it is 0, the wait_time of building_timer in the scene is used instead.
var build_time := 0.0

var _rover_requested := false  # Already asked for its rover; avoids asking again on every re-click.

# Placeable only if nothing overlaps it. A counter (instead of a bool) avoids
# becoming "placeable" while ANOTHER object is still covering the spot.
var placeable: bool:
	get:
		return overlap_count == 0


func _ready() -> void:
	# "interactables": main.gd looks them up for the click hit-test.
	add_to_group("interactables")
	add_to_group("buildings")

	building_timer.timeout.connect(_on_construction_finished)
	timer.stop()  # Production only starts once construction finishes.
	timer.timeout.connect(_on_production_tick)

	state_changed.connect(_on_state_changed)
	clicked.connect(_on_clicked)
	modulate = COLOR_GHOST_VALID

	# Both "area" and "body" are listened to because we don't know whether the
	# colliding object is an Area2D or a physics body.
	area_2d.area_entered.connect(_on_object_entered)
	area_2d.body_entered.connect(_on_object_entered)
	area_2d.area_exited.connect(_on_object_exited)
	area_2d.body_exited.connect(_on_object_exited)


func _process(_delta: float) -> void:
	# Only runs while this is a ghost (see _on_clicked, which disables it).
	global_position = get_global_mouse_position()


# --- Rover interface ---

## base.gd calls it when the building is clicked. Returns true only the first
## time the building is under construction without an assigned rover.
func request_rover() -> bool:
	if not is_under_construction or _rover_requested:
		return false
	_rover_requested = true
	return true


## The rover arrived: construction starts.
func start_rover_interaction() -> void:
	if build_time > 0.0:
		building_timer.start(build_time)
	else:
		building_timer.start()


# --- Callbacks ---

## This building was clicked (main.gd emits "clicked").
func _on_clicked() -> void:
	# Only a ghost on a valid spot can be placed.
	if not (is_placing and placeable):
		return  # TODO: inspect an already placed building.

	is_placing = false
	set_process(false)  # No longer follows the mouse.
	state_changed.emit()
	is_under_construction = true


func _on_state_changed() -> void:
	modulate = COLOR_UNDER_CONSTRUCTION


func _on_construction_finished() -> void:
	is_under_construction = false
	timer.start()
	modulate = COLOR_ACTIVE
	rover_interaction_finished.emit()


## Production tick: adds one unit of this generator's resource to the Inventory.
func _on_production_tick() -> void:
	Inventory.add(resource_id)


func _on_object_entered(_object: Node) -> void:
	overlap_count += 1
	if is_placing:
		modulate = COLOR_GHOST_INVALID


func _on_object_exited(_object: Node) -> void:
	overlap_count = maxi(overlap_count - 1, 0)
	# Only turns green again once nothing is overlapping.
	if is_placing and placeable:
		modulate = COLOR_GHOST_VALID

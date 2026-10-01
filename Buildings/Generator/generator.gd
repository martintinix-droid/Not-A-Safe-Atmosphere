extends Sprite2D
## Generador de energía.
##
## Ciclo de vida:
##   1. Fantasma: sigue al mouse; verde/rojo según si el lugar es válido.
##   2. Click válido: queda colocado, en construcción (azul), y pide un rover.
##   3. Cuando el rover llega arranca building_timer. Al terminar, el edificio
##      queda activo y emite energía cada vez que `timer` termina.
##
## El click NO se detecta acá: main.gd decide qué fue clickeado y emite "clicked".
## Interfaz con el rover (ver outpost_rover.gd): request_rover(),
## start_rover_interaction() y rover_interaction_finished.

signal state_changed              # el fantasma se colocó
signal clicked                    # main.gd lo emite cuando este edificio es el clickeado
signal rover_interaction_finished # la construcción terminó: el rover puede volver

const COLOR_GHOST_VALID := Color(0, 1, 0, 0.5)
const COLOR_GHOST_INVALID := Color(1, 0, 0, 0.5)
const COLOR_UNDER_CONSTRUCTION := Color(0, 0.5, 1, 0.5)
const COLOR_ACTIVE := Color(1, 1, 1, 1)

@onready var building_timer: Timer = $building_timer  # duración de la construcción
@onready var timer: Timer = %Timer                    # intervalo de producción
@onready var area_2d: Area2D = %Area2D

var is_placing := true             # modo fantasma (sin colocar todavía)
var is_under_construction := false # colocado, esperando/recibiendo al rover
var overlap_count := 0             # cuerpos/áreas tocando el Area2D ahora mismo

# Duración de la construcción en segundos. main.gd lo setea desde BUILDINGS.
# Si es 0, se usa el wait_time de building_timer en la escena.
var build_time := 0.0

var _rover_requested := false  # ya pidió su rover; evita pedir otro en cada re-click

# Colocable solo si no hay nada encimado. Un contador (en vez de un bool)
# evita quedar "colocable" mientras OTRO objeto sigue tapando el lugar.
var placeable: bool:
	get:
		return overlap_count == 0


func _ready() -> void:
	# "interactables": main.gd los busca para el hit-test del click.
	add_to_group("interactables")
	add_to_group("buildings")

	building_timer.timeout.connect(_on_construction_finished)
	timer.stop()  # la producción arranca recién cuando termina la construcción
	timer.timeout.connect(_on_production_tick)

	state_changed.connect(_on_state_changed)
	clicked.connect(_on_clicked)
	modulate = COLOR_GHOST_VALID

	# Se escuchan "area" y "body" porque no sabemos si lo que colisiona es un
	# Area2D o un cuerpo físico.
	area_2d.area_entered.connect(_on_object_entered)
	area_2d.body_entered.connect(_on_object_entered)
	area_2d.area_exited.connect(_on_object_exited)
	area_2d.body_exited.connect(_on_object_exited)


func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()


# --- Interfaz con el rover ---

## base.gd la llama al clickear el edificio. Devuelve true solo la primera vez
## que el edificio está en construcción sin rover asignado.
func request_rover() -> bool:
	if not is_under_construction or _rover_requested:
		return false
	_rover_requested = true
	return true


## El rover llegó: arranca la construcción.
func start_rover_interaction() -> void:
	if build_time > 0.0:
		building_timer.start(build_time)
	else:
		building_timer.start()


# --- Callbacks ---

func _on_clicked() -> void:
	if not (is_placing and placeable):
		return  # TODO: inspeccionar el edificio ya colocado

	is_placing = false
	set_process(false)  # ya no sigue al mouse
	state_changed.emit()
	is_under_construction = true


func _on_state_changed() -> void:
	modulate = COLOR_UNDER_CONSTRUCTION


func _on_construction_finished() -> void:
	is_under_construction = false
	timer.start()
	modulate = COLOR_ACTIVE
	rover_interaction_finished.emit()


func _on_production_tick() -> void:
	SignalManager.energy_ready.emit()


func _on_object_entered(_object: Node) -> void:
	overlap_count += 1
	if is_placing:
		modulate = COLOR_GHOST_INVALID


func _on_object_exited(_object: Node) -> void:
	overlap_count = maxi(overlap_count - 1, 0)
	# Solo vuelve a verde si ya no queda nada encimado.
	if is_placing and placeable:
		modulate = COLOR_GHOST_VALID

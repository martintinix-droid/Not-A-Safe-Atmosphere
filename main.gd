extends Node2D
## Controlador principal del juego: escucha las señales globales de
## SignalManager, lleva la cuenta de la energía, instancia los edificios que
## pide la UI, y es el único que escucha el input de click del jugador.
##
## Centralizar el click acá (en vez de que cada edificio corra su propio
## _input) es lo que permite diferenciar "clickeaste un edificio" de
## "clickeaste el suelo" (para el rover con point-and-click) sin que los
## input handlers de cada sistema compitan entre sí.

var energy := 0
var water :=0
# Edificio que está actualmente en modo fantasma (is_placing == true), si
# hay alguno. Se usa para no dejar instanciar un segundo edificio mientras
# el primero todavía no se colocó, así no quedan dos superpuestos.
var _placing_building: Node = null

# Escena de cada tipo de edificio, indexada por nombre.
var buildings_preload := {
	"energy": preload("uid://b7ux8e48tnrv3"),
	"water":preload("uid://cv1m1r8gxkird")
}

# Info de cada edificio disponible. La posición de cada elemento en este
# array es el "index" que usa la UI (ver ui.gd) para pedir que se instancie.
var buildings_info: Array = [
	{"building": "energy", "cost": 10, "preload": buildings_preload["energy"]},
	{"building": "water", "cost": 5, "preload": buildings_preload["water"]}
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.energy_ready.connect(_on_energy_ready)
	SignalManager.water_ready.connect(_on_water_ready)
	SignalManager.spawn_building.connect(_on_spawn_building_ready)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		_handle_click(get_global_mouse_position())

## Único punto de entrada para "algo fue clickeado". Decide QUÉ fue
## clickeado y le pasa la posta al sistema correspondiente: si fue un
## edificio, le emite su señal "clicked" (la conecta él mismo a su propia
## lógica); si no, es terreno libre, que en el futuro va a ser lo que
## dispare el movimiento del rover.
func _handle_click(click_position: Vector2) -> void:
	var target_building := _find_clicked_building(click_position)
	if target_building != null:
		target_building.clicked.emit()
		return

	# No había ningún edificio bajo el click: acá es donde va a engancharse
	# el point-and-click del rover más adelante (por ejemplo, emitiendo
	SignalManager.ground_clicked.emit(click_position) 
	

## Busca, entre los edificios de la escena, cuál está bajo click_position,
## usando is_pixel_opaque (igual que hacía cada edificio antes en su propio
## _input) para que el click sea preciso al sprite y no a su bounding box.
func _find_clicked_building(click_position: Vector2) -> Node:
	# El edificio en modo fantasma (si hay uno) tiene prioridad: es el que
	# está siguiendo al mouse y el jugador espera clickearlo a él primero.
	if _placing_building != null and is_instance_valid(_placing_building):
		if _is_click_on_building(_placing_building, click_position):
			return _placing_building

	for building in get_tree().get_nodes_in_group("buildings"):
		if building == _placing_building:
			continue
		if _is_click_on_building(building, click_position):
			return building

	return null

func _is_click_on_building(building: Node, click_position: Vector2) -> bool:
	if not (building is Sprite2D):
		return false
	return building.is_pixel_opaque(building.to_local(click_position))

func _on_energy_ready() -> void:
	energy += 1

func _on_water_ready() ->void:
	water+=1

func _on_spawn_building_ready(index: int) -> void:
	# Si ya hay un edificio en modo fantasma (todavía no se colocó), no se
	# instancia uno nuevo: harían overlap entre ellos.
	if _placing_building != null and is_instance_valid(_placing_building) and _placing_building.is_placing:
		return

	var current_building = buildings_info[index]
	var new_building = current_building["preload"].instantiate()
	add_child(new_building)

	_placing_building = new_building
	# CONNECT_ONE_SHOT: una vez que se coloca (is_placing pasa a false y
	# emite state_changed), se libera el "candado" solo, sin tener que
	# desconectar la señal a mano.
	new_building.state_changed.connect(func() -> void:
		_placing_building = null
	, CONNECT_ONE_SHOT)

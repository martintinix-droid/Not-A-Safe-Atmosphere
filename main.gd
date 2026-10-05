extends Node2D
## Controlador principal del juego: lleva la cuenta de los recursos,
## instancia los edificios que pide la UI y es el único que escucha el click
## del jugador.
##
## Centralizar el click acá (en vez de que cada objeto corra su propio _input)
## permite diferenciar "clickeaste un interactuable" de "clickeaste el suelo"
## sin que los handlers de cada sistema compitan entre sí.

## Grupo al que se une todo nodo clickeable (ver generator.gd).
const INTERACTABLE_GROUP := "interactables"

## Catálogo de edificios construibles. La clave es el id que manda la UI en
## SignalManager.spawn_building. Para agregar un edificio nuevo: una entrada
## acá y un botón en ui.gd. ("build_time" en segundos; "cost" todavía no se usa.)
const RESOURCES_REQUIERMENTS :={
	"energy":{"mineral 1":3, "mineral 2": 4, "rock 1": 2},
	"water": {"mineral 1":3, "mineral 2": 4, "rock 1": 2}
}
const BUILDINGS := {
	"energy": {"scene": preload("uid://b7ux8e48tnrv3"), "materials": RESOURCES_REQUIERMENTS["energy"], "build_time": 6.0},
	"water": {"scene": preload("uid://cv1m1r8gxkird"), "materials": RESOURCES_REQUIERMENTS["water"], "build_time": 6.0},
}


var energy := 1110
var water := 1110
var mineral1:=10
var mineral2:=10
var rock1:=10

var CURRENT_MATERIALS :={
	"energy":energy,
	"water": water,
	"mineral 1":mineral1,
	"mineral 2" : mineral2,
	"rock 1" : rock1
	
}
# Edificio en modo fantasma (todavía sin colocar), si hay uno. Evita instanciar
# un segundo edificio mientras el primero no se colocó, y le da prioridad en el click.
var _placing_building: Node = null


func _ready() -> void:
	NodeRefs.main_ref = self
	SignalManager.energy_ready.connect(_on_energy_ready)
	SignalManager.water_ready.connect(_on_water_ready)
	SignalManager.spawn_building.connect(_on_spawn_building)


# _unhandled_input (no _input): si un Control de la UI (ej: un botón) consume el
# click, no llega acá y no se manda un rover al suelo que hay detrás.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		_handle_click(get_global_mouse_position())


## Único punto de entrada para "algo fue clickeado". Si hay un interactuable
## bajo el click, le emite su señal "clicked" y avisa a los demás sistemas
## (ej: la base, que decide si manda un rover). Si no, es terreno libre.
func _handle_click(click_position: Vector2) -> void:
	var target := _find_clicked_interactable(click_position)
	if target == null:
		SignalManager.ground_clicked.emit(click_position)
		return

	target.clicked.emit()
	SignalManager.interactable_clicked.emit(target)


## Busca qué interactuable está bajo click_position. El edificio fantasma
## (si hay uno) tiene prioridad: es el que sigue al mouse.
func _find_clicked_interactable(click_position: Vector2) -> Node:
	if is_instance_valid(_placing_building) and _is_click_on(_placing_building, click_position):
		return _placing_building

	for node in get_tree().get_nodes_in_group(INTERACTABLE_GROUP):
		if node != _placing_building and _is_click_on(node, click_position):
			return node

	return null


## El click es preciso al sprite (ignora píxeles transparentes), no a su bounding box.
## Por ahora solo se soportan interactuables que sean Sprite2D.
func _is_click_on(node: Node, click_position: Vector2) -> bool:
	var sprite := node as Sprite2D
	if sprite == null:
		return false
	return sprite.is_pixel_opaque(sprite.to_local(click_position))


func _on_spawn_building(building_id: String) -> void:
	# Si todavía hay un fantasma sin colocar, no se crea otro: se superpondrían.
	if is_instance_valid(_placing_building):
		return
	if not BUILDINGS.has(building_id):
		push_warning("Edificio desconocido: %s" % building_id)
		return
	
	var info: Dictionary = BUILDINGS[building_id]
	for mat in info["materials"]:
		if info["materials"][mat]>CURRENT_MATERIALS[mat]:
			#Logica futura para mostrar mensaje de materiales insuficientes
			print("not enough materials")
			return
		else:
			CURRENT_MATERIALS[mat]-=info["materials"][mat]
			
	var new_building: Node = info["scene"].instantiate()
	add_child(new_building)
	new_building.build_time = float(info["build_time"])
	_placing_building = new_building
	# CONNECT_ONE_SHOT: al colocarse se libera el "candado" solo, sin desconectar a mano.
	new_building.state_changed.connect(_on_placing_finished, CONNECT_ONE_SHOT)


func _on_placing_finished() -> void:
	_placing_building = null


func _on_energy_ready() -> void:
	energy += 1


func _on_water_ready() -> void:
	water += 1

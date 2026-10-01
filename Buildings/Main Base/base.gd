extends Sprite2D
## Base principal: despacha rovers hacia un punto del suelo clickeado o hacia
## un interactuable que pida uno (hasta MAX_ROVERS activos a la vez).
##
## No sabe qué hace el rover en el destino ni cuándo termina: solo cuenta
## cuántos hay vivos para saber si puede mandar otro.
##
## Un interactuable "pide rover" implementando request_rover(); el resto de la
## interfaz (start_rover_interaction, rover_interaction_finished) la usa el
## rover. Ver outpost_rover.gd.

const MAX_ROVERS := 3
const ROVER_SCENE := preload("uid://np2aojdufexy")

var _active_rovers := 0
# Interactuables que pidieron rover cuando no había cupo (FIFO).
var _pending_targets: Array = []


func _ready() -> void:
	SignalManager.ground_clicked.connect(_on_ground_clicked)
	SignalManager.interactable_clicked.connect(_on_interactable_clicked)


func _on_ground_clicked(click_position: Vector2) -> void:
	# Los clicks al suelo sin cupo se descartan (no se encolan).
	if _has_free_rover():
		_spawn_rover(click_position)


func _on_interactable_clicked(target: Node) -> void:
	# request_rover() es quien decide (y recuerda) si el target quiere un rover,
	# así un mismo target no se encola ni se atiende dos veces por re-clicks.
	if not target.has_method("request_rover") or not target.request_rover():
		return

	if _has_free_rover():
		_spawn_rover(target.global_position, target)
	else:
		_pending_targets.append(target)


func _has_free_rover() -> bool:
	return _active_rovers < MAX_ROVERS


## Manda un rover a destination. Si se pasa target, el rover interactúa con él al llegar.
func _spawn_rover(destination: Vector2, target: Node = null) -> void:
	var rover: OutpostRover = ROVER_SCENE.instantiate()
	rover.position = global_position
	rover.base_position = global_position
	rover.target_position = destination
	rover.target = target

	# CONNECT_ONE_SHOT: cuando el rover vuelve y se destruye solo, la base
	# libera el cupo. No hace falta guardar una lista de rovers.
	rover.returned_to_base.connect(_on_rover_returned, CONNECT_ONE_SHOT)

	_active_rovers += 1
	get_tree().root.add_child(rover)


func _on_rover_returned() -> void:
	_active_rovers -= 1
	_dispatch_pending()


## Manda rovers a los interactuables en cola mientras haya cupo.
func _dispatch_pending() -> void:
	while not _pending_targets.is_empty() and _has_free_rover():
		var target = _pending_targets.pop_front()
		if is_instance_valid(target):
			_spawn_rover(target.global_position, target)

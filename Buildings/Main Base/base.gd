extends Sprite2D
## Base principal: cada vez que se clickea el suelo, manda un rover a esa
## posición (hasta un máximo de rovers activos a la vez). No le importa a
## dónde va cada rover ni cuándo vuelve el resto: solo cuenta cuántos hay
## vivos ahora mismo para saber si puede crear uno más.

const MAX_ROVERS := 3

var rover_scene = preload("uid://diy8tkismxt1k")

var _active_rovers := 0

func _ready() -> void:
	SignalManager.ground_clicked.connect(_on_ground_clicked)

func _on_ground_clicked(click_position: Vector2) -> void:
	if _active_rovers >= MAX_ROVERS:
		return

	var new_rover = rover_scene.instantiate()
	new_rover.position = global_position
	new_rover.base_position = global_position
	new_rover.target_position = click_position

	_active_rovers += 1
	# CONNECT_ONE_SHOT: cuando el rover llega de vuelta y se destruye solo,
	# la base se entera y libera el cupo. No hace falta guardar una lista
	# de rovers ni desconectar nada a mano; cada rover se maneja a sí mismo.
	new_rover.returned_to_base.connect(func() -> void:
		_active_rovers -= 1
	, CONNECT_ONE_SHOT)

	get_tree().root.add_child(new_rover)

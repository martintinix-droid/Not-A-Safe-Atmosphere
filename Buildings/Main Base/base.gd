extends Sprite2D
## Base principal: cada vez que se clickea el suelo, manda un rover a esa
## posición (hasta un máximo de rovers activos a la vez). No le importa a
## dónde va cada rover ni cuándo vuelve el resto: solo cuenta cuántos hay
## vivos ahora mismo para saber si puede crear uno más.

const MAX_ROVERS := 3

var qued_rovers:=0
var qued_objects=[]


var rover_scene = preload("uid://np2aojdufexy")

var _active_rovers := 0

func _ready() -> void:
	SignalManager.ground_clicked.connect(_on_ground_clicked)
	SignalManager.builidng_placed.connect(_on_building_placed)
	
func _process(_delta: float) -> void:
	if qued_rovers>0:
		if !_active_rovers>=MAX_ROVERS:
			spawn_rover(qued_objects[0])
			qued_objects.remove_at(0)
			qued_rovers-=1
			

func _on_ground_clicked(click_position: Vector2) -> void:
	if _active_rovers >= MAX_ROVERS:
		return
	print("accesed ground clicked")
	spawn_rover(click_position)
	

func _on_building_placed(building)->void:
	if building.is_building:
		if _active_rovers >= MAX_ROVERS:
			qued_rovers+=1
			qued_objects.append(building)
			return
		
		spawn_rover(building)

func spawn_rover(object):
	if object is Sprite2D:
		if object.is_in_group("buildings"):
			var new_rover = rover_scene.instantiate()
			new_rover.position = global_position
			new_rover.base_position = global_position
			new_rover.target_position = object.global_position
			new_rover.building = object

			_active_rovers += 1
			
			
			# CONNECT_ONE_SHOT: cuando el rover llega de vuelta y se destruye solo,
			# la base se entera y libera el cupo. No hace falta guardar una lista
			# de rovers ni desconectar nada a mano; cada rover se maneja a sí mismo.
			new_rover.returned_to_base.connect(func() -> void:
				_active_rovers -= 1
			, CONNECT_ONE_SHOT)
			
			get_tree().root.add_child(new_rover)
	else:
		var new_rover = rover_scene.instantiate()
		new_rover.position = global_position
		new_rover.base_position = global_position
		new_rover.target_position = object

		_active_rovers += 1
		print(_active_rovers)
		# CONNECT_ONE_SHOT: cuando el rover llega de vuelta y se destruye solo,
		# la base se entera y libera el cupo. No hace falta guardar una lista
		# de rovers ni desconectar nada a mano; cada rover se maneja a sí mismo.
		new_rover.returned_to_base.connect(func() -> void:
			_active_rovers -= 1
		, CONNECT_ONE_SHOT)

		get_tree().root.add_child(new_rover)
		

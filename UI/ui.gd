extends Control
## Panel de UI: por ahora solo tiene un botón para pedirle a main.gd que
## instancie el generador de energía.

@onready var building_button: Button = %"building button"

@onready var v_box_container: VBoxContainer = %VBoxContainer

# Índice de cada edificio dentro del array "buildings_info" de main.gd.
# Se usa como "id" para no tener que mandar el nombre del edificio por señal.
var button_building_index := {
	"energy": 0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	building_button.pressed.connect(func() -> void:
		#SignalManager.spawn_building.emit(button_building_index["energy"])
		_swap_building_ui()
	)
	
func _swap_building_ui()->void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(building_button,"position:x",
	building_button.position.x+300,0.5)
	
	v_box_container.position.x+=300
	v_box_container.visible=true
	tween.tween_property(v_box_container,"position:x",
	v_box_container.position.x-300,0.5)

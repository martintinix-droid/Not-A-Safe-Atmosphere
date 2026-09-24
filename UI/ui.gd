extends Control
## Panel de UI: por ahora solo tiene un botón para pedirle a main.gd que
## instancie el generador de energía.

@onready var button: Button = %Button

# Índice de cada edificio dentro del array "buildings_info" de main.gd.
# Se usa como "id" para no tener que mandar el nombre del edificio por señal.
var button_building_index := {
	"energy": 0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(func() -> void:
		SignalManager.spawn_building.emit(button_building_index["energy"])
	)

extends Node2D
## Controlador principal del juego: escucha las señales globales de
## SignalManager, lleva la cuenta de la energía y se encarga de instanciar
## los edificios que pide la UI.

var energy := 0

const building_placer_scene = preload("uid://df3auwtkj8ls8")

# Escena de cada tipo de edificio, indexada por nombre.
var buildings_preload := {
	"energy": preload("uid://b7ux8e48tnrv3")
}

# Info de cada edificio disponible. La posición de cada elemento en este
# array es el "index" que usa la UI (ver ui.gd) para pedir que se instancie.
var buildings_info: Array = [
	{"building": "energy", "cost": 10, "preload": buildings_preload["energy"]}
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.energy_ready.connect(_on_energy_ready)
	SignalManager.spawn_building.connect(_on_spawn_building_ready)

func _on_energy_ready() -> void:
	energy += 1

func _on_spawn_building_ready(index: int) -> void:
	var current_building = buildings_info[index]
	var new_building = current_building["preload"].instantiate()
	add_child(new_building)

extends Node2D


var energy:=0
const building_placer_scene = preload("uid://df3auwtkj8ls8")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.energy_ready.connect(_on_energy_ready)
	SignalManager.spawn_building.connect(_on_spawn_building_ready)
func _on_energy_ready()->void:
	energy+=1
	
func _on_spawn_building_ready()->void:
	var building_placer = building_placer_scene.instantiate()
	add_child(building_placer)
	

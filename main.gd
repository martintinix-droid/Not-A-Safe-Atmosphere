extends Node2D


var energy:=0
const building_placer_scene = preload("uid://df3auwtkj8ls8")

var buildings_preload={
	"energy": preload("uid://b7ux8e48tnrv3")
}

var buildings_info:Array=[
	{"building":"energy", "cost":10,"preload":buildings_preload["energy"]}
]
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.energy_ready.connect(_on_energy_ready)
	SignalManager.spawn_building.connect(_on_spawn_building_ready)
func _on_energy_ready()->void:
	energy+=1
	
func _on_spawn_building_ready(index)->void:
	print("on spawn accesed")
	var current_building=buildings_info[index]
	var new_building = current_building["preload"].instantiate()
	add_child(new_building)
	

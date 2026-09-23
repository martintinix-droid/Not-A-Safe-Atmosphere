extends Node2D


var energy:=0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalManager.energy_ready.connect(_on_energy_ready)

func _on_energy_ready()->void:
	energy+=1
	

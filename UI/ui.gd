extends Control
@onready var button: Button = %Button

var button_building_index={
	"enrgy":0
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(func()->void:
		print("button pressed")
		SignalManager.spawn_building.emit(button_building_index["energy"])
		)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

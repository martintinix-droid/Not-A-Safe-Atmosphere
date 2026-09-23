extends Sprite2D
@onready var timer: Timer = %Timer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.timeout.connect(func() ->void:
		SignalManager.energy_ready.emit())
		

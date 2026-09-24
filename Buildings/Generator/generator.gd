extends Sprite2D
@onready var timer: Timer = %Timer

var spawned_state=true
signal state_changed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.stop()
	timer.timeout.connect(func() ->void:
		SignalManager.energy_ready.emit())
	state_changed.connect(_on_state_changed)
	modulate=Color(0,1,0,0.7)
		
func _on_clicked()->void:
	if spawned_state:
		spawned_state=false
		state_changed.emit()
	else:
		#future logic to inspect properties
		pass

func _on_state_changed()->void:
		timer.start()
		modulate=Color(0,0,0,1)

func _process(delta: float) -> void:
	if spawned_state:
		global_position=get_global_mouse_position()
		

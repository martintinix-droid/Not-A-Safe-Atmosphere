extends Sprite2D
## Generador de energía.
## Al instanciarse queda en "modo fantasma": sigue al mouse y se pinta de
## verde/rojo según si el lugar es válido. Al hacer click se coloca de forma
## definitiva y empieza a generar energía cada vez que el Timer termina.

@onready var timer: Timer = %Timer
@onready var area_2d: Area2D = %Area2D

var is_placing := true   # true mientras el edificio está en modo fantasma (sin colocar todavía)
var overlap_count := 0   # cantidad de cuerpos/áreas que están tocando el Area2D ahora mismo

# Solo es colocable si no hay nada encimado. Usar un contador (en vez de un
# simple bool) evita que quede "colocable" cuando todavía hay OTRO objeto
# distinto tapando el lugar (bug si hay varios objetos superpuestos).
var placeable: bool:
	get:
		return overlap_count == 0

signal state_changed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# El timer arranca recién cuando el edificio se coloca, no antes.
	timer.stop()
	timer.timeout.connect(func() -> void:
		SignalManager.energy_ready.emit())

	state_changed.connect(_on_state_changed)
	modulate = Color(0, 1, 0, 0.5)  # verde semi-transparente = modo fantasma

	# Se escuchan tanto "area" como "body" porque no sabemos de antemano si lo
	# que colisiona es un Area2D o un body físico (StaticBody2D, etc).
	area_2d.area_entered.connect(_on_object_entered)
	area_2d.body_entered.connect(_on_object_entered)
	area_2d.body_exited.connect(_on_object_exited)
	area_2d.area_exited.connect(_on_object_exited)

func _input(event: InputEvent) -> void:
	# is_action_pressed (y no is_action) evita que el click se procese dos
	# veces: una al presionar el botón y otra al soltarlo.
	if event.is_action_pressed("click"):
		if is_pixel_opaque(get_local_mouse_position()):
			_on_clicked()

func _on_clicked() -> void:
	if is_placing && placeable:
		is_placing = false
		state_changed.emit()
	else:
		# TODO: lógica futura para inspeccionar el edificio ya colocado
		pass

func _on_object_entered(_object_collided: Object) -> void:
	overlap_count += 1
	if is_placing:
		modulate = Color(1, 0, 0)  # rojo = no se puede colocar acá

func _on_object_exited(_object_collided: Object) -> void:
	overlap_count = max(overlap_count - 1, 0)
	# Solo vuelve a verde si YA NO queda ningún objeto encimado.
	if is_placing && placeable:
		modulate = Color(0, 1, 0, 0.5)

func _on_state_changed() -> void:
	# El edificio quedó colocado de forma definitiva: se vuelve opaco y
	# arranca a generar energía cada vez que pasa el tiempo del Timer.
	timer.start()
	modulate = Color(1, 1, 1, 1)

func _process(_delta: float) -> void:
	if is_placing:
		global_position = get_global_mouse_position()

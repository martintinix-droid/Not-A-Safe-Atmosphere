extends Sprite2D
## Generador de energía.
## Al instanciarse queda en "modo fantasma": sigue al mouse y se pinta de
## verde/rojo según si el lugar es válido. Al hacer click se coloca de forma
## definitiva y empieza a generar energía cada vez que el Timer termina.
##
## El click en sí ya NO se detecta acá: main.gd es quien escucha el input
## global, decide qué objeto fue clickeado (edificio, suelo para el rover,
## etc.) y emite "clicked" sobre el que corresponda.

@onready var building_timer: Timer = $building_timer
@onready var timer: Timer = %Timer
@onready var area_2d: Area2D = %Area2D

var is_placing := true   # true mientras el edificio está en modo fantasma (sin colocar todavía)
var overlap_count := 0   # cantidad de cuerpos/áreas que están tocando el Area2D ahora mismo

var build_time:=0
# Solo es colocable si no hay nada encimado. Usar un contador (en vez de un
# simple bool) evita que quede "colocable" cuando todavía hay OTRO objeto
# distinto tapando el lugar (bug si hay varios objetos superpuestos).
var placeable: bool:
	get:
		return overlap_count == 0

signal state_changed
signal clicked   # main.gd lo emite cuando este edificio es el que se clickeó

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# main.gd necesita poder encontrar a todos los edificios (colocados o
	# no) para hacer el hit-test del click sin que cada uno escuche input.
	add_to_group("buildings")

	# El timer arranca recién cuando el edificio se coloca, no antes.
	building_timer.timeout.connect(func()->void:
		#timer.start()
		modulate = Color(1, 1, 1, 1)
		)
	
	timer.stop()
	timer.timeout.connect(func() -> void:
		SignalManager.energy_ready.emit())

	state_changed.connect(_on_state_changed)
	clicked.connect(_on_clicked)
	modulate = Color(0, 1, 0, 0.5)  # verde semi-transparente = modo fantasma

	# Se escuchan tanto "area" como "body" porque no sabemos de antemano si lo
	# que colisiona es un Area2D o un body físico (StaticBody2D, etc).
	area_2d.area_entered.connect(_on_object_entered)
	area_2d.body_entered.connect(_on_object_entered)
	area_2d.body_exited.connect(_on_object_exited)
	area_2d.area_exited.connect(_on_object_exited)

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
		modulate = Color(1, 0, 0,0.5)  # rojo = no se puede colocar acá

func _on_object_exited(_object_collided: Object) -> void:
	overlap_count = max(overlap_count - 1, 0)
	# Solo vuelve a verde si YA NO queda ningún objeto encimado.
	if is_placing && placeable:
		modulate = Color(0, 1, 0, 0.5)

func _on_state_changed() -> void:
	# El edificio quedó colocado de forma definitiva: se vuelve opaco y
	# arranca a generar energía cada vez que pasa el tiempo del Timer.
	#timer.start()
	modulate = Color(0, 0.5, 1, 0.5)

func _process(_delta: float) -> void:
	if is_placing:
		global_position = get_global_mouse_position()

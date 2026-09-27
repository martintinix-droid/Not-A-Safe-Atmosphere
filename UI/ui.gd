extends Control
## Panel de UI: por ahora solo tiene un botón para pedirle a main.gd que
## instancie el generador de energía.

@onready var building_button: Button = %"building button"
@onready var energy: Button = %energy
@onready var water: Button = $HBoxContainer/VBoxContainer/water
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var back_button: Button = $"HBoxContainer/VBoxContainer2/Back Button"

# Índice de cada edificio dentro del array "buildings_info" de main.gd.
# Se usa como "id" para no tener que mandar el nombre del edificio por señal.
var button_building_index := {
	"energy": 0,
	"water":1
}

const SWAP_OFFSET_X := 300.0
const SWAP_DURATION := 0.5

# Posiciones originales, guardadas una sola vez al iniciar. Animar siempre
# hacia/desde estos valores evita ir sumando/restando offsets a mano (y que
# se desincronicen si _swap_building_ui se llama más de una vez).
var _building_button_start_pos: Vector2
var _h_box_container_start_pos: Vector2

var _current_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_building_button_start_pos = building_button.position
	_h_box_container_start_pos = h_box_container.position

	building_button.pressed.connect(func() -> void:
		_swap_building_ui()
	)
	back_button.pressed.connect(func() -> void:
		_reset_building_ui()
	)
	energy.pressed.connect(func() -> void:
		SignalManager.spawn_building.emit(button_building_index["energy"])
	)
	water.pressed.connect(func() ->void:
		SignalManager.spawn_building.emit(button_building_index["water"])
		)


## Desliza building_button hacia afuera y h_box_container hacia adentro.
func _swap_building_ui() -> void:
	h_box_container.position = _h_box_container_start_pos + Vector2(SWAP_OFFSET_X, 0)
	h_box_container.visible = true

	_animate_swap(
		_building_button_start_pos + Vector2(SWAP_OFFSET_X, 0),
		_h_box_container_start_pos
	)


## Inverso de _swap_building_ui: devuelve todo a su posición original.
func _reset_building_ui() -> void:
	_animate_swap(
		_building_button_start_pos,
		_h_box_container_start_pos + Vector2(SWAP_OFFSET_X, 0),
		func() -> void:
			h_box_container.visible = false
	)


## Anima building_button y h_box_container en paralelo hacia las posiciones
## dadas. Bloquea los botones mientras dura la animación y los vuelve a
## habilitar al terminar (ejecutando on_finished justo antes, si se pasó).
func _animate_swap(
	building_button_target: Vector2,
	h_box_container_target: Vector2,
	on_finished: Callable = Callable()
) -> void:
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()

	_set_buttons_interactable(false)

	_current_tween = create_tween()
	_current_tween.set_trans(Tween.TRANS_QUAD)
	_current_tween.set_parallel(true)
	_current_tween.tween_property(
		building_button, "position", building_button_target, SWAP_DURATION
	)
	_current_tween.tween_property(
		h_box_container, "position", h_box_container_target, SWAP_DURATION
	)

	_current_tween.finished.connect(func() -> void:
		if on_finished.is_valid():
			on_finished.call()
		_set_buttons_interactable(true)
	)


func _set_buttons_interactable(interactable: bool) -> void:
	building_button.disabled = not interactable
	back_button.disabled = not interactable
	energy.disabled = not interactable
	water.disabled = not interactable

extends Control
## Panel de UI para construir: el botón "building" desliza el panel de
## edificios, y cada botón de edificio le pide a main.gd que lo instancie.

const SWAP_OFFSET_X := 300.0
const SWAP_DURATION := 0.5

@onready var building_button: Button = %"building button"
@onready var energy: Button = %energy
@onready var water: Button = $HBoxContainer/VBoxContainer/water
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var back_button: Button = $"HBoxContainer/VBoxContainer2/Back Button"

## id de edificio (clave de BUILDINGS en main.gd) -> su botón.
## Para agregar un edificio: sumar su botón y una entrada acá.
@onready var _building_buttons := {
	"energy": energy,
	"water": water,
}

# Posiciones originales, guardadas una sola vez al iniciar. Animar siempre
# hacia/desde estos valores evita ir sumando/restando offsets a mano.
var _building_button_start_pos: Vector2
var _h_box_container_start_pos: Vector2

var _current_tween: Tween


func _ready() -> void:
	# El panel ocupa la pantalla; si el Control raíz absorbiera los clicks, main.gd
	# nunca los recibiría. Los botones siguen consumiendo los suyos.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_building_button_start_pos = building_button.position
	_h_box_container_start_pos = h_box_container.position

	building_button.pressed.connect(_swap_building_ui)
	back_button.pressed.connect(_reset_building_ui)
	for building_id in _building_buttons:
		var button: Button = _building_buttons[building_id]
		button.pressed.connect(_request_building.bind(building_id))


func _request_building(building_id: String) -> void:
	SignalManager.spawn_building.emit(building_id)


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
## dadas. Bloquea los botones mientras dura y los rehabilita al terminar
## (ejecutando on_finished justo antes, si se pasó).
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
	for button in _building_buttons.values():
		button.disabled = not interactable

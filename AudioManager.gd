extends Node
## Autoload (singleton) that plays all the game's audio: background music,
## one-shot sound effects and the looping construction sound.
##
## - Button clicks: every BaseButton that enters the scene tree is connected
##   automatically (see _on_node_added), including buttons created by code.
##   To silence a button: button.set_meta("no_click_sound", true).
## - Construction: generator.gd / research_lab.gd emit construction_started and
##   construction_finished through SignalManager. The loop plays while at least
##   one building is under construction.
## - Sounds are defined in sounds.gd.
##
## Register it in Project Settings > Autoload, AFTER SignalManager.

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const NO_CLICK_META := "no_click_sound"
const SFX_POOL_SIZE := 8  # Max sound effects playing at the same time.

var _music_player := AudioStreamPlayer.new()
var _construction_player := AudioStreamPlayer.new()
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _constructing := 0  # Buildings currently under construction.


func _ready() -> void:
	# Music and click sounds keep working while the game is paused (events).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(BUS_MUSIC)
	_ensure_bus(BUS_SFX)

	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	# The construction loop DOES stop with the pause: building timers stop too.
	_construction_player.bus = BUS_SFX
	_construction_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_construction_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_sfx_pool.append(player)

	get_tree().node_added.connect(_on_node_added)
	SignalManager.building_placed.connect(play_sfx.bind(Sounds.PLACE))
	SignalManager.construction_started.connect(_on_construction_started)
	SignalManager.construction_finished.connect(_on_construction_finished)

	play_music(Sounds.MUSIC_MAIN)


# --- Public API ---

## Plays a one-shot effect. Several can overlap (up to SFX_POOL_SIZE).
func play_sfx(id: String) -> void:
	var stream := Sounds.get_stream(id)
	if stream == null:
		return
	# Prefer an idle player; if all are busy, reuse the oldest one (round robin).
	var player: AudioStreamPlayer = null
	for candidate in _sfx_pool:
		if not candidate.playing:
			player = candidate
			break
	if player == null:
		player = _sfx_pool[_next_sfx]
		_next_sfx = (_next_sfx + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = Sounds.volume_db(id)
	player.play()


func play_music(id: String) -> void:
	var stream := Sounds.get_stream(id)
	if stream == null:
		return
	_prepare_loop(_music_player, stream)
	_music_player.stream = stream
	_music_player.volume_db = Sounds.volume_db(id)
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


## For future volume sliders. `linear` goes from 0.0 (mute) to 1.0 (full).
func set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))


# --- Internals ---

## Creates the bus at runtime if it does not exist yet. If you create "Music"
## and "SFX" in the editor's Audio panel, those are used instead.
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


## .ogg and .mp3 have a `loop` property. For .wav (no such property) the player
## is restarted when it finishes; a short gap is possible, so prefer .ogg for
## loops, or enable looping in the file's Import tab.
func _prepare_loop(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if "loop" in stream:
		stream.loop = true
	elif not player.finished.is_connected(player.play):
		player.finished.connect(player.play)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(_on_button_pressed.bind(node))


func _on_button_pressed(button: BaseButton) -> void:
	if not button.has_meta(NO_CLICK_META):
		play_sfx(Sounds.CLICK)


func _on_construction_started() -> void:
	_constructing += 1
	if _constructing > 1:
		return  # Already playing for another building.
	var stream := Sounds.get_stream(Sounds.CONSTRUCTION_LOOP)
	if stream == null:
		return
	_prepare_loop(_construction_player, stream)
	_construction_player.stream = stream
	_construction_player.volume_db = Sounds.volume_db(Sounds.CONSTRUCTION_LOOP)
	_construction_player.play()


func _on_construction_finished() -> void:
	_constructing = maxi(_constructing - 1, 0)
	if _constructing == 0:
		_construction_player.stop()

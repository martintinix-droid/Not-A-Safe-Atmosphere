extends Node
## Schedules random events and applies the chosen option's effects.
## Flow: WAITING (timer) -> PENDING (button shown, game paused)
##       -> ACTIVE (panel open) -> result -> dismissed -> WAITING.
## The timer restarts when the event is dismissed, so intervals never stack.

const MIN_INTERVAL := 300.0  # 5 min
const MAX_INTERVAL := 360.0  # 6 min
## While DEBUG is true: events fire every DEBUG_INTERVAL seconds, and F12
## force-closes a pending/active event (emergency unpause).
const DEBUG := false
const DEBUG_INTERVAL := 5.0

enum State { WAITING, PENDING, ACTIVE }

var state := State.WAITING

var _current_id := ""
var _last_id := ""  # Avoids picking the same event twice in a row.
var _timer := Timer.new()


func _ready() -> void:
	if DEBUG:
		# Needed so F12 still works while the tree is paused.
		process_mode = Node.PROCESS_MODE_ALWAYS

	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	SignalManager.event_open_requested.connect(_on_open_requested)
	SignalManager.event_option_chosen.connect(_on_option_chosen)
	SignalManager.event_dismissed.connect(_on_dismissed)
	_start_timer()


func _input(event: InputEvent) -> void:
	if DEBUG and state != State.WAITING \
			and event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		print("[EventManager] DEBUG: forced dismiss")
		_on_dismissed()


func _start_timer() -> void:
	state = State.WAITING
	_timer.start(DEBUG_INTERVAL if DEBUG else randf_range(MIN_INTERVAL, MAX_INTERVAL))


func _on_timer_timeout() -> void:
	_current_id = _pick_event()
	state = State.PENDING
	get_tree().paused = true  # Only nodes with process_mode ALWAYS keep working.
	print("[EventManager] event available: ", _current_id)
	SignalManager.event_available.emit(_current_id)

func _on_open_requested() -> void:
	if state != State.PENDING:
		return
	state = State.ACTIVE  # The UI reads EventsData.DATA[_current_id] itself.


func _on_option_chosen(index: int) -> void:
	if state != State.ACTIVE:
		return
	var option: Dictionary = EventsData.DATA[_current_id]["options"][index]
	if not Inventory.can_afford(option["requires"]):
		return
	for effect in option["effects"]:
		EventEffects.apply(effect, get_tree())
	SignalManager.event_resolved.emit(option["result"])


func _on_dismissed() -> void:
	_last_id = _current_id
	_current_id = ""
	get_tree().paused = false
	_start_timer()


## Weighted random pick, avoiding the event that just happened.
func _pick_event() -> String:
	var ids: Array = EventsData.DATA.keys().filter(func(id): return id != _last_id)
	if ids.is_empty():
		ids = EventsData.DATA.keys()
	var total := 0.0
	for id in ids:
		total += EventsData.DATA[id]["weight"]
	var roll := randf() * total
	for id in ids:
		roll -= EventsData.DATA[id]["weight"]
		if roll <= 0.0:
			return id
	return ids.back()

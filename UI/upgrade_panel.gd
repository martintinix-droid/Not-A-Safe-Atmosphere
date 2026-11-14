extends PanelContainer
## Mini upgrade panel: shows the next level's stat changes and cost for the
## clicked building (or the base). Works with any node that has `upgrade: UpgradeState`.

const COLOR_OK := Color.WHITE
const COLOR_MISSING := Color(1.0, 0.4, 0.4)

@onready var title_label: Label = %UTitleLabel
@onready var stats_container: VBoxContainer = %StatsContainer
@onready var cost_container: VBoxContainer = %CostContainer
@onready var upgrade_button: Button = %UpgradeButton
@onready var close_button: Button = %CloseButton

var _target: Node = null


func _ready() -> void:
	hide()
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	close_button.pressed.connect(close)
	SignalManager.upgrade_requested.connect(open)
	# The game pauses for events: don't leave this panel stuck open.
	SignalManager.event_available.connect(func(_id: String) -> void: close())
	Inventory.changed.connect(_on_inventory_changed)


func open(target: Node) -> void:
	if not "upgrade" in target:
		return
	_release_target()
	_target = target
	# An event can destroy the building while the panel is open.
	_target.tree_exiting.connect(close)
	show()
	_refresh()


func close() -> void:
	_release_target()
	hide()


func _release_target() -> void:
	if is_instance_valid(_target) and _target.tree_exiting.is_connected(close):
		_target.tree_exiting.disconnect(close)
	_target = null


func _on_upgrade_pressed() -> void:
	if is_instance_valid(_target) and _target.upgrade.try_upgrade():
		_refresh()


## Keeps the red/white cost colors and the button state up to date while open.
func _on_inventory_changed(_id: String, _amount: int) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	if not is_instance_valid(_target):
		close()
		return

	var state: UpgradeState = _target.upgrade
	title_label.text = "%s - Level %d/%d" % [
		UpgradesInfo.display_name(state.upgrade_id), state.level, state.max_level()
	]
	_clear(stats_container)
	_clear(cost_container)

	if state.is_max():
		_add_label(stats_container, "Max level reached")
		upgrade_button.text = "Maxed"
		upgrade_button.disabled = true
		return

	var next := state.next()
	for stat in next["stats"]:
		_add_label(stats_container, "%s: %s -> %s" % [
			UpgradesInfo.stat_name(stat),
			UpgradesInfo.format_stat(stat, state.stats.get(stat, 0)),
			UpgradesInfo.format_stat(stat, next["stats"][stat]),
		])
	for id in next["cost"]:
		var need: int = next["cost"][id]
		var have := Inventory.get_amount(id)
		var label := _add_label(cost_container, "%s: %d / %d" % [Resources.display_name(id), have, need])
		label.modulate = COLOR_OK if have >= need else COLOR_MISSING

	upgrade_button.text = "Upgrade"
	upgrade_button.disabled = not state.can_afford()


func _add_label(container: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	container.add_child(label)
	return label


func _clear(container: VBoxContainer) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

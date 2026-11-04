
class_name EventEffects
extends RefCounted
## Applies the typed effects defined in EventsData.
## To add an effect type: add a case in apply() and a helper below.

static func apply(effect: Dictionary, tree:SceneTree) -> void:
	match effect["type"]:
		"resource":
			_apply_resource(effect)
		"disable_generator":
			for generator in _pick_generators(effect, tree, true):
				generator.disable(effect.get("duration",0.0))
		"destroy_generator":
			for generator in _pick_generators(effect, tree, false):
				generator.destroy()

static func _apply_resource(effect:Dictionary)->void:
	var id : String = effect["id"]
	assert(Inventory.get_ids().has(id), "Event uses unknown resource: %s" % id)
	var delta: int  = effect["amount"]
	
	Inventory.add(id, maxi(delta, -Inventory.get_amount(id)))

static func _pick_generators(effect:Dictionary, tree: SceneTree, skip_disabled:bool)-> Array:
	var target : String = effect.get("target", "any")
	var candidates := tree.get_nodes_in_group("buildings").filter(func(b):
		return b.is_active() \
			and not (skip_disabled and b.is_disabled) \
			and (target == "any" or b.resource_id == target) 
	)
	candidates.shuffle()
	return candidates.slice(0,effect.get("count",1))

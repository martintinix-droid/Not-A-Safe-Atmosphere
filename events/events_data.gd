class_name EventsData
extends RefCounted
## Catalog of random events (static data only), same idea as Buildings.DATA.
##
## Entry format:
##   "title", "description": texts shown in the panel.
##   "weight":   relative chance of being picked.
##   "options":  Array of:
##       "text":     button label.
##       "requires": {resource id: amount}. Only GATES the option (button
##                   disabled if not affordable); it does NOT charge anything.
##                   To charge, add a "resource" effect with a negative amount.
##       "effects":  Array of typed effects (see event_effects.gd):
##           {"type": "resource", "id": String, "amount": int}
##           {"type": "disable_generator", "target": String, "count": int, "duration": float}
##           {"type": "destroy_generator", "target": String, "count": int}
##           "target" is a generator resource_id ("energy", "water"...) or "any".
##           "duration" <= 0 means the generator stays off permanently.
##       "result":   text shown after choosing.
##
## To add an event: add an entry here. No other file needs to change.

const DATA := {
	"event1": {
		"title": "Test event #1",
		"description": "resource substraction or a generator stops",
		"weight": 1.0,
		"options": [
			{
				"text": "resource lost",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -5},
				],
				"result": "you lost some resources",
			},
			{
				"text": "extra resource and generator stops",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": 8},
					{"type": "disable_generator", "target": "energy", "count": 1, "duration": 60.0},
				],
				"result": "a generator jams for a minute",
			},
		],
	},
	"event2": {
		"title": "Test event #2",
		"description": "Resource substraction or a generator is destroyed",
		"weight": 1.0,
		"options": [
			{
				"text": "lose resources",
				"requires": {"Basalt rock": 3},
				"effects": [
					{"type": "resource", "id": "Basalt rock", "amount": -3},
				],
				"result": "lost resources",
			},
			{
				"text": "generator is destroyed",
				"requires": {},
				"effects": [
					{"type": "destroy_generator", "target": "any", "count": 1},
				],
				"result": "a geenrator is destroyed",
			},
		],
	},
	"event3": {
		"title": "Test event #3",
		"description": "resource lost or generator jam + resource lost",
		"weight": 1.0,
		"options": [
			{
				"text": "lose resources",
				"requires": {"Regolith": 2},
				"effects": [
					{"type": "resource", "id": "Regolith", "amount": -2},
				],
				"result": "resource lost",
			},
			{
				"text": "lose resources and a generator jams",
				"requires": {},
				"effects": [
					{"type": "disable_generator", "target": "water", "count": 1, "duration": 45.0},
					{"type": "resource", "id": "water", "amount": -10},
				],
				"result": "generator jamed, resources lost",
			},
		],
	},
}

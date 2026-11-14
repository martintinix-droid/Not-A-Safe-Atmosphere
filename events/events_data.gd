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
	"Dust Storm": {
		"title": "Dust Storm",
		"description": "A Dust Storm Approaches",
		"weight": 1.0,
		"options": [
			{
				## Reformat
				"text": "Reinforce Your Generators (Requires: 5 Basalt Rocks and 5 Regolith)",
				"requires": {"Basalt Rock": 5, "Regolith": 5},
				"effects": [
					{"type": "resource", "id": "Basalt Rock", "amount": -5},
					{"type": "resource", "id": "Regolith", "amount": -5},
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
	"Structural Failure": {
		"title": "Structural Failure",
		"description": "Stress fractures are spreading through one of the outpost's support beams.",
		"weight": 1.0,
		"options": [
			{
				"text": "Reinforce the beam (Requires: 3 Basalt Rock)",
				"requires": {"Basalt Rock": 3},
				"effects": [
					{"type": "resource", "id": "Basalt Rock", "amount": -3},
				],
				"result": "The beam is reinforced. You used 3 Basalt Rock.",
			},
			{
				"text": "Leave it and keep working",
				"requires": {},
				"effects": [
					{"type": "destroy_generator", "target": "any", "count": 1},
				],
				"result": "The beam gives way and a generator is destroyed.",
			},
		],
	},
	"Meteor Shower": {
		"title": "Meteor Shower",
		"description": "Small meteors are streaking toward the outpost. Impact in under a minute.",
		"weight": 0.8,
		"options": [
			{
				"text": "Raise a debris shield (Requires: 15 Basalt Rock and 10 Regolith)",
				"requires": {"Basalt Rock": 15, "Regolith": 10},
				"effects": [
					{"type": "resource", "id": "Basalt Rock", "amount": -15},
					{"type": "resource", "id": "Regolith", "amount": -10},
				],
				"result": "The shield holds. Meteors burn up harmlessly above the base.",
			},
			{
				"text": "Take cover and hope for the best",
				"requires": {},
				"effects": [
					{"type": "destroy_generator", "target": "any", "count": 1},
				],
				"result": "A meteor slams into the outpost. One building is destroyed.",
			},
		],
	},
	"Solar Flare": {
		"title": "Solar Flare",
		"description": "A solar flare is about to wash over the surface. Electronics are at risk.",
		"weight": 0.8,
		"options": [
			{
				"text": "Shut down non-essential systems (Requires: 20 Energy)",
				"requires": {"energy": 20},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -20},
					{"type": "disable_generator", "target": "energy", "count": 1, "duration": 30.0},
				],
				"result": "You power down in time. Generators restart after 30 seconds.",
			},
			{
				"text": "Ride it out",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -15},
					{"type": "disable_generator", "target": "energy", "count": 2, "duration": 60.0},
				],
				"result": "The flare fries the circuits. Energy is lost and two generators go offline for a minute.",
			},
		],
	},
	"Water Leak": {
		"title": "Water Leak",
		"description": "Pressure is dropping in the water lines. Somewhere there is a leak.",
		"weight": 1.0,
		"options": [
			{
				"text": "Patch the pipes (Requires: 8 Regolith)",
				"requires": {"Regolith": 8},
				"effects": [
					{"type": "resource", "id": "Regolith", "amount": -8},
					{"type": "resource", "id": "water", "amount": -5},
				],
				"result": "The leak is sealed quickly. Only a little water escapes.",
			},
			{
				"text": "Ignore it and keep working",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "water", "amount": -20},
					{"type": "disable_generator", "target": "water", "count": 1, "duration": 40.0},
				],
				"result": "Water drains away and the water generator stalls for 40 seconds.",
			},
		],
	},
	"Power Surge": {
		"title": "Power Surge",
		"description": "A sudden spike is running through the power grid.",
		"weight": 1.0,
		"options": [
			{
				"text": "Divert power to storage (Requires: 10 Energy)",
				"requires": {"energy": 10},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -10},
				],
				"result": "The surge is absorbed. A small amount of energy is lost.",
			},
			{
				"text": "Let it pass through the grid",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -10},
					{"type": "disable_generator", "target": "energy", "count": 1, "duration": 45.0},
				],
				"result": "A generator overloads and shuts down for 45 seconds.",
			},
		],
	},
	"Rover Malfunction": {
		"title": "Rover Malfunction",
		"description": "A rover is giving off warning sounds, and its tracks are grinding.",
		"weight": 0.8,
		"options": [
			{
				"text": "Repair it with spare parts (Requires: 10 Basalt Rock and 5 Regolith)",
				"requires": {"Basalt Rock": 10, "Regolith": 5},
				"effects": [
					{"type": "resource", "id": "Basalt Rock", "amount": -10},
					{"type": "resource", "id": "Regolith", "amount": -5},
				],
				"result": "The rover is repaired and running smoothly.",
			},
			{
				"text": "Push on without repairs",
				"requires": {},
				"effects": [
					{"type": "disable_generator", "target": "any", "count": 1, "duration": 50.0},
				],
				"result": "The strain takes its toll. One generator is knocked offline for 50 seconds.",
			},
		],
	},
	"Marsquake": {
		"title": "Marsquake",
		"description": "The ground starts to shake beneath the outpost.",
		"weight": 0.7,
		"options": [
			{
				"text": "Brace the structures (Requires: 20 Basalt Rock)",
				"requires": {"Basalt Rock": 20},
				"effects": [
					{"type": "resource", "id": "Basalt Rock", "amount": -20},
				],
				"result": "The supports hold, and the quake passes.",
			},
			{
				"text": "Evacuate the area and wait",
				"requires": {},
				"effects": [
					{"type": "destroy_generator", "target": "any", "count": 1},
					{"type": "resource", "id": "Regolith", "amount": -10},
				],
				"result": "The quake cracks a building beyond repair and scatters some regolith.",
			},
		],
	},
	"Supply Capsule": {
		"title": "Supply Capsule",
		"description": "A supply capsule has landed a short distance from the base.",
		"weight": 0.6,
		"options": [
			{
				"text": "Open the capsule carefully",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": 15},
					{"type": "resource", "id": "water", "amount": 15},
				],
				"result": "The capsule holds energy cells and water.",
			},
			{
				"text": "Cut it open with a torch (Requires: 5 Energy)",
				"requires": {"energy": 5},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -5},
					{"type": "resource", "id": "energy", "amount": 30},
					{"type": "resource", "id": "water", "amount": 30},
				],
				"result": "The torch gets at the supplies. Double the loot.",
			},
		],
	},
	"Static Discharge": {
		"title": "Static Discharge",
		"description": "Electric static is building up in the dust around the base.",
		"weight": 0.9,
		"options": [
			{
				"text": "Ground the buildings (Requires: 10 Regolith)",
				"requires": {"Regolith": 10},
				"effects": [
					{"type": "resource", "id": "Regolith", "amount": -10},
				],
				"result": "The discharge goes harmlessly into the ground.",
			},
			{
				"text": "Wait it out",
				"requires": {},
				"effects": [
					{"type": "resource", "id": "energy", "amount": -12},
					{"type": "disable_generator", "target": "water", "count": 1, "duration": 35.0},
				],
				"result": "Sparks arc across the base and the water generator trips offline for 35 seconds.",
			},
		],
	},
}

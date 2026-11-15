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
##           "target" is a generator resource_id (Resources.ENERGY, Resources.WATER...) or "any".
##           "duration" <= 0 means the generator stays off permanently.
##       "result":   text shown after choosing.
##
## To add an event: add an entry here. No other file needs to change.
##
## BALANCE (tools/balance_sim.py reads this file and lints it):
##   - Every event keeps one option with "requires": {} so it can never dead-end.
##   - HAZARD events: option 1 is the protective option (costs Basalt / Regolith / Energy),
##     option 2 is free but hurts (disables or destroys a generator). Protective costs are
##     about 20-40 s of mid-game income, so early events are hard to afford and late ones are not.
##   - OPPORTUNITY events (last six): optional trades that turn one mineral into others.
##     Ignoring them costs nothing, so drawing one early never punishes the player.
##   - The button text repeats the numbers in "requires"; keep them in sync (the lint checks it).

const DATA := {
	# ---------------------------------------------------------------- hazards
	"Dust Storm": {
		"title": "Dust Storm",
		"description": "A Dust Storm Approaches",
		"weight": 1.0,
		"options": [
			{
				"text": "Reinforce your generators (Requires: 50 Basalt Rock and 25 Regolith)",
				"requires": {Resources.BASALT_ROCK: 50, Resources.REGOLITH: 25},
				"effects": [
					{"type": "resource", "id": Resources.BASALT_ROCK, "amount": -50},
					{"type": "resource", "id": Resources.REGOLITH, "amount": -25},
				],
				"result": "The reinforced generators ride out the storm. You used 50 Basalt Rock and 25 Regolith.",
			},
			{
				"text": "Squeeze extra power out of the storm",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": 40},
					{"type": "disable_generator", "target": Resources.ENERGY, "count": 1, "duration": 45.0},
				],
				"result": "You gain 40 energy, but a generator jams for 45 seconds.",
			},
		],
	},
	"Structural Failure": {
		"title": "Structural Failure",
		"description": "Stress fractures are spreading through one of the outpost's support beams.",
		"weight": 1.0,
		"options": [
			{
				"text": "Reinforce the beam (Requires: 60 Basalt Rock)",
				"requires": {Resources.BASALT_ROCK: 60},
				"effects": [
					{"type": "resource", "id": Resources.BASALT_ROCK, "amount": -60},
				],
				"result": "The beam is reinforced. You used 60 Basalt Rock.",
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
				"text": "Raise a debris shield (Requires: 100 Basalt Rock and 50 Regolith)",
				"requires": {Resources.BASALT_ROCK: 100, Resources.REGOLITH: 50},
				"effects": [
					{"type": "resource", "id": Resources.BASALT_ROCK, "amount": -100},
					{"type": "resource", "id": Resources.REGOLITH, "amount": -50},
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
				"text": "Shut down non-essential systems (Requires: 100 Energy)",
				"requires": {Resources.ENERGY: 100},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -100},
					{"type": "disable_generator", "target": Resources.ENERGY, "count": 1, "duration": 20.0},
				],
				"result": "You power down in time. The generator restarts after 20 seconds.",
			},
			{
				"text": "Ride it out",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -75},
					{"type": "disable_generator", "target": Resources.ENERGY, "count": 2, "duration": 45.0},
				],
				"result": "The flare fries the circuits. Energy is lost and two generators go offline for 45 seconds.",
			},
		],
	},
	"Water Leak": {
		"title": "Water Leak",
		"description": "Pressure is dropping in the water lines. Somewhere there is a leak.",
		"weight": 1.0,
		"options": [
			{
				"text": "Patch the pipes (Requires: 50 Regolith)",
				"requires": {Resources.REGOLITH: 50},
				"effects": [
					{"type": "resource", "id": Resources.REGOLITH, "amount": -50},
					{"type": "resource", "id": Resources.WATER, "amount": -25},
				],
				"result": "The leak is sealed quickly. Only a little water escapes.",
			},
			{
				"text": "Ignore it and keep working",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.WATER, "amount": -100},
					{"type": "disable_generator", "target": Resources.WATER, "count": 1, "duration": 40.0},
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
				"text": "Divert power to storage (Requires: 60 Energy)",
				"requires": {Resources.ENERGY: 60},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -60},
				],
				"result": "The surge is absorbed. A small amount of energy is lost.",
			},
			{
				"text": "Let it pass through the grid",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -50},
					{"type": "disable_generator", "target": Resources.ENERGY, "count": 1, "duration": 45.0},
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
				"text": "Repair it with spare parts (Requires: 60 Basalt Rock and 30 Regolith)",
				"requires": {Resources.BASALT_ROCK: 60, Resources.REGOLITH: 30},
				"effects": [
					{"type": "resource", "id": Resources.BASALT_ROCK, "amount": -60},
					{"type": "resource", "id": Resources.REGOLITH, "amount": -30},
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
				"text": "Brace the structures (Requires: 125 Basalt Rock)",
				"requires": {Resources.BASALT_ROCK: 125},
				"effects": [
					{"type": "resource", "id": Resources.BASALT_ROCK, "amount": -125},
				],
				"result": "The supports hold, and the quake passes.",
			},
			{
				"text": "Evacuate the area and wait",
				"requires": {},
				"effects": [
					{"type": "destroy_generator", "target": "any", "count": 1},
					{"type": "resource", "id": Resources.REGOLITH, "amount": -60},
				],
				"result": "The quake cracks a building beyond repair and scatters some regolith.",
			},
		],
	},
	"Static Discharge": {
		"title": "Static Discharge",
		"description": "Electric static is building up in the dust around the base.",
		"weight": 0.9,
		"options": [
			{
				"text": "Ground the buildings (Requires: 60 Regolith)",
				"requires": {Resources.REGOLITH: 60},
				"effects": [
					{"type": "resource", "id": Resources.REGOLITH, "amount": -60},
				],
				"result": "The discharge goes harmlessly into the ground.",
			},
			{
				"text": "Wait it out",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -60},
					{"type": "disable_generator", "target": Resources.WATER, "count": 1, "duration": 35.0},
				],
				"result": "Sparks arc across the base and the water generator trips offline for 35 seconds.",
			},
		],
	},
	# ---------------------------------------------------------------- opportunities
	"Supply Capsule": {
		"title": "Supply Capsule",
		"description": "A supply capsule has landed a short distance from the base.",
		"weight": 0.6,
		"options": [
			{
				"text": "Open the capsule carefully",
				"requires": {},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": 40},
					{"type": "resource", "id": Resources.WATER, "amount": 40},
				],
				"result": "The capsule holds energy cells and water.",
			},
			{
				"text": "Cut it open with a torch (Requires: 10 Energy)",
				"requires": {Resources.ENERGY: 10},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -10},
					{"type": "resource", "id": Resources.ENERGY, "amount": 80},
					{"type": "resource", "id": Resources.WATER, "amount": 80},
				],
				"result": "The torch gets at the supplies. Double the loot.",
			},
		],
	},
	"Ore Vein": {
		"title": "Ore Vein",
		"description": "Surveyors have spotted a rich iron vein just under the surface.",
		"weight": 0.5,
		"options": [
			{
				"text": "Blast it open (Requires: 40 Energy)",
				"requires": {Resources.ENERGY: 40},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -40},
					{"type": "resource", "id": Resources.IRON_ORE, "amount": 30},
				],
				"result": "The vein gives up 30 Iron Ore.",
			},
			{
				"text": "Mark it and move on",
				"requires": {},
				"effects": [],
				"result": "You mark the spot for later.",
			},
		],
	},
	"Ice Cavern": {
		"title": "Ice Cavern",
		"description": "A rover has found a cavern lined with frozen water.",
		"weight": 0.5,
		"options": [
			{
				"text": "Cut out the ice (Requires: 30 Energy and 20 Iron Ore)",
				"requires": {Resources.ENERGY: 30, Resources.IRON_ORE: 20},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -30},
					{"type": "resource", "id": Resources.IRON_ORE, "amount": -20},
					{"type": "resource", "id": Resources.ICE, "amount": 40},
				],
				"result": "The drill bites in. You haul out 40 Ice.",
			},
			{
				"text": "Leave it for now",
				"requires": {},
				"effects": [],
				"result": "The cavern will have to wait.",
			},
		],
	},
	"Metal Meteorite": {
		"title": "Metal Meteorite",
		"description": "A meteorite rich in light metals has landed nearby.",
		"weight": 0.4,
		"options": [
			{
				"text": "Recover it (Requires: 30 Energy and 15 Ice)",
				"requires": {Resources.ENERGY: 30, Resources.ICE: 15},
				"effects": [
					{"type": "resource", "id": Resources.ENERGY, "amount": -30},
					{"type": "resource", "id": Resources.ICE, "amount": -15},
					{"type": "resource", "id": Resources.TITANIUM, "amount": 20},
					{"type": "resource", "id": Resources.ALUMINUM, "amount": 20},
				],
				"result": "Coolant keeps the metal workable. You recover 20 Titanium and 20 Aluminum.",
			},
			{
				"text": "Let it cool, then ignore it",
				"requires": {},
				"effects": [],
				"result": "The meteorite sits where it fell.",
			},
		],
	},
	"Hydrothermal Vent": {
		"title": "Hydrothermal Vent",
		"description": "A vent is venting mineral-rich steam not far from the base.",
		"weight": 0.4,
		"options": [
			{
				"text": "Collect samples (Requires: 25 Titanium and 20 Water)",
				"requires": {Resources.TITANIUM: 25, Resources.WATER: 20},
				"effects": [
					{"type": "resource", "id": Resources.TITANIUM, "amount": -25},
					{"type": "resource", "id": Resources.WATER, "amount": -20},
					{"type": "resource", "id": Resources.SULFUR, "amount": 20},
					{"type": "resource", "id": Resources.GYPSUM, "amount": 20},
				],
				"result": "Titanium collectors survive the heat. You gather 20 Sulfur and 20 Gypsum.",
			},
			{
				"text": "Keep your distance",
				"requires": {},
				"effects": [],
				"result": "The vent keeps steaming.",
			},
		],
	},
	"Dry Lake Bed": {
		"title": "Dry Lake Bed",
		"description": "Survey drones have mapped an ancient lake bed crusted with salts.",
		"weight": 0.4,
		"options": [
			{
				"text": "Harvest the crust (Requires: 25 Sulfur and 25 Gypsum)",
				"requires": {Resources.SULFUR: 25, Resources.GYPSUM: 25},
				"effects": [
					{"type": "resource", "id": Resources.SULFUR, "amount": -25},
					{"type": "resource", "id": Resources.GYPSUM, "amount": -25},
					{"type": "resource", "id": Resources.SOLUBLE_SALTS, "amount": 25},
					{"type": "resource", "id": Resources.NICKEL, "amount": 15},
				],
				"result": "Processing yields 25 Soluble Salts and 15 Nickel.",
			},
			{
				"text": "Leave it for the dust",
				"requires": {},
				"effects": [],
				"result": "Wind slowly covers the lake bed again.",
			},
		],
	},
}

class_name AnimalDefs
extends RefCounted

# DS-006: Animal definitions per spec §8 (MVP: chickens, cows only).

const ANIMALS: Dictionary = {
	"chicken": {
		"display_name": "Chicken",
		"max_health": 20,
		"feed_per_min": 0.5,
		"product_item": "egg",
		"product_seconds": 60.0,         # spec: 30 min — shortened for testing
		"slaughter_yields": [{"item_type": "meat_raw", "quantity": 1}],
		"capture_difficulty": 0.3,        # 30% base + skill bonus
		"color": Color(0.95, 0.95, 0.85),
	},
	"cow": {
		"display_name": "Cow",
		"max_health": 80,
		"feed_per_min": 2.0,
		"product_item": "milk",
		"product_seconds": 240.0,
		"slaughter_yields": [
			{"item_type": "meat_raw", "quantity": 5},
			{"item_type": "leather", "quantity": 2},
		],
		"capture_difficulty": 0.5,
		"color": Color(0.5, 0.35, 0.25),
	},
}


static func get_animal(animal_id: String) -> Dictionary:
	if ANIMALS.has(animal_id):
		var a: Dictionary = ANIMALS[animal_id].duplicate(true)
		a["id"] = animal_id
		return a
	return {}

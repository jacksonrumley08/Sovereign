class_name CropDefs
extends RefCounted

# DS-006: Crop definitions per spec §7.1.
# growth_seconds, yield_item, yield_qty, season modifiers (1.0 summer / 0.0 winter for crops)

const CROPS: Dictionary = {
	"wheat": {
		"display_name": "Wheat",
		"seed_item": "seed_wheat",
		"yield_item": "wheat",
		"yield_qty": 3,
		"growth_seconds": 180.0,  # 3 min for testing (spec: 3-4 hr)
		"category": "grain",
	},
	"barley": {
		"display_name": "Barley",
		"seed_item": "seed_barley",
		"yield_item": "barley",
		"yield_qty": 3,
		"growth_seconds": 180.0,
		"category": "grain",
	},
	"carrot": {
		"display_name": "Carrot",
		"seed_item": "seed_carrot",
		"yield_item": "carrot",
		"yield_qty": 4,
		"growth_seconds": 120.0,
		"category": "vegetable",
	},
}


static func get_crop(crop_id: String) -> Dictionary:
	if CROPS.has(crop_id):
		var c: Dictionary = CROPS[crop_id].duplicate()
		c["id"] = crop_id
		return c
	return {}


static func crop_for_seed(seed_item_type: String) -> String:
	for id in CROPS.keys():
		if CROPS[id]["seed_item"] == seed_item_type:
			return id
	return ""

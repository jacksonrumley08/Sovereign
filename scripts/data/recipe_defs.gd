class_name RecipeDefs
extends RefCounted

# DS-002: Recipe definitions. Each recipe has:
# id, output, output_quantity, materials[], station, skill, skill_req, craft_time

# Stations: "inventory" (no station needed), "workbench", "forge", "campfire", "loom"

const RECIPES: Dictionary = {
	# --- Inventory crafts (no station) ---
	"flint_knife": {
		"output": "flint_knife", "output_quantity": 1,
		"materials": [{"item_type": "flint", "quantity": 2}, {"item_type": "stick", "quantity": 1}, {"item_type": "fiber", "quantity": 1}],
		"station": "inventory", "skill": "smithing", "skill_req": 0, "craft_time": 3.0,
	},
	"stone_axe": {
		"output": "stone_axe", "output_quantity": 1,
		"materials": [{"item_type": "flint", "quantity": 2}, {"item_type": "stick", "quantity": 1}, {"item_type": "fiber", "quantity": 1}],
		"station": "inventory", "skill": "carpentry", "skill_req": 0, "craft_time": 3.0,
	},
	"stone_pickaxe": {
		"output": "stone_pickaxe", "output_quantity": 1,
		"materials": [{"item_type": "flint", "quantity": 2}, {"item_type": "stick", "quantity": 1}, {"item_type": "fiber", "quantity": 1}],
		"station": "inventory", "skill": "masonry", "skill_req": 0, "craft_time": 3.0,
	},
	"rope": {
		"output": "rope", "output_quantity": 1,
		"materials": [{"item_type": "fiber", "quantity": 5}],
		"station": "inventory", "skill": "tailoring", "skill_req": 0, "craft_time": 2.0,
	},
	"bandage": {
		"output": "bandage", "output_quantity": 2,
		"materials": [{"item_type": "fiber", "quantity": 3}],
		"station": "inventory", "skill": "alchemy", "skill_req": 0, "craft_time": 2.0,
	},

	# --- Workbench crafts ---
	"plank": {
		"output": "plank", "output_quantity": 2,
		"materials": [{"item_type": "wood_log", "quantity": 1}],
		"station": "workbench", "skill": "carpentry", "skill_req": 0, "craft_time": 2.0,
	},
	"hammer": {
		"output": "hammer", "output_quantity": 1,
		"materials": [{"item_type": "stone", "quantity": 2}, {"item_type": "stick", "quantity": 1}],
		"station": "workbench", "skill": "carpentry", "skill_req": 0, "craft_time": 3.0,
	},
	"short_bow": {
		"output": "short_bow", "output_quantity": 1,
		"materials": [{"item_type": "wood_log", "quantity": 2}, {"item_type": "fiber", "quantity": 2}],
		"station": "workbench", "skill": "fletching", "skill_req": 25, "craft_time": 8.0,
	},

	# --- Forge crafts ---
	"bronze_axe": {
		"output": "bronze_axe", "output_quantity": 1,
		"materials": [{"item_type": "copper_ore", "quantity": 3}, {"item_type": "tin_ore", "quantity": 1}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 25, "craft_time": 10.0,
	},
	"iron_axe": {
		"output": "iron_axe", "output_quantity": 1,
		"materials": [{"item_type": "iron_ore", "quantity": 4}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 50, "craft_time": 15.0,
	},
	"bronze_pickaxe": {
		"output": "bronze_pickaxe", "output_quantity": 1,
		"materials": [{"item_type": "copper_ore", "quantity": 3}, {"item_type": "tin_ore", "quantity": 1}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 25, "craft_time": 10.0,
	},
	"iron_pickaxe": {
		"output": "iron_pickaxe", "output_quantity": 1,
		"materials": [{"item_type": "iron_ore", "quantity": 4}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 50, "craft_time": 15.0,
	},
	"bronze_sword": {
		"output": "bronze_sword", "output_quantity": 1,
		"materials": [{"item_type": "copper_ore", "quantity": 3}, {"item_type": "tin_ore", "quantity": 1}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 25, "craft_time": 10.0,
	},
	"iron_sword": {
		"output": "iron_sword", "output_quantity": 1,
		"materials": [{"item_type": "iron_ore", "quantity": 4}, {"item_type": "stick", "quantity": 1}],
		"station": "forge", "skill": "smithing", "skill_req": 50, "craft_time": 15.0,
	},

	# --- Campfire (cooking) ---
	"meat_cooked": {
		"output": "meat_cooked", "output_quantity": 1,
		"materials": [{"item_type": "meat_raw", "quantity": 1}],
		"station": "campfire", "skill": "cooking", "skill_req": 0, "craft_time": 5.0,
	},
}


static func get_recipe(recipe_id: String) -> Dictionary:
	if RECIPES.has(recipe_id):
		var r: Dictionary = RECIPES[recipe_id].duplicate(true)
		r["id"] = recipe_id
		return r
	return {}


static func recipes_for_station(station: String) -> Array:
	var result: Array = []
	for id in RECIPES.keys():
		if RECIPES[id]["station"] == station or RECIPES[id]["station"] == "inventory":
			var r: Dictionary = RECIPES[id].duplicate(true)
			r["id"] = id
			result.append(r)
	return result

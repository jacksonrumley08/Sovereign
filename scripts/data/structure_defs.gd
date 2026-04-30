class_name StructureDefs
extends RefCounted

# DS-003: Structure definitions. Used by BuildMenu, BlueprintPlacer, completion.

const STRUCTURES: Dictionary = {
	"workbench": {
		"display_name": "Workbench",
		"size": Vector3(1.5, 1.0, 1.0),
		"max_health": 200,
		"materials": [{"item_type": "wood_log", "quantity": 4}],
		"skill": "carpentry", "skill_req": 0,
		"station_type": "workbench",
		"color": Color(0.45, 0.3, 0.18),
	},
	"forge": {
		"display_name": "Forge",
		"size": Vector3(1.8, 1.5, 1.5),
		"max_health": 400,
		"materials": [{"item_type": "stone", "quantity": 8}, {"item_type": "wood_log", "quantity": 2}],
		"skill": "masonry", "skill_req": 25,
		"station_type": "forge",
		"color": Color(0.4, 0.4, 0.42),
	},
	"campfire": {
		"display_name": "Campfire",
		"size": Vector3(1.0, 0.4, 1.0),
		"max_health": 80,
		"materials": [{"item_type": "stone", "quantity": 4}, {"item_type": "wood_log", "quantity": 2}],
		"skill": "carpentry", "skill_req": 0,
		"station_type": "campfire",
		"color": Color(0.5, 0.2, 0.1),
	},
	"wall_wood": {
		"display_name": "Wood Wall",
		"size": Vector3(2.0, 2.5, 0.3),
		"max_health": 250,
		"materials": [{"item_type": "plank", "quantity": 4}],
		"skill": "carpentry", "skill_req": 0,
		"station_type": "",
		"color": Color(0.55, 0.4, 0.22),
	},
	"wall_stone": {
		"display_name": "Stone Wall",
		"size": Vector3(2.0, 2.5, 0.4),
		"max_health": 600,
		"materials": [{"item_type": "stone", "quantity": 4}],
		"skill": "masonry", "skill_req": 25,
		"station_type": "",
		"color": Color(0.55, 0.55, 0.55),
	},
	"floor_wood": {
		"display_name": "Wood Floor",
		"size": Vector3(2.0, 0.2, 2.0),
		"max_health": 150,
		"materials": [{"item_type": "plank", "quantity": 3}],
		"skill": "carpentry", "skill_req": 0,
		"station_type": "",
		"color": Color(0.55, 0.4, 0.22),
	},
	"door_wood": {
		"display_name": "Wood Door",
		"size": Vector3(1.0, 2.0, 0.2),
		"max_health": 120,
		"materials": [{"item_type": "plank", "quantity": 3}],
		"skill": "carpentry", "skill_req": 25,
		"station_type": "",
		"color": Color(0.6, 0.45, 0.25),
	},
	"hearthstone": {
		"display_name": "Hearthstone",
		"size": Vector3(1.0, 1.2, 1.0),
		"max_health": 1000,
		"materials": [{"item_type": "stone", "quantity": 8}, {"item_type": "wood_log", "quantity": 2}],
		"skill": "masonry", "skill_req": 0,
		"station_type": "",
		"color": Color(0.7, 0.65, 0.5),
	},
	"farm_plot": {
		"display_name": "Farm Plot",
		"size": Vector3(2.0, 0.1, 2.0),
		"max_health": 50,
		"materials": [{"item_type": "wood_log", "quantity": 1}],
		"skill": "farming", "skill_req": 0,
		"station_type": "",
		"color": Color(0.35, 0.2, 0.1),
		"variant": "farm_plot",
	},
	"animal_pen": {
		"display_name": "Animal Pen",
		"size": Vector3(4.0, 1.2, 4.0),
		"max_health": 200,
		"materials": [{"item_type": "wood_log", "quantity": 6}, {"item_type": "fiber", "quantity": 4}],
		"skill": "carpentry", "skill_req": 0,
		"station_type": "",
		"color": Color(0.55, 0.4, 0.22),
		"variant": "animal_pen",
	},
	"throne": {
		"display_name": "Throne",
		"size": Vector3(1.5, 2.0, 1.5),
		"max_health": 2000,
		"materials": [{"item_type": "iron_ore", "quantity": 8}, {"item_type": "plank", "quantity": 6}],
		"skill": "masonry", "skill_req": 50,
		"station_type": "throne",
		"color": Color(0.5, 0.3, 0.6),
	},
	"marketplace_stall": {
		"display_name": "Marketplace Stall",
		"size": Vector3(2.0, 1.5, 1.5),
		"max_health": 200,
		"materials": [{"item_type": "plank", "quantity": 6}, {"item_type": "fiber", "quantity": 2}],
		"skill": "carpentry", "skill_req": 25,
		"station_type": "marketplace",
		"color": Color(0.7, 0.5, 0.2),
	},
}


static func get_structure(structure_id: String) -> Dictionary:
	if STRUCTURES.has(structure_id):
		var s: Dictionary = STRUCTURES[structure_id].duplicate(true)
		s["id"] = structure_id
		return s
	return {}


static func all_buildable() -> Array:
	var result: Array = []
	for id in STRUCTURES.keys():
		var s: Dictionary = STRUCTURES[id].duplicate(true)
		s["id"] = id
		result.append(s)
	return result

class_name ItemDefs
extends RefCounted

# DS-001: Item definitions. Every item type lives here.
# Schema: display_name, weight, stackable, slot, category, durability, spoil_hours, damage_type, etc.

const ITEMS: Dictionary = {
	# --- Resources (gathered) ---
	"wood_log":   {"display_name": "Wood Log",   "weight": 2.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"plank":      {"display_name": "Plank",      "weight": 1.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"stone":      {"display_name": "Stone",      "weight": 3.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"copper_ore": {"display_name": "Copper Ore", "weight": 4.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"tin_ore":    {"display_name": "Tin Ore",    "weight": 4.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"iron_ore":   {"display_name": "Iron Ore",   "weight": 5.0,  "stackable": true,  "category": "resource", "slot": "none"},
	"flint":      {"display_name": "Flint",      "weight": 0.2,  "stackable": true,  "category": "resource", "slot": "none"},
	"fiber":      {"display_name": "Fiber",      "weight": 0.1,  "stackable": true,  "category": "resource", "slot": "none"},
	"stick":      {"display_name": "Stick",      "weight": 0.3,  "stackable": true,  "category": "resource", "slot": "none"},
	"berries":    {"display_name": "Berries",    "weight": 0.2,  "stackable": true,  "category": "food",     "slot": "none", "spoil_hours": 4},
	"meat_raw":   {"display_name": "Raw Meat",   "weight": 1.0,  "stackable": true,  "category": "food",     "slot": "none", "spoil_hours": 3},
	"meat_cooked":{"display_name": "Cooked Meat","weight": 0.8,  "stackable": true,  "category": "food",     "slot": "none", "spoil_hours": 10},
	"egg":        {"display_name": "Egg",        "weight": 0.1,  "stackable": true,  "category": "food",     "slot": "none", "spoil_hours": 24},
	"milk":       {"display_name": "Milk",       "weight": 0.5,  "stackable": true,  "category": "food",     "slot": "none", "spoil_hours": 12},
	"leather":    {"display_name": "Leather",    "weight": 0.4,  "stackable": true,  "category": "resource", "slot": "none"},
	"manure":     {"display_name": "Manure",     "weight": 0.5,  "stackable": true,  "category": "resource", "slot": "none"},

	# --- Crops (harvested) ---
	"wheat":      {"display_name": "Wheat",   "weight": 0.2,  "stackable": true, "category": "food", "slot": "none", "spoil_hours": 48},
	"barley":     {"display_name": "Barley",  "weight": 0.2,  "stackable": true, "category": "food", "slot": "none", "spoil_hours": 48},
	"carrot":     {"display_name": "Carrot",  "weight": 0.2,  "stackable": true, "category": "food", "slot": "none", "spoil_hours": 24},

	# --- Seeds (plantable) ---
	"seed_wheat":  {"display_name": "Wheat Seed",  "weight": 0.05, "stackable": true, "category": "seed", "slot": "none"},
	"seed_barley": {"display_name": "Barley Seed", "weight": 0.05, "stackable": true, "category": "seed", "slot": "none"},
	"seed_carrot": {"display_name": "Carrot Seed", "weight": 0.05, "stackable": true, "category": "seed", "slot": "none"},

	# --- Animal husbandry ---
	"animal_feed": {"display_name": "Animal Feed", "weight": 0.3, "stackable": true, "category": "resource", "slot": "none"},

	# --- Tools ---
	"stone_axe":     {"display_name": "Stone Axe",     "weight": 1.5, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 30,  "tool_type": "axe"},
	"bronze_axe":    {"display_name": "Bronze Axe",    "weight": 1.8, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 80,  "tool_type": "axe"},
	"iron_axe":      {"display_name": "Iron Axe",      "weight": 2.0, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 150, "tool_type": "axe"},
	"stone_pickaxe": {"display_name": "Stone Pickaxe", "weight": 1.8, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 30,  "tool_type": "pickaxe"},
	"bronze_pickaxe":{"display_name": "Bronze Pickaxe","weight": 2.0, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 80,  "tool_type": "pickaxe"},
	"iron_pickaxe":  {"display_name": "Iron Pickaxe",  "weight": 2.2, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 150, "tool_type": "pickaxe"},
	"hammer":        {"display_name": "Hammer",        "weight": 1.0, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 100, "tool_type": "hammer"},
	"bucket":        {"display_name": "Bucket",        "weight": 1.0, "stackable": false, "category": "tool", "slot": "main_hand", "durability": 50,  "tool_type": "bucket"},
	"rope":          {"display_name": "Rope",          "weight": 0.5, "stackable": true,  "category": "tool", "slot": "none"},
	"bandage":       {"display_name": "Bandage",       "weight": 0.1, "stackable": true,  "category": "consumable", "slot": "none"},
	"torch":         {"display_name": "Torch",         "weight": 0.5, "stackable": false, "category": "tool", "slot": "off_hand", "durability": 100},

	# --- Weapons reference WeaponDefs for stats; declare slots/weight here ---
	"flint_knife":   {"display_name": "Flint Knife",   "weight": 0.6, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 30,  "damage_type": "slash"},
	"bronze_sword":  {"display_name": "Bronze Sword",  "weight": 1.5, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 80,  "damage_type": "slash"},
	"iron_sword":    {"display_name": "Iron Sword",    "weight": 1.8, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 150, "damage_type": "slash"},
	"bronze_spear":  {"display_name": "Bronze Spear",  "weight": 2.0, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 60,  "damage_type": "pierce"},
	"iron_spear":    {"display_name": "Iron Spear",    "weight": 2.2, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 120, "damage_type": "pierce"},
	"bronze_mace":   {"display_name": "Bronze Mace",   "weight": 2.5, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 100, "damage_type": "blunt"},
	"iron_mace":     {"display_name": "Iron Mace",     "weight": 3.0, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 180, "damage_type": "blunt"},
	"short_bow":     {"display_name": "Short Bow",     "weight": 1.0, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 50,  "damage_type": "pierce"},
	"crossbow":      {"display_name": "Crossbow",      "weight": 2.5, "stackable": false, "category": "weapon", "slot": "main_hand", "durability": 70,  "damage_type": "pierce"},
	"kite_shield":   {"display_name": "Kite Shield",   "weight": 4.0, "stackable": false, "category": "shield", "slot": "off_hand", "durability": 120},
}


static func get_item(item_type: String) -> Dictionary:
	if ITEMS.has(item_type):
		return ITEMS[item_type]
	return {}


static func has(item_type: String) -> bool:
	return ITEMS.has(item_type)

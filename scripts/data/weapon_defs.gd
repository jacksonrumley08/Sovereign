class_name WeaponDefs
extends RefCounted

# DS-005: Weapon stat definitions per spec §4.5.

const WEAPONS: Dictionary = {
	"unarmed": {
		"display_name": "Unarmed",
		"damage": 4, "speed": 0.5, "stamina_cost": 3,
		"range": 1.0, "durability": -1,
		"damage_type": "blunt", "category": "melee",
		"skill": "melee_weapons",
	},
	"flint_knife": {
		"display_name": "Flint Knife",
		"damage": 8, "speed": 0.4, "stamina_cost": 5,
		"range": 1.0, "durability": 30,
		"damage_type": "slash", "category": "melee",
		"skill": "melee_weapons",
	},
	"bronze_sword": {
		"display_name": "Bronze Sword",
		"damage": 18, "speed": 0.6, "stamina_cost": 12,
		"range": 1.5, "durability": 80,
		"damage_type": "slash", "category": "melee",
		"skill": "melee_weapons",
	},
	"iron_sword": {
		"display_name": "Iron Sword",
		"damage": 25, "speed": 0.6, "stamina_cost": 14,
		"range": 1.5, "durability": 150,
		"damage_type": "slash", "category": "melee",
		"skill": "melee_weapons",
	},
	"bronze_spear": {
		"display_name": "Bronze Spear",
		"damage": 15, "speed": 0.8, "stamina_cost": 15,
		"range": 2.5, "durability": 60,
		"damage_type": "pierce", "category": "melee",
		"skill": "melee_weapons",
	},
	"iron_spear": {
		"display_name": "Iron Spear",
		"damage": 22, "speed": 0.8, "stamina_cost": 17,
		"range": 2.5, "durability": 120,
		"damage_type": "pierce", "category": "melee",
		"skill": "melee_weapons",
	},
	"bronze_mace": {
		"display_name": "Bronze Mace",
		"damage": 20, "speed": 0.8, "stamina_cost": 18,
		"range": 1.2, "durability": 100,
		"damage_type": "blunt", "category": "melee",
		"skill": "melee_weapons",
	},
	"iron_mace": {
		"display_name": "Iron Mace",
		"damage": 30, "speed": 0.8, "stamina_cost": 22,
		"range": 1.2, "durability": 180,
		"damage_type": "blunt", "category": "melee",
		"skill": "melee_weapons",
	},
	"short_bow": {
		"display_name": "Short Bow",
		"damage": 12, "speed": 0.8, "stamina_cost": 8,
		"range": 30.0, "durability": 50,
		"damage_type": "pierce", "category": "ranged",
		"skill": "ranged_weapons", "projectile_speed": 25.0,
	},
	"crossbow": {
		"display_name": "Crossbow",
		"damage": 28, "speed": 2.0, "stamina_cost": 10,
		"range": 45.0, "durability": 70,
		"damage_type": "pierce", "category": "ranged",
		"skill": "ranged_weapons", "projectile_speed": 35.0,
	},
}


static func get_weapon(weapon_id: String) -> Dictionary:
	if WEAPONS.has(weapon_id):
		return WEAPONS[weapon_id]
	return WEAPONS["unarmed"]

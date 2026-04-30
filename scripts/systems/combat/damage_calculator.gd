class_name DamageCalculator
extends RefCounted

# CO-006: Pure-function damage calc per spec §2.2.
# Tier × skill × zone × armor × block.

const ARMOR_RESIST: Dictionary = {
	"none":         {"slash": 0.0,  "blunt": 0.0,  "pierce": 0.0},
	"leather":      {"slash": 0.20, "blunt": 0.10, "pierce": 0.15},
	"bronze_plate": {"slash": 0.40, "blunt": 0.20, "pierce": 0.35},
	"iron_plate":   {"slash": 0.55, "blunt": 0.30, "pierce": 0.50},
}


static func calculate_damage(
	base_damage: int,
	attack_tier: int,        # 0=jab, 1=normal, 2=heavy
	weapon_type: String,     # "slash", "blunt", "pierce"
	hit_zone: String,        # "head", "torso", "left_arm", etc.
	armor_type: String,      # "none", "leather", "bronze_plate", "iron_plate"
	attacker_skill: int,     # melee/ranged weapon skill 0-100
	is_blocked: bool,
	shield_type: String      # "none", "kite"
) -> Dictionary:
	var damage: float = float(base_damage)

	# Tier multiplier
	match attack_tier:
		0: damage *= 0.5  # jab
		1: damage *= 1.0  # normal
		2: damage *= 1.5  # heavy

	# Skill bonus (up to +30% at level 100)
	damage *= 1.0 + (attacker_skill * 0.003)

	# Zone multiplier
	damage *= _get_zone_multiplier(hit_zone)

	# Armor resistance
	damage *= 1.0 - _get_armor_resistance(armor_type, weapon_type)

	# Block reduction
	var stamina_cost: float = 0.0
	if is_blocked:
		damage *= 0.2  # blocks reduce 80%
		stamina_cost = _get_shield_block_cost(shield_type)

	return {
		"final_damage": int(damage),
		"hit_zone": hit_zone,
		"injury_type": _determine_injury(damage),
		"blocked": is_blocked,
		"block_stamina_cost": stamina_cost,
	}


static func _get_zone_multiplier(zone: String) -> float:
	match zone:
		"head": return 2.0
		"torso": return 1.0
		"left_arm", "right_arm": return 0.7
		"left_leg", "right_leg": return 0.8
	return 1.0


static func _get_armor_resistance(armor: String, damage_type: String) -> float:
	if ARMOR_RESIST.has(armor) and ARMOR_RESIST[armor].has(damage_type):
		return ARMOR_RESIST[armor][damage_type]
	return 0.0


static func _get_shield_block_cost(shield: String) -> float:
	match shield:
		"kite": return 8.0
	return 0.0


static func _determine_injury(damage: float) -> String:
	if damage < 15:
		return "none"
	elif damage < 30:
		return "minor"
	elif damage < 50:
		return "moderate"
	return "severe"


static func get_bleedout_time(injuries: Dictionary) -> float:
	if injuries.get("torso", "none") == "severe":
		return 15.0
	elif injuries.get("head", "none") == "severe":
		return 10.0
	elif injuries.get("torso", "none") == "moderate":
		return 30.0
	return 60.0

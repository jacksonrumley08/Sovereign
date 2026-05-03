class_name HitZoneSystem
extends RefCounted

# C-006: Determine which body zone a hit lands on.
# Inputs: attack direction (0-7 sector), attacker pos, defender pos, attack height (0-1).
# Output: zone string in {"head","torso","left_arm","right_arm","left_leg","right_leg"}.


static func determine_hit_zone(
	attack_direction: int,
	attacker_pos: Vector3,
	defender_pos: Vector3,
	attack_height: float
) -> String:
	# Vertical zone from attack height
	if attack_height > 0.8:
		return "head"
	elif attack_height > 0.4:
		# Mid: direction relative to defender's facing decides arm vs torso
		var attack_angle: float = _direction_to_angle(attack_direction)
		var rel: float = _relative_angle(attacker_pos, defender_pos, attack_angle)
		if rel < -30:
			return "left_arm"
		elif rel > 30:
			return "right_arm"
		return "torso"
	else:
		# Low: legs
		var attack_angle: float = _direction_to_angle(attack_direction)
		var rel: float = _relative_angle(attacker_pos, defender_pos, attack_angle)
		return "left_leg" if rel < 0 else "right_leg"


static func _direction_to_angle(dir: int) -> float:
	return dir * 45.0  # 0=N, 1=NE, 2=E, etc.


static func _relative_angle(attacker: Vector3, defender: Vector3, attack_angle: float) -> float:
	var to_def: Vector3 = (defender - attacker).normalized()
	var def_facing: float = atan2(to_def.x, to_def.z)
	return rad_to_deg(def_facing) - attack_angle

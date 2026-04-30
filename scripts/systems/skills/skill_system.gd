class_name SkillSystem
extends Node

# SK-001: Per-character skill XP tracking with level computation + 500 cap.

var levels: Dictionary = {}  # skill_name -> int
var xps: Dictionary = {}     # skill_name -> int

signal level_up(skill: String, new_level: int)
signal milestone_reached(skill: String, level: int)
signal xp_gained(skill: String, amount: int)


func _ready() -> void:
	for skill_name in SkillDefs.SKILLS.keys():
		levels[skill_name] = 1
		xps[skill_name] = 0


func add_xp(skill: String, amount: int) -> void:
	if not SkillDefs.SKILLS.has(skill):
		return
	if total_levels() >= SkillDefs.TOTAL_SKILL_CAP and levels[skill] >= SkillDefs.MAX_SKILL_LEVEL:
		return  # Cap reached for this skill
	xps[skill] += amount
	xp_gained.emit(skill, amount)
	var new_level: int = SkillDefs.level_from_xp(xps[skill])
	# Enforce 500-cap by ignoring levels beyond
	if total_levels() + (new_level - levels[skill]) > SkillDefs.TOTAL_SKILL_CAP:
		new_level = levels[skill]  # Freeze level if cap would exceed
	if new_level > levels[skill]:
		var old: int = levels[skill]
		levels[skill] = new_level
		level_up.emit(skill, new_level)
		# Milestone hooks
		for m in [25, 50, 75, 100]:
			if old < m and new_level >= m:
				milestone_reached.emit(skill, m)
				GameManager.log("info", "%s milestone L%d reached" % [skill, m])


func get_level(skill: String) -> int:
	return levels.get(skill, 1)


func get_xp(skill: String) -> int:
	return xps.get(skill, 0)


func total_levels() -> int:
	var total: int = 0
	for v in levels.values():
		total += v
	return total

class_name SkillDefs
extends RefCounted

# DS-004: All 22 skills + XP curve per spec §6.2.

const TOTAL_SKILL_CAP: int = 500
const MAX_SKILL_LEVEL: int = 100
const RESPEC_COOLDOWN_DAYS: int = 7

# Level N requires: floor(N^2 * 100 + N * 50) cumulative XP
# Level 100 total: ~1,005,000 XP
static func xp_for_level(level: int) -> int:
	var total: int = 0
	for i in range(1, level + 1):
		total += i * i * 100 + i * 50
	return total


static func level_from_xp(xp: int) -> int:
	var level: int = 1
	var total: int = 0
	while level < MAX_SKILL_LEVEL:
		var next: int = (level + 1) * (level + 1) * 100 + (level + 1) * 50
		if total + next > xp:
			break
		total += next
		level += 1
	return level


const SKILLS: Dictionary = {
	"mining":           {"category": "gathering", "display_name": "Mining"},
	"woodcutting":      {"category": "gathering", "display_name": "Woodcutting"},
	"farming":          {"category": "gathering", "display_name": "Farming"},
	"fishing":          {"category": "gathering", "display_name": "Fishing"},
	"herbalism":        {"category": "gathering", "display_name": "Herbalism"},
	"quarrying":        {"category": "gathering", "display_name": "Quarrying"},
	"smithing":         {"category": "crafting",  "display_name": "Smithing"},
	"carpentry":        {"category": "crafting",  "display_name": "Carpentry"},
	"masonry":          {"category": "crafting",  "display_name": "Masonry"},
	"leatherworking":   {"category": "crafting",  "display_name": "Leatherworking"},
	"cooking":          {"category": "crafting",  "display_name": "Cooking"},
	"tailoring":        {"category": "crafting",  "display_name": "Tailoring"},
	"alchemy":          {"category": "crafting",  "display_name": "Alchemy/Medicine"},
	"fletching":        {"category": "crafting",  "display_name": "Fletching"},
	"melee_weapons":    {"category": "combat",    "display_name": "Melee Weapons"},
	"ranged_weapons":   {"category": "combat",    "display_name": "Ranged Weapons"},
	"defense":          {"category": "combat",    "display_name": "Defense/Armor"},
	"tactics":          {"category": "combat",    "display_name": "Tactics"},
	"animal_husbandry": {"category": "labor",     "display_name": "Animal Husbandry"},
	"sailing":          {"category": "labor",     "display_name": "Sailing/Navigation"},
	"construction":     {"category": "labor",     "display_name": "Construction"},
	"trading":          {"category": "labor",     "display_name": "Trading"},
}

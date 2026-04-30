class_name KingdomSystem
extends Node

# K-001/002/005: Per-character kingdom membership + role + war state.
# Stub for P1 — real multiplayer-aware version lands in K-* tickets.

var current_kingdom: Dictionary = {}  # empty if no kingdom
var active_war: Dictionary = {}        # empty if not at war

signal kingdom_founded(name: String)
signal war_declared(against: String)


func has_kingdom() -> bool:
	return not current_kingdom.is_empty()


func found_kingdom(kingdom_name: String, throne_pos: Vector3) -> void:
	current_kingdom = {
		"name": kingdom_name,
		"sovereign": "you",
		"marshal": "",
		"chancellor": "",
		"treasurer": "",
		"steward": "",
		"tax_rate": 0.05,
		"throne_position": throne_pos,
		"created_at": Time.get_unix_time_from_system(),
	}
	GameManager.log("info", "Kingdom of %s founded" % kingdom_name)
	kingdom_founded.emit(kingdom_name)


func declare_war(against: String) -> void:
	if not has_kingdom():
		GameManager.log("warn", "Need a kingdom to declare war")
		return
	active_war = {
		"against": against,
		"declared_at": Time.get_unix_time_from_system(),
		"active_at": Time.get_unix_time_from_system() + 86400,  # 24-hour countdown
		"status": "preparing",
	}
	GameManager.log("info", "War declared on %s — buildings vulnerable in 24hrs" % against)
	war_declared.emit(against)


func is_at_war_with(other: String) -> bool:
	if active_war.is_empty():
		return false
	if active_war["against"] != other:
		return false
	return Time.get_unix_time_from_system() >= active_war.get("active_at", 0)

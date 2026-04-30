extends Node

# F-002 stub; F-003 populates the input map in project.godot.
# F-007 (post-MVP) adds rebind UI; for now this just exposes load/save hooks.

const SETTINGS_PATH: String = "user://input_remap.cfg"


func _ready() -> void:
	_load_remap()


func _load_remap() -> void:
	# Stub: rebind UI (UI-004) writes to SETTINGS_PATH.
	# For now, default actions from project.godot are authoritative.
	pass


func _save_remap() -> void:
	pass


# Convenience: returns true if any of the listed actions is currently pressed.
func is_any_pressed(actions: Array) -> bool:
	for a in actions:
		if Input.is_action_pressed(a):
			return true
	return false

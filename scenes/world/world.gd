extends Node3D

# W-001: World root.
# Hosts terrain (W-002 placeholder here, real impl in next ticket),
# directional light (sun), and WorldEnvironment.

@onready var sun: DirectionalLight3D = $Sun
@onready var environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	GameManager.log("info", "World ready")
	# Hook day/night cycle (W-006) by listening to GameManager.time_updated
	GameManager.time_updated.connect(_on_time_updated)


func _on_time_updated(hours: float, _day: int) -> void:
	# W-006 will rotate sun and modulate energy. For W-001 we just track.
	# Map game_time (0-24) to sun rotation; noon = horizontal noon angle.
	if sun:
		var angle: float = (hours / 24.0) * 360.0 - 90.0
		sun.rotation_degrees = Vector3(angle, -45.0, 0.0)

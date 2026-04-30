extends Node

# F-002 / W-001: Root scene controller.
# Loads the world, attaches debug overlay, transitions GameManager into PLAYING.

@onready var world_container: Node = $WorldContainer
@onready var ui_container: CanvasLayer = $UIContainer


func _ready() -> void:
	GameManager.log("info", "Sovereign main scene loaded")
	_load_world()
	_load_debug_overlay()
	GameManager.change_state(GameManager.GameState.PLAYING)


func _load_world() -> void:
	var world_scene: PackedScene = load("res://scenes/world/world.tscn")
	if world_scene == null:
		GameManager.log("error", "Failed to load world.tscn")
		return
	var world_instance: Node = world_scene.instantiate()
	world_container.add_child(world_instance)
	GameManager.log("info", "World instantiated")


func _load_debug_overlay() -> void:
	var overlay_scene: PackedScene = load("res://scenes/ui/hud/debug_overlay.tscn")
	if overlay_scene == null:
		GameManager.log("warn", "debug_overlay.tscn not found")
		return
	add_child(overlay_scene.instantiate())

extends Node

# F-002 / W-001: Root scene controller.

@onready var world_container: Node = $WorldContainer
@onready var ui_container: CanvasLayer = $UIContainer

var blueprint_placer: Node3D = null
var build_menu: Control = null
var crafting_screen: Control = null


func _ready() -> void:
	GameManager.log("info", "Sovereign main scene loaded")
	_load_world()
	_load_debug_overlay()
	_load_build_menu()
	_load_crafting_screen()
	_load_blueprint_placer()
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
		return
	add_child(overlay_scene.instantiate())


func _load_build_menu() -> void:
	var scene: PackedScene = load("res://scenes/ui/menus/build_menu.tscn")
	if scene == null:
		return
	build_menu = scene.instantiate()
	ui_container.add_child(build_menu)
	build_menu.structure_selected.connect(_on_build_structure_selected)


func _load_crafting_screen() -> void:
	var scene: PackedScene = load("res://scenes/ui/menus/crafting_screen.tscn")
	if scene == null:
		return
	crafting_screen = scene.instantiate()
	crafting_screen.name = "CraftingScreen"
	ui_container.add_child(crafting_screen)


func _load_blueprint_placer() -> void:
	# Spawn an instance of BlueprintPlacer in the world (so it can read mouse + raycast).
	blueprint_placer = Node3D.new()
	blueprint_placer.name = "BlueprintPlacer"
	blueprint_placer.set_script(load("res://scripts/systems/building/blueprint_placer.gd"))
	world_container.add_child(blueprint_placer)


func _on_build_structure_selected(structure_id: String) -> void:
	if blueprint_placer and blueprint_placer.has_method("start_placement"):
		blueprint_placer.start_placement(structure_id)

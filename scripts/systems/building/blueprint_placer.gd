class_name BlueprintPlacer
extends Node3D

# B-006: Ghost placer. Player picks a structure type from build menu;
# this node follows the mouse with a translucent ghost; LMB places, RMB cancels.

const STRUCTURE_SCENE_PATH: String = "res://scenes/entities/structure.tscn"
const ROTATION_STEP: float = 15.0

var active_type: String = ""
var ghost_mesh: MeshInstance3D = null
var can_place: bool = false
var placement_position: Vector3 = Vector3.ZERO
var placement_rotation: float = 0.0

signal blueprint_placed(structure_type: String, position: Vector3, rotation: float)
signal blueprint_cancelled()


func start_placement(structure_type: String) -> void:
	cancel_placement()
	active_type = structure_type
	var def: Dictionary = StructureDefs.get_structure(structure_type)
	if def.is_empty():
		active_type = ""
		return
	ghost_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = def["size"]
	ghost_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 0.4, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_mesh.material_override = mat
	add_child(ghost_mesh)


func _process(_delta: float) -> void:
	if active_type.is_empty() or ghost_mesh == null:
		return
	var p: Node = GameManager.player
	if p == null:
		return
	var camera = p.camera
	if camera == null:
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	placement_position = camera.screen_to_ground(mouse_pos)
	var def: Dictionary = StructureDefs.get_structure(active_type)
	# Lift so bottom rests on y=0
	ghost_mesh.global_position = placement_position + Vector3(0, def["size"].y * 0.5, 0)
	ghost_mesh.rotation_degrees.y = placement_rotation
	can_place = _validate_placement(placement_position)
	var mat: StandardMaterial3D = ghost_mesh.material_override
	if can_place:
		mat.albedo_color = Color(0.3, 0.85, 0.4, 0.45)
	else:
		mat.albedo_color = Color(0.85, 0.25, 0.25, 0.45)


func _unhandled_input(event: InputEvent) -> void:
	if active_type.is_empty():
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_place:
			_place()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_placement()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and Input.is_key_pressed(KEY_SHIFT):
			placement_rotation += ROTATION_STEP
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and Input.is_key_pressed(KEY_SHIFT):
			placement_rotation -= ROTATION_STEP
			get_viewport().set_input_as_handled()


func _place() -> void:
	var struct_scene: PackedScene = load(STRUCTURE_SCENE_PATH)
	if struct_scene == null:
		GameManager.log("error", "structure.tscn not found")
		return
	var inst = struct_scene.instantiate()
	inst.structure_type = active_type
	inst.is_blueprint = true
	get_tree().current_scene.add_child(inst)
	inst.global_position = placement_position
	inst.rotation_degrees.y = placement_rotation
	NetworkManager.send_build_place(active_type, placement_position, placement_rotation)
	blueprint_placed.emit(active_type, placement_position, placement_rotation)
	GameManager.log("info", "Placed blueprint: %s at %s" % [active_type, str(placement_position)])
	cancel_placement()


func cancel_placement() -> void:
	if ghost_mesh:
		ghost_mesh.queue_free()
		ghost_mesh = null
	active_type = ""
	blueprint_cancelled.emit()


func _validate_placement(_pos: Vector3) -> bool:
	# Phase 1 stub — always allow. B-009 adds support raycast + claim check.
	return true


func is_active() -> bool:
	return not active_type.is_empty()

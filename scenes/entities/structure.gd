extends StaticBody3D

# Generic structure entity. Configures itself from StructureDefs based on `structure_type`.
# Two states: blueprint (translucent, accepts contributions) → solid (opaque, functional).

@export var structure_type: String = "wall_wood"
@export var is_blueprint: bool = true
@export var build_progress: float = 0.0     # 0..1
@export var owner_id: String = ""

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var def: Dictionary = {}
var contributed: Dictionary = {}  # item_type -> qty contributed

signal blueprint_completed(structure: Node)


func _ready() -> void:
	add_to_group("structure")
	def = StructureDefs.get_structure(structure_type)
	_apply_visual()


func _apply_visual() -> void:
	if def.is_empty():
		return
	var size: Vector3 = def["size"]
	# Mesh
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	# Collision
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	# Lift mesh and collision so the bottom rests on y=0
	var t := Transform3D.IDENTITY
	t.origin.y = size.y * 0.5
	mesh.transform = t
	collision.transform = t
	# Material
	var mat := StandardMaterial3D.new()
	if is_blueprint:
		mat.albedo_color = Color(0.3, 0.85, 0.4, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.albedo_color = def.get("color", Color(0.6, 0.4, 0.2, 1))
	mesh.material_override = mat


func station_type() -> String:
	if is_blueprint:
		return ""
	return def.get("station_type", "")


# Player contributes items toward construction.
# Returns dict of items consumed.
func contribute(inventory: Inventory) -> Dictionary:
	if not is_blueprint:
		return {}
	var consumed: Dictionary = {}
	for mat in def["materials"]:
		var item_type: String = mat["item_type"]
		var needed: int = mat["quantity"] - contributed.get(item_type, 0)
		if needed <= 0:
			continue
		var have: int = inventory.count_item(item_type)
		var take: int = min(have, needed)
		if take <= 0:
			continue
		# Remove from inventory
		var stacks: Array = inventory.get_items_of_type(item_type)
		var remaining: int = take
		for s in stacks:
			if remaining <= 0:
				break
			var rm: int = min(s["quantity"], remaining)
			inventory.remove_item(s["id"], rm)
			remaining -= rm
		contributed[item_type] = contributed.get(item_type, 0) + take
		consumed[item_type] = take
	# Update progress
	var total_needed: int = 0
	var total_contributed: int = 0
	for mat in def["materials"]:
		total_needed += mat["quantity"]
		total_contributed += contributed.get(mat["item_type"], 0)
	build_progress = float(total_contributed) / max(1, total_needed)
	if build_progress >= 1.0:
		_complete_build()
	return consumed


func _complete_build() -> void:
	is_blueprint = false
	build_progress = 1.0
	_apply_visual()
	blueprint_completed.emit(self)
	GameManager.log("info", "%s built at %s" % [def.get("display_name", structure_type), str(global_position)])


func interact(player: Node) -> void:
	# If blueprint: contribute. If station: open crafting UI (handled in player).
	if is_blueprint:
		if player.has_node("Inventory"):
			var inv: Inventory = player.get_node("Inventory")
			var consumed: Dictionary = contribute(inv)
			if consumed.is_empty():
				GameManager.log("warn", "No contributable materials in inventory")
			else:
				GameManager.log("info", "Contributed: %s  (%.0f%%)" % [str(consumed), build_progress * 100])

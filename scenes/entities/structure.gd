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

# Farming state (only meaningful when variant == "farm_plot")
var planted_crop: String = ""
var growth_progress: float = 0.0
var water_level: float = 0.0
var soil_fertility: float = 1.0

signal blueprint_completed(structure: Node)


func _ready() -> void:
	add_to_group("structure")
	def = StructureDefs.get_structure(structure_type)
	_apply_visual()
	if def.get("variant", "") == "farm_plot" and not is_blueprint:
		set_process(true)


func _process(delta: float) -> void:
	if def.get("variant", "") != "farm_plot" or is_blueprint or planted_crop.is_empty():
		return
	if growth_progress >= 1.0:
		return
	var crop: Dictionary = CropDefs.get_crop(planted_crop)
	if crop.is_empty():
		return
	# Water depletes; growth needs water > 0
	water_level = max(0.0, water_level - 0.05 * delta / 60.0)
	var rate: float = 1.0 / crop["growth_seconds"]
	# Half-speed without water
	if water_level <= 0.0:
		rate *= 0.5
	rate *= soil_fertility
	growth_progress = min(1.0, growth_progress + rate * delta)
	# Update visual at growth stage boundaries
	_update_farm_visual()


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
		return
	# Farm plot interaction
	if def.get("variant", "") == "farm_plot":
		_farm_interact(player)
		return
	# Throne: declare kingdom
	if structure_type == "throne":
		var ks: Node = get_tree().current_scene.get_node_or_null("UIContainer/KingdomScreen")
		if ks and ks.has_method("open_with_throne"):
			ks.open_with_throne(self)
		return


func _farm_interact(player: Node) -> void:
	if not player.has_node("Inventory"):
		return
	var inv: Inventory = player.get_node("Inventory")
	# Empty plot — open seed picker UI
	if planted_crop.is_empty():
		var picker: Node = get_tree().current_scene.get_node_or_null("UIContainer/SeedPicker")
		if picker and picker.has_method("open_for_plot"):
			picker.open_for_plot(self)
		else:
			GameManager.log("warn", "Seed picker not loaded")
		return
	# Mature — harvest
	if growth_progress >= 1.0:
		var crop: Dictionary = CropDefs.get_crop(planted_crop)
		var bonus: int = 0
		if player.has_node("SkillSystem"):
			var sk: SkillSystem = player.get_node("SkillSystem")
			bonus = int(sk.get_level("farming") / 25)
			sk.add_xp("farming", 15)
		var qty: int = crop["yield_qty"] + bonus
		inv.add_item(crop["yield_item"], qty)
		GameManager.log("info", "Harvested %s ×%d" % [crop["yield_item"], qty])
		planted_crop = ""
		growth_progress = 0.0
		soil_fertility = max(0.5, soil_fertility - 0.1)
		_update_farm_visual()
		return
	# Growing — water if has bucket
	water_level = 1.0
	GameManager.log("info", "Watered (%.0f%% grown)" % [growth_progress * 100])


# Public planting API used by the SeedPicker UI.
func plant_seed(seed_type: String, player: Node) -> bool:
	if not planted_crop.is_empty():
		return false
	var inv: Inventory = player.get_node("Inventory")
	if inv == null or not inv.has_item(seed_type, 1):
		GameManager.log("warn", "No %s in inventory" % seed_type)
		return false
	var crop_id: String = CropDefs.crop_for_seed(seed_type)
	if crop_id.is_empty():
		return false
	# Find a stack and consume one
	for item in inv.items:
		if item["item_type"] == seed_type:
			inv.remove_item(item["id"], 1)
			break
	planted_crop = crop_id
	growth_progress = 0.0
	_update_farm_visual()
	GameManager.log("info", "Planted %s" % CropDefs.get_crop(crop_id).get("display_name", crop_id))
	return true


func _update_farm_visual() -> void:
	if mesh == null or def.get("variant", "") != "farm_plot":
		return
	var mat := StandardMaterial3D.new()
	if planted_crop.is_empty():
		mat.albedo_color = Color(0.35, 0.2, 0.1)  # tilled dirt
	elif growth_progress < 0.33:
		mat.albedo_color = Color(0.4, 0.3, 0.15)  # planted
	elif growth_progress < 0.66:
		mat.albedo_color = Color(0.4, 0.55, 0.25)  # sprouting green
	elif growth_progress < 1.0:
		mat.albedo_color = Color(0.55, 0.65, 0.2)  # growing
	else:
		mat.albedo_color = Color(0.85, 0.75, 0.2)  # ripe gold
	mesh.material_override = mat

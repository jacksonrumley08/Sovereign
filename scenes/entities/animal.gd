extends CharacterBody3D

# AN-001/002/003/005: Wandering animal that can be tamed, penned, fed, harvested.

@export var animal_type: String = "chicken"
@export var is_tamed: bool = false
@export var owner_id: String = ""
@export var pen_position: Vector3 = Vector3.ZERO
@export var pen_radius: float = 4.0

@onready var mesh: MeshInstance3D = $MeshInstance3D

var def: Dictionary = {}
var health: int = 20
var hunger: float = 100.0
var product_timer: float = 0.0
var has_product: bool = false
var wander_target: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0


func _ready() -> void:
	add_to_group("animal")
	def = AnimalDefs.get_animal(animal_type)
	if def.is_empty():
		GameManager.log("error", "Unknown animal_type: %s" % animal_type)
		return
	health = def["max_health"]
	_apply_visual()
	wander_target = global_position


func _apply_visual() -> void:
	if mesh == null:
		return
	var color: Color = def.get("color", Color.WHITE)
	# Mesh size by type
	var size: Vector3 = Vector3(0.4, 0.5, 0.6) if animal_type == "chicken" else Vector3(1.0, 1.2, 1.6)
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var t := Transform3D.IDENTITY
	t.origin.y = size.y * 0.5
	mesh.transform = t
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	# Collision shape too
	var col: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if col:
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		col.transform = t


func _physics_process(delta: float) -> void:
	hunger = max(0.0, hunger - def["feed_per_min"] * delta / 60.0)
	if hunger <= 0.0:
		health -= 1
		if health <= 0:
			_die()
			return
	# Product generation
	if hunger > 30.0 and not has_product:
		product_timer += delta
		if product_timer >= def["product_seconds"]:
			has_product = true
			product_timer = 0.0
	# Movement
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_new_wander_target()
	var to_target: Vector3 = wander_target - global_position
	to_target.y = 0
	if to_target.length() > 0.3:
		velocity = to_target.normalized() * 1.5
		move_and_slide()
	else:
		velocity = Vector3.ZERO


func _pick_new_wander_target() -> void:
	wander_timer = randf_range(2.0, 5.0)
	var center: Vector3 = pen_position if is_tamed else global_position
	var radius: float = pen_radius if is_tamed else 5.0
	var angle: float = randf() * TAU
	wander_target = center + Vector3(cos(angle), 0, sin(angle)) * randf_range(0.5, radius)


# Capture attempt with rope. Skill = animal_husbandry.
func attempt_capture(player: Node) -> bool:
	if is_tamed:
		return false
	var skill_lv: int = 0
	if player.has_node("SkillSystem"):
		skill_lv = player.get_node("SkillSystem").get_level("animal_husbandry")
	var success_chance: float = 1.0 - def["capture_difficulty"] + (skill_lv * 0.005)
	if randf() < success_chance:
		is_tamed = true
		owner_id = "player"  # placeholder
		var pen: Node = _find_nearest_pen(player)
		if pen:
			pen_position = pen.global_position
			pen_radius = 3.0
			global_position = pen.global_position
		if player.has_node("SkillSystem"):
			player.get_node("SkillSystem").add_xp("animal_husbandry", 25)
		GameManager.log("info", "Tamed %s" % animal_type)
		return true
	GameManager.log("warn", "Capture failed (animal flees)")
	# Run away
	var flee_dir: Vector3 = (global_position - player.global_position).normalized()
	wander_target = global_position + flee_dir * 8.0
	return false


func _find_nearest_pen(_player: Node) -> Node:
	for s in get_tree().get_nodes_in_group("structure"):
		if s == null or s.is_blueprint:
			continue
		if s.def.get("variant", "") == "animal_pen":
			return s
	return null


# Interact with tamed animal: collect product, feed, slaughter.
func interact(player: Node) -> void:
	if not is_tamed:
		# Try to capture if player has rope
		if player.has_node("Inventory") and player.get_node("Inventory").has_item("rope", 1):
			player.get_node("Inventory").remove_item(_find_rope_id(player), 1)
			attempt_capture(player)
		else:
			GameManager.log("warn", "Need rope to capture")
		return
	# Feed if hungry
	if hunger < 50.0 and player.has_node("Inventory") and player.get_node("Inventory").has_item("animal_feed", 1):
		var feed_id: String = ""
		for item in player.get_node("Inventory").items:
			if item["item_type"] == "animal_feed":
				feed_id = item["id"]
				break
		if not feed_id.is_empty():
			player.get_node("Inventory").remove_item(feed_id, 1)
			hunger = min(100.0, hunger + 30.0)
			GameManager.log("info", "Fed %s" % animal_type)
			return
	# Collect product
	if has_product and player.has_node("Inventory"):
		player.get_node("Inventory").add_item(def["product_item"], 1)
		has_product = false
		if player.has_node("SkillSystem"):
			player.get_node("SkillSystem").add_xp("animal_husbandry", 5)
		GameManager.log("info", "Collected %s" % def["product_item"])
		return
	GameManager.log("info", "%s status: hunger %.0f, product %s" % [animal_type, hunger, "ready" if has_product else "growing"])


func _find_rope_id(player: Node) -> String:
	for item in player.get_node("Inventory").items:
		if item["item_type"] == "rope":
			return item["id"]
	return ""


func _die() -> void:
	GameManager.log("info", "%s died" % animal_type)
	# Drop slaughter yields
	for y in def.get("slaughter_yields", []):
		var p: Node = GameManager.player
		if p and p.has_node("Inventory"):
			p.get_node("Inventory").add_item(y["item_type"], y["quantity"])
	queue_free()

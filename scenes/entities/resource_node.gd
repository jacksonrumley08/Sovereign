extends StaticBody3D

# R-001: Gatherable resource node base. Yields items, depletes, respawns.

@export var resource_type: String = "tree"  # display tag
@export var max_health: int = 100
@export var yield_item: String = "wood_log"
@export var yield_quantity: int = 3
@export var required_tool: String = ""        # "" = hand-gatherable
@export var required_skill: String = ""       # SkillDefs key
@export var required_skill_level: int = 0
@export var xp_skill: String = ""             # which skill awards XP
@export var xp_amount: int = 5
@export var gather_time: float = 3.0          # per gather hit
@export var hit_damage: int = 25              # damage per gather hit
@export var respawn_time: float = 60.0

var current_health: int = 0
var is_depleted: bool = false
var respawn_timer: float = 0.0

signal gather_completed(node: Node, item_type: String, quantity: int, xp_skill: String, xp_amount: int)


func _ready() -> void:
	current_health = max_health
	add_to_group("resource_node")
	_apply_visual_for_type()


func _apply_visual_for_type() -> void:
	# Color the mesh by resource type so the dev can spot them visually.
	var mesh_inst: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh_inst == null:
		return
	var mat := StandardMaterial3D.new()
	match resource_type:
		"tree":
			mat.albedo_color = Color(0.2, 0.5, 0.15)  # green
		"stone":
			mat.albedo_color = Color(0.55, 0.55, 0.55)  # gray
		"berry_bush":
			mat.albedo_color = Color(0.7, 0.15, 0.4)  # pink
		"flint_rock":
			mat.albedo_color = Color(0.35, 0.35, 0.4)  # dark gray
		"copper_ore":
			mat.albedo_color = Color(0.7, 0.4, 0.2)
		"iron_ore":
			mat.albedo_color = Color(0.5, 0.5, 0.55)
		_:
			mat.albedo_color = Color(0.4, 0.25, 0.1)
	mesh_inst.material_override = mat


func _process(delta: float) -> void:
	if is_depleted:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()


func can_gather(tool_type: String, skill_level: int) -> Dictionary:
	if is_depleted:
		return {"ok": false, "reason": "Depleted"}
	if required_tool != "" and tool_type != required_tool:
		return {"ok": false, "reason": "Need %s" % required_tool}
	if required_skill != "" and skill_level < required_skill_level:
		return {"ok": false, "reason": "Need %s %d" % [required_skill, required_skill_level]}
	return {"ok": true, "reason": ""}


# Called by gathering interaction; returns whether yield was produced.
func gather_hit() -> Dictionary:
	current_health -= hit_damage
	if current_health <= 0:
		is_depleted = true
		respawn_timer = respawn_time
		visible = false
		# Disable collision while depleted
		var col: Node = get_node_or_null("CollisionShape3D")
		if col:
			col.set_deferred("disabled", true)
		gather_completed.emit(self, yield_item, yield_quantity, xp_skill, xp_amount)
		return {"yielded": true, "item_type": yield_item, "quantity": yield_quantity}
	return {"yielded": false}


func _respawn() -> void:
	is_depleted = false
	current_health = max_health
	visible = true
	var col: Node = get_node_or_null("CollisionShape3D")
	if col:
		col.set_deferred("disabled", false)

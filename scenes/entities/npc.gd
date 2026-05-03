extends CharacterBody3D

# CO-014: Simple dummy NPC enemy with patrol/aggro/chase/attack states.

@onready var combat_sm: CombatStateMachine = $CombatStateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var model: Node3D = $Model

@export var aggro_range: float = 10.0
@export var attack_range: float = 1.8
@export var move_speed: float = 3.5
@export var equipped_weapon: String = "flint_knife"
@export var equipped_armor: String = "none"
@export var peaceful: bool = false  # Won't aggro on proximity or on hit

# Stats consumed by CombatStateMachine
var stamina: float = 100.0
var max_stamina: float = 100.0

enum AIState { IDLE, PATROL, CHASE, ATTACK, DEAD }
var ai_state: AIState = AIState.PATROL

var target: Node3D = null
var patrol_center: Vector3 = Vector3.ZERO
var attack_cooldown: float = 0.0


func _ready() -> void:
	patrol_center = global_position
	if health_component:
		health_component.died.connect(_on_died)
		health_component.damaged.connect(_on_damaged)
	GameManager.log("info", "NPC ready at %s, weapon=%s, hp=%d" % [str(global_position), equipped_weapon, health_component.health])


func _physics_process(delta: float) -> void:
	if ai_state == AIState.DEAD:
		return
	stamina = min(max_stamina, stamina + Config.STAMINA_REGEN_RATE * delta)
	attack_cooldown = max(0.0, attack_cooldown - delta)
	_update_ai(delta)


func _update_ai(_delta: float) -> void:
	var player: Node = GameManager.player
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)

	match ai_state:
		AIState.IDLE, AIState.PATROL:
			if not peaceful and dist < aggro_range:
				target = player
				ai_state = AIState.CHASE
		AIState.CHASE:
			if dist > aggro_range * 1.5:
				target = null
				ai_state = AIState.PATROL
				return
			if dist <= attack_range:
				ai_state = AIState.ATTACK
				return
			_walk_toward(player.global_position)
		AIState.ATTACK:
			if dist > attack_range:
				ai_state = AIState.CHASE
				return
			_face(player.global_position)
			velocity = Vector3.ZERO
			move_and_slide()
			if attack_cooldown <= 0 and combat_sm.current_state == CombatStateMachine.State.IDLE:
				_try_attack_player()


func _walk_toward(pos: Vector3) -> void:
	var dir: Vector3 = (pos - global_position)
	dir.y = 0
	if dir.length() < 0.01:
		return
	dir = dir.normalized()
	velocity = dir * move_speed
	move_and_slide()
	_face(pos)


func _face(pos: Vector3) -> void:
	if model == null:
		return
	var to: Vector3 = pos - global_position
	to.y = 0
	if to.length() > 0.1:
		var target_yaw: float = atan2(to.x, to.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 0.3)


func _try_attack_player() -> void:
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	if combat_sm.try_attack(1, 0, weapon["speed"], weapon["stamina_cost"]):
		attack_cooldown = weapon["speed"] + 0.5
		# Apply damage at animation midpoint via small delay
		await get_tree().create_timer(weapon["speed"] * 0.5).timeout
		if not is_instance_valid(target) or ai_state == AIState.DEAD:
			return
		if global_position.distance_to(target.global_position) > attack_range * 1.2:
			return
		var calc: Dictionary = DamageCalculator.calculate_damage(
			weapon["damage"], 1, weapon["damage_type"], "torso",
			"none", 0, false, "none"
		)
		if target.has_method("take_damage"):
			target.take_damage(calc)


# Receive damage from player attack. Damage payload comes from DamageCalculator.
func take_damage(damage_result: Dictionary) -> void:
	if ai_state == AIState.DEAD:
		return
	var amount: int = damage_result.get("final_damage", 0)
	GameManager.log("info", "NPC hit for %d (%s)" % [amount, damage_result.get("hit_zone", "?")])
	health_component.take_damage(amount)
	_spawn_damage_vfx(amount, damage_result.get("hit_zone", "torso"), damage_result.get("blocked", false))


func _spawn_damage_vfx(amount: int, zone: String, blocked: bool) -> void:
	var hit_pos: Vector3 = global_position + Vector3(0, 1.5, 0)
	# Damage number
	var dn_scene: PackedScene = load("res://scenes/effects/damage_number.tscn")
	if dn_scene:
		var dn: Node3D = dn_scene.instantiate()
		get_tree().current_scene.add_child(dn)
		dn.global_position = hit_pos
		dn.setup(amount, zone, blocked)
	# Hit burst
	var fx_scene: PackedScene = load("res://scenes/effects/hit_effect.tscn")
	if fx_scene:
		var fx: Node3D = fx_scene.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = hit_pos


func _on_damaged(_amount: int) -> void:
	if peaceful:
		return
	# Aggro on hit if not already engaged
	if ai_state in [AIState.IDLE, AIState.PATROL]:
		target = GameManager.player
		ai_state = AIState.CHASE


func _on_died() -> void:
	GameManager.log("info", "NPC died")
	ai_state = AIState.DEAD
	# Tint model dark to indicate death
	if model:
		var mesh_inst: MeshInstance3D = model.get_node_or_null("MeshInstance3D")
		if mesh_inst and mesh_inst.material_override is StandardMaterial3D:
			(mesh_inst.material_override as StandardMaterial3D).albedo_color = Color(0.15, 0.15, 0.15, 1)
	# Disable further physics
	set_physics_process(false)
	# Remove collision after a short delay so the corpse lingers
	await get_tree().create_timer(2.0).timeout
	queue_free()

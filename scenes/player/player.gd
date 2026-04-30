class_name PlayerController
extends CharacterBody3D

# C-001 + W-004: Click-to-move player controller.
# CO-002 + CO-007: Click on enemy = attack; sphere overlap on swing applies damage.

@onready var camera = $PlayerCamera
@onready var model: Node3D = $PlayerModel
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var combat_sm: CombatStateMachine = $CombatStateMachine
@onready var health_component: HealthComponent = $HealthComponent

var move_target: Vector3 = Vector3.ZERO
var is_moving: bool = false
var is_sprinting: bool = false
var current_speed: float = Config.WALK_SPEED

# Combat target (enemy clicked on)
var attack_target: Node = null
var equipped_weapon: String = "bronze_sword"  # Starts armed for combat testing
var equipped_armor: String = "none"

# Stats
var health: int = 100
var max_health: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0
var hunger: float = 100.0
var carry_weight: float = 0.0
var max_carry_weight: float = 100.0
var total_playtime: float = 0.0


func _ready() -> void:
	GameManager.player = self
	camera.target = self
	nav_agent.path_desired_distance = Config.PATH_ARRIVE_THRESHOLD
	nav_agent.target_desired_distance = Config.PATH_ARRIVE_THRESHOLD
	if health_component:
		health_component.died.connect(_on_died)
		# Sync stat shorthand
		health_component.damaged.connect(func(_a): health = health_component.health)
		health_component.healed.connect(func(_a): health = health_component.health)
		health = health_component.health
		max_health = health_component.max_health
	GameManager.log("info", "Player ready at %s, weapon=%s" % [str(global_position), equipped_weapon])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		# Quick weapon hotswap for testing combat feel
		match event.keycode:
			KEY_1: _set_weapon("flint_knife")
			KEY_2: _set_weapon("bronze_sword")
			KEY_3: _set_weapon("iron_sword")
			KEY_4: _set_weapon("bronze_spear")
			KEY_5: _set_weapon("iron_spear")
			KEY_6: _set_weapon("bronze_mace")
			KEY_7: _set_weapon("iron_mace")


func _set_weapon(weapon_id: String) -> void:
	equipped_weapon = weapon_id
	var w: Dictionary = WeaponDefs.get_weapon(weapon_id)
	GameManager.log("info", "Weapon → %s (dmg=%d, range=%.1fm, speed=%.2fs)" % [w["display_name"], w["damage"], w["range"], w["speed"]])


func _physics_process(delta: float) -> void:
	total_playtime += delta
	_update_sprint(delta)
	_update_stamina(delta)
	_update_hunger(delta)
	_process_attack_target()
	_process_movement(delta)


func _handle_left_click(screen_pos: Vector2) -> void:
	# Raycast from screen position to find what's under the cursor.
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [self.get_rid()])
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit and hit.collider and hit.collider.has_method("take_damage") and hit.collider != self:
		# Clicked on an enemy → set as attack target
		attack_target = hit.collider
		_set_move_target(hit.collider.global_position)
		GameManager.log("info", "Targeted enemy at %s" % str(hit.collider.global_position))
	else:
		# Clicked on ground → just move
		attack_target = null
		var ground_pos: Vector3 = camera.screen_to_ground(screen_pos)
		_set_move_target(ground_pos)


func _set_move_target(target_pos: Vector3) -> void:
	move_target = target_pos
	if nav_agent:
		nav_agent.target_position = target_pos
	is_moving = true
	NetworkManager.send_move(target_pos)


func _process_attack_target() -> void:
	if attack_target == null:
		return
	if not is_instance_valid(attack_target):
		attack_target = null
		return
	# Stop attacking dead targets even if their corpse is still in the scene
	if attack_target.has_node("HealthComponent"):
		var hp: HealthComponent = attack_target.get_node("HealthComponent")
		if not hp.is_alive():
			attack_target = null
			is_moving = false
			return
	# Update move target to follow if enemy moves
	move_target = attack_target.global_position
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	var dist: float = global_position.distance_to(attack_target.global_position)
	if dist <= weapon["range"]:
		# In range — stop and swing
		is_moving = false
		_face(attack_target.global_position)
		if combat_sm.current_state == CombatStateMachine.State.IDLE:
			_swing_at_target()


func _swing_at_target() -> void:
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	if not combat_sm.try_attack(1, 0, weapon["speed"], weapon["stamina_cost"]):
		return
	NetworkManager.send_attack(attack_target.get_instance_id(), 1, 0)
	# Apply damage at animation midpoint
	await get_tree().create_timer(weapon["speed"] * 0.5).timeout
	if not is_instance_valid(attack_target):
		return
	if global_position.distance_to(attack_target.global_position) > weapon["range"] * 1.2:
		return
	var calc: Dictionary = DamageCalculator.calculate_damage(
		weapon["damage"], 1, weapon["damage_type"], "torso",
		"none", 0, false, "none"
	)
	if attack_target.has_method("take_damage"):
		attack_target.take_damage(calc)


func _face(pos: Vector3) -> void:
	if model == null:
		return
	var to: Vector3 = pos - global_position
	to.y = 0
	if to.length() > 0.1:
		var look_target: Vector3 = global_position + to.normalized()
		look_target.y = global_position.y
		model.look_at(look_target, Vector3.UP)


func _update_sprint(_delta: float) -> void:
	is_sprinting = Input.is_action_pressed("sprint") and is_moving and stamina > 0.0


func _process_movement(_delta: float) -> void:
	if not is_moving:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var to_target: Vector3 = move_target - global_position
	to_target.y = 0
	if to_target.length() < Config.PATH_ARRIVE_THRESHOLD:
		is_moving = false
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var direction: Vector3 = to_target.normalized()

	current_speed = Config.WALK_SPEED
	if is_sprinting:
		current_speed = Config.SPRINT_SPEED
	# Block movement while attacking (per spec §4.2 stationary heavy / walk for normal)
	if combat_sm and combat_sm.current_state == CombatStateMachine.State.ATTACKING:
		current_speed *= 0.7
	current_speed *= _get_encumbrance_modifier()

	velocity = direction * current_speed
	move_and_slide()

	# Rotate model
	if model and direction.length() > 0.1:
		var look_target: Vector3 = global_position + direction
		look_target.y = global_position.y
		model.look_at(look_target, Vector3.UP)


func _get_encumbrance_modifier() -> float:
	if carry_weight <= max_carry_weight:
		return 1.0
	var overweight_ratio: float = carry_weight / max_carry_weight
	if overweight_ratio >= 1.5:
		return 0.0
	return 1.0 - ((overweight_ratio - 1.0) / 0.5)


func _update_stamina(delta: float) -> void:
	if is_sprinting:
		stamina -= Config.SPRINT_STAMINA_COST * delta
		stamina = max(0.0, stamina)
	else:
		stamina = min(max_stamina, stamina + Config.STAMINA_REGEN_RATE * delta)


func _update_hunger(delta: float) -> void:
	hunger -= Config.HUNGER_RATE_BASE * delta
	hunger = max(0.0, hunger)
	if hunger <= 0.0:
		health -= int(delta / 10.0)


# Receive damage (e.g. from NPCs). Same shape as NPC.take_damage.
func take_damage(damage_result: Dictionary) -> void:
	var amount: int = damage_result.get("final_damage", 0)
	if health_component:
		health_component.take_damage(amount)
	GameManager.log("info", "Player hit for %d (HP=%d)" % [amount, health_component.health if health_component else -1])
	_spawn_damage_vfx(amount, damage_result.get("hit_zone", "torso"), damage_result.get("blocked", false))


func _spawn_damage_vfx(amount: int, zone: String, blocked: bool) -> void:
	var hit_pos: Vector3 = global_position + Vector3(0, 1.5, 0)
	var dn_scene: PackedScene = load("res://scenes/effects/damage_number.tscn")
	if dn_scene:
		var dn: Node3D = dn_scene.instantiate()
		get_tree().current_scene.add_child(dn)
		dn.global_position = hit_pos
		dn.setup(amount, zone, blocked)
	var fx_scene: PackedScene = load("res://scenes/effects/hit_effect.tscn")
	if fx_scene:
		var fx: Node3D = fx_scene.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = hit_pos


func _on_died() -> void:
	GameManager.log("warn", "Player died")
	# Respawn full HP at origin for now (proper respawn flow lands in C-010)
	if health_component:
		health_component.health = health_component.max_health
		health = health_component.health
	global_position = Vector3(0, 1, 0)

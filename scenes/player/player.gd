class_name PlayerController
extends CharacterBody3D

# Player controller — WASD movement, mouse-aim facing, LMB attack, RMB block, E interact.

@onready var camera = $PlayerCamera
@onready var model: Node3D = $PlayerModel
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D  # kept for future AI use
@onready var combat_sm: CombatStateMachine = $CombatStateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentManager = $EquipmentManager
@onready var skills: SkillSystem = $SkillSystem
@onready var crafting: CraftingSystem = $CraftingSystem

# --- Crafting / station ---
var nearest_station_type: String = ""
var nearest_station_id: int = 0
var crafting_station_id: int = 0
var selected_seed: String = "seed_wheat"

# --- Movement (WASD) ---
# Isometric camera is rotated 45° around Y. WASD is mapped to screen-space directions:
#   W = up-on-screen  → world (-sin45, 0, -cos45) ≈ (-0.707, 0, -0.707)
const ISO_FORWARD: Vector3 = Vector3(-0.7071, 0, -0.7071)
const ISO_RIGHT: Vector3   = Vector3( 0.7071, 0, -0.7071)
var move_input: Vector3 = Vector3.ZERO
var is_moving: bool = false
var is_sprinting: bool = false
var current_speed: float = Config.WALK_SPEED

# --- Mouse aim ---
var mouse_world_pos: Vector3 = Vector3.ZERO
var facing_yaw: float = 0.0  # radians, model rotation around Y

# --- Combat ---
var attack_target: Node = null  # set when LMB swing finds something in arc
var equipped_weapon: String = "bronze_sword"
var equipped_armor: String = "none"
const TIER_JAB_THRESHOLD: float = 0.15
const TIER_HEAVY_THRESHOLD: float = 0.40
var lmb_press_time: float = -1.0
var pending_tier: int = 1
var is_charging_heavy: bool = false

# Block (RMB)
var is_blocking: bool = false
var block_dir_sector: int = 0

# Dodge
var last_dodge_time: float = -10.0
var _dodge_active: bool = false
var _dodge_direction: Vector3 = Vector3.ZERO

# --- Gathering ---
var gather_target: Node = null
var gather_progress: float = 0.0
var gather_total: float = 0.0
var is_gathering: bool = false

# --- Stats ---
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
	if health_component:
		health_component.died.connect(_on_died)
		health_component.damaged.connect(func(_a): health = health_component.health)
		health_component.healed.connect(func(_a): health = health_component.health)
		health = health_component.health
		max_health = health_component.max_health
	if inventory:
		inventory.weight_changed.connect(func(w): carry_weight = w)
		inventory.add_item("stone_axe", 1)
		inventory.add_item("stone_pickaxe", 1)
		inventory.add_item("flint_knife", 1)
		inventory.add_item("seed_wheat", 5)
		inventory.add_item("seed_carrot", 5)
		inventory.add_item("rope", 3)
		inventory.add_item("animal_feed", 10)
	if skills:
		skills.level_up.connect(func(s, lv): GameManager.log("info", "Level up: %s → %d" % [s, lv]))
	if crafting:
		crafting.craft_completed.connect(_on_craft_completed)
		crafting.craft_failed.connect(func(rid, reason): GameManager.log("warn", "Craft %s failed: %s" % [rid, reason]))
		crafting.craft_started.connect(func(rid, dur): GameManager.log("info", "Crafting %s (%.1fs)..." % [rid, dur]))
	GameManager.log("info", "Player ready (WASD move + mouse aim), weapon=%s" % equipped_weapon)


func _on_craft_completed(_recipe_id: String, output_item: String, qty: int, _quality: String) -> void:
	inventory.add_item(output_item, qty)
	var def: Dictionary = RecipeDefs.get_recipe(_recipe_id)
	if not def.is_empty() and skills:
		skills.add_xp(def["skill"], 10 + def["skill_req"] / 2)
	GameManager.log("info", "Crafted %s ×%d" % [output_item, qty])


# ----- INPUT -----

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_lmb_pressed()
			else:
				_on_lmb_released()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_on_rmb_pressed()
			else:
				_on_rmb_released()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:  _try_dodge()
			KEY_E:      _try_interact()
			KEY_F:      _try_open_crafting()
			KEY_R:      _cycle_seed()
			KEY_1:      _set_weapon("flint_knife")
			KEY_2:      _set_weapon("bronze_sword")
			KEY_3:      _set_weapon("iron_sword")
			KEY_4:      _set_weapon("bronze_spear")
			KEY_5:      _set_weapon("iron_spear")
			KEY_6:      _set_weapon("bronze_mace")
			KEY_7:      _set_weapon("iron_mace")
			KEY_8:      _equip_tool("stone_axe")
			KEY_9:      _equip_tool("stone_pickaxe")


func _set_weapon(weapon_id: String) -> void:
	equipped_weapon = weapon_id
	var w: Dictionary = WeaponDefs.get_weapon(weapon_id)
	GameManager.log("info", "Weapon → %s (dmg=%d, range=%.1fm)" % [w["display_name"], w["damage"], w["range"]])


func _equip_tool(tool_type: String) -> void:
	if not inventory.has_item(tool_type):
		GameManager.log("warn", "Don't have %s" % tool_type)
		return
	equipment.unequip("main_hand")
	for item in inventory.items:
		if item["item_type"] == tool_type:
			equipment.equip(item["id"], "main_hand", inventory)
			GameManager.log("info", "Equipped %s" % ItemDefs.get_item(tool_type).get("display_name", tool_type))
			return


func _cycle_seed() -> void:
	var seeds: Array[String] = []
	for item in inventory.items:
		var def: Dictionary = ItemDefs.get_item(item["item_type"])
		if def.get("category", "") == "seed":
			if not seeds.has(item["item_type"]):
				seeds.append(item["item_type"])
	if seeds.is_empty():
		return
	var idx: int = seeds.find(selected_seed)
	idx = (idx + 1) % seeds.size() if idx >= 0 else 0
	selected_seed = seeds[idx]


# ----- LMB / RMB / Dodge -----

func _on_lmb_pressed() -> void:
	# Don't intercept clicks while a blueprint placer is active
	var bp: Node = get_tree().current_scene.get_node_or_null("BlueprintPlacer")
	if bp == null:
		bp = get_node_or_null("/root/Main/BlueprintPlacer")
	if bp and bp.has_method("is_active") and bp.is_active():
		return
	lmb_press_time = Time.get_ticks_msec() / 1000.0
	is_charging_heavy = false


func _on_lmb_released() -> void:
	if lmb_press_time < 0:
		return
	var duration: float = (Time.get_ticks_msec() / 1000.0) - lmb_press_time
	lmb_press_time = -1.0
	is_charging_heavy = false
	if duration < TIER_JAB_THRESHOLD:
		pending_tier = 0
	elif duration > TIER_HEAVY_THRESHOLD:
		pending_tier = 2
	else:
		pending_tier = 1
	# Fire the swing now (in facing direction, sphere-overlap forward)
	_fire_swing(pending_tier)
	pending_tier = 1


func _on_rmb_pressed() -> void:
	if combat_sm.current_state != CombatStateMachine.State.IDLE:
		return
	block_dir_sector = _facing_to_sector()
	if combat_sm.try_block(block_dir_sector):
		is_blocking = true


func _on_rmb_released() -> void:
	combat_sm.stop_block()
	is_blocking = false


func _try_dodge() -> void:
	if combat_sm.current_state != CombatStateMachine.State.IDLE:
		return
	if stamina < Config.DODGE_STAMINA_COST:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - last_dodge_time < Config.DODGE_COOLDOWN:
		return
	var dir: Vector3 = move_input
	if dir.length() < 0.01:
		dir = _facing_vector()
	dir.y = 0
	if dir.length() < 0.01:
		dir = Vector3(0, 0, -1)
	last_dodge_time = now
	stamina -= Config.DODGE_STAMINA_COST
	combat_sm._transition_to(CombatStateMachine.State.DODGING)
	combat_sm.state_timer = Config.DODGE_DURATION
	_dodge_direction = dir.normalized()
	_dodge_active = true
	NetworkManager.send_dodge(Vector2(dir.x, dir.z))


func _try_open_crafting() -> void:
	var station: String = nearest_station_type if not nearest_station_type.is_empty() else "inventory"
	crafting_station_id = nearest_station_id
	var ui: Node = get_tree().current_scene.get_node_or_null("UIContainer/CraftingScreen")
	if ui and ui.has_method("open"):
		ui.open(station)


# ----- INTERACT (E key) -----

func _try_interact() -> void:
	# Raycast from mouse cursor into scene; whichever interactable is hit, try it.
	var space_state := get_world_3d().direct_space_state
	var screen_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [self.get_rid()])
	var hit: Dictionary = space_state.intersect_ray(query)
	if not hit:
		GameManager.log("info", "Nothing under cursor")
		return
	var c = hit.collider
	var dist: float = global_position.distance_to(c.global_position)
	if dist > 3.5:
		GameManager.log("warn", "Move closer (%.1fm)" % dist)
		return
	# Resource node — start gather
	if c.is_in_group("resource_node"):
		gather_target = c
		_start_gather()
		return
	# Structure — interact (contribute / open station / farm plot)
	if c.is_in_group("structure") and c.has_method("interact"):
		c.interact(self)
		return
	# Animal
	if c.is_in_group("animal") and c.has_method("interact"):
		c.interact(self)
		return
	GameManager.log("info", "Nothing interactable here")


# ----- COMBAT SWING -----

func _fire_swing(tier: int) -> void:
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	# Heavy attack: must be stationary (pause WASD this frame anyway via charging flag)
	if not combat_sm.try_attack(tier, _facing_to_sector(), weapon["speed"], weapon["stamina_cost"]):
		return
	NetworkManager.send_attack(0, tier, _facing_to_sector())
	# Resolve hit: sphere overlap in front of character in arc of facing
	var swing_time: float = weapon["speed"]
	if tier == 0:
		swing_time *= 0.6
	elif tier == 2:
		swing_time *= 1.4
	await get_tree().create_timer(swing_time * 0.5).timeout
	_apply_swing_hits(tier, weapon)


func _apply_swing_hits(tier: int, weapon: Dictionary) -> void:
	var direction_sector: int = _facing_to_sector()
	# Origin of the swing is 0.5m forward of player so range counts from arm's reach,
	# not from center-of-body. Compensates for player + target collision radii.
	var fwd: Vector3 = _facing_vector()
	var swing_origin: Vector3 = global_position + fwd * 0.5
	var range: float = weapon["range"]
	# Wider arc for forgiving glancing hits — 75° each side = 150° front cone
	const ARC_HALF_DEG: float = 75.0
	var hits: Array = []
	var seen: Dictionary = {}
	for body in get_tree().get_nodes_in_group("animal") + _get_npcs_and_wildlife():
		if body == self or body == null or not is_instance_valid(body):
			continue
		if seen.has(body.get_instance_id()):
			continue
		seen[body.get_instance_id()] = true
		var to: Vector3 = body.global_position - swing_origin
		to.y = 0
		var d: float = to.length()
		if d > range or d < 0.01:
			continue
		# Arc check still uses player position (so the cone visually originates at player)
		var to_from_player: Vector3 = body.global_position - global_position
		to_from_player.y = 0
		if to_from_player.length() < 0.01:
			continue
		var ang: float = rad_to_deg(fwd.angle_to(to_from_player.normalized()))
		if ang <= ARC_HALF_DEG:
			hits.append(body)
	# For each hit body, deal damage (only first one for melee — mash through one target at a time)
	if hits.is_empty():
		return
	hits.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	var target = hits[0]
	if not target.has_method("take_damage"):
		return
	var skill_lv: int = skills.get_level("melee_weapons") if skills else 0
	var attack_height: float = 0.5
	if tier == 2:
		attack_height = 0.85
	elif tier == 0:
		attack_height = 0.3
	var hit_zone: String = HitZoneSystem.determine_hit_zone(
		direction_sector, global_position, target.global_position, attack_height
	)
	var def_blocked: bool = false
	if target.has_node("CombatStateMachine"):
		var def_csm: CombatStateMachine = target.get_node("CombatStateMachine")
		var incoming: int = (direction_sector + 4) % 8
		if def_csm.is_blocking_direction(incoming):
			def_blocked = true
	var def_armor: String = "none"
	if "equipped_armor" in target:
		def_armor = target.equipped_armor
	var calc: Dictionary = DamageCalculator.calculate_damage(
		weapon["damage"], tier, weapon["damage_type"], hit_zone,
		def_armor, skill_lv, def_blocked, "none"
	)
	target.take_damage(calc)
	if skills:
		skills.add_xp("melee_weapons", 10 + tier * 5)


func _get_npcs_and_wildlife() -> Array:
	var out: Array = []
	for n in get_tree().current_scene.get_children():
		_collect_combatants(n, out)
	return out


func _collect_combatants(n: Node, out: Array) -> void:
	# Only physical bodies (NPCs, animals, wolves) — skip HealthComponent etc.
	if n is CharacterBody3D and n.has_method("take_damage") and n != self:
		out.append(n)
	for c in n.get_children():
		_collect_combatants(c, out)


# ----- DAMAGE INTAKE -----

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
	if health_component:
		health_component.health = health_component.max_health
		health = health_component.health
	global_position = Vector3(0, 1, 0)


# ----- PHYSICS / FRAME UPDATE -----

func _physics_process(delta: float) -> void:
	total_playtime += delta
	_update_lmb_charge()
	_update_mouse_world_pos()
	_update_facing()
	_update_move_input()
	_update_sprint()
	_update_stamina(delta)
	_update_hunger(delta)
	_update_nearest_station()
	_process_gathering(delta)
	_process_dodge(delta)
	_process_movement(delta)


func _update_lmb_charge() -> void:
	if lmb_press_time < 0:
		return
	var dur: float = (Time.get_ticks_msec() / 1000.0) - lmb_press_time
	if dur > TIER_HEAVY_THRESHOLD and not is_charging_heavy:
		is_charging_heavy = true


func _update_mouse_world_pos() -> void:
	if camera == null:
		return
	mouse_world_pos = camera.screen_to_ground(get_viewport().get_mouse_position())


func _update_facing() -> void:
	# Character always faces the mouse ground point.
	var to_mouse: Vector3 = mouse_world_pos - global_position
	to_mouse.y = 0
	if to_mouse.length() < 0.05:
		return
	facing_yaw = atan2(to_mouse.x, to_mouse.z)
	if model:
		model.rotation.y = lerp_angle(model.rotation.y, facing_yaw, 0.4)


func _update_move_input() -> void:
	var fwd_amt: float = 0.0
	var right_amt: float = 0.0
	if Input.is_key_pressed(KEY_W):
		fwd_amt += 1.0
	if Input.is_key_pressed(KEY_S):
		fwd_amt -= 1.0
	if Input.is_key_pressed(KEY_D):
		right_amt += 1.0
	if Input.is_key_pressed(KEY_A):
		right_amt -= 1.0
	move_input = (ISO_FORWARD * fwd_amt + ISO_RIGHT * right_amt)
	if move_input.length() > 1.0:
		move_input = move_input.normalized()
	is_moving = move_input.length() > 0.01


func _update_sprint() -> void:
	is_sprinting = Input.is_action_pressed("sprint") and is_moving and stamina > 0.0


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


func _update_nearest_station() -> void:
	nearest_station_type = ""
	nearest_station_id = 0
	var nearest_dist: float = 3.0
	for s in get_tree().get_nodes_in_group("structure"):
		if s == null or s.is_blueprint:
			continue
		var st: String = s.station_type()
		if st.is_empty():
			continue
		var d: float = global_position.distance_to(s.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest_station_type = st
			nearest_station_id = s.get_instance_id()


# ----- GATHERING -----

func _process_gathering(delta: float) -> void:
	if gather_target == null:
		return
	if not is_instance_valid(gather_target):
		_cancel_gather()
		return
	if gather_target.is_depleted:
		_cancel_gather()
		return
	# Must stay close to gather (no auto-walk now — player drives via WASD)
	var dist: float = global_position.distance_to(gather_target.global_position)
	if dist > 3.0:
		_cancel_gather()
		GameManager.log("info", "Gather cancelled (moved away)")
		return
	if not is_gathering:
		is_gathering = true
		gather_progress = 0.0
		gather_total = gather_target.gather_time
	gather_progress += delta
	if gather_progress >= gather_total:
		_finish_gather_hit()


func _start_gather() -> void:
	if gather_target.required_tool != "":
		var current: String = ""
		if equipment:
			var main: String = equipment.get_equipped_item_type("main_hand", inventory)
			if not main.is_empty():
				current = ItemDefs.get_item(main).get("tool_type", "")
		if current != gather_target.required_tool:
			_auto_equip_tool(gather_target.required_tool)
	var tool_type: String = ""
	if equipment:
		var main: String = equipment.get_equipped_item_type("main_hand", inventory)
		if not main.is_empty():
			tool_type = ItemDefs.get_item(main).get("tool_type", "")
	var skill_lv: int = 0
	if gather_target.required_skill != "" and skills:
		skill_lv = skills.get_level(gather_target.required_skill)
	var check: Dictionary = gather_target.can_gather(tool_type, skill_lv)
	if not check["ok"]:
		GameManager.log("warn", "Cannot gather: %s" % check["reason"])
		_cancel_gather()
		return
	is_gathering = true
	gather_progress = 0.0
	gather_total = gather_target.gather_time
	NetworkManager.send_gather(gather_target.get_instance_id())


func _auto_equip_tool(tool_type: String) -> void:
	for item in inventory.items:
		var def: Dictionary = ItemDefs.get_item(item["item_type"])
		if def.get("tool_type", "") == tool_type:
			equipment.unequip("main_hand")
			equipment.equip(item["id"], "main_hand", inventory)
			return


func _finish_gather_hit() -> void:
	gather_progress = 0.0
	if not is_instance_valid(gather_target):
		_cancel_gather()
		return
	var result: Dictionary = gather_target.gather_hit()
	if result.get("yielded", false):
		var item_type: String = result["item_type"]
		var qty: int = result["quantity"]
		inventory.add_item(item_type, qty)
		if gather_target.xp_skill != "" and skills:
			skills.add_xp(gather_target.xp_skill, gather_target.xp_amount)
		GameManager.log("info", "Gathered %s ×%d" % [item_type, qty])
		_cancel_gather()


func _cancel_gather() -> void:
	gather_target = null
	is_gathering = false
	gather_progress = 0.0


# ----- DODGE / MOVEMENT -----

func _process_dodge(_delta: float) -> void:
	if not _dodge_active:
		return
	if combat_sm.current_state != CombatStateMachine.State.DODGING:
		_dodge_active = false
		return
	velocity = _dodge_direction * Config.DODGE_SPEED
	move_and_slide()
	if combat_sm.state_timer <= 0:
		_dodge_active = false
		velocity = Vector3.ZERO


func _process_movement(_delta: float) -> void:
	if _dodge_active:
		return
	# Stop while charging heavy
	if is_charging_heavy:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if not is_moving:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	current_speed = Config.WALK_SPEED
	if is_sprinting:
		current_speed = Config.SPRINT_SPEED
	if combat_sm and combat_sm.current_state == CombatStateMachine.State.ATTACKING:
		current_speed *= 0.7
	if is_blocking:
		current_speed *= 0.5  # spec: blocking = 50% speed
	current_speed *= _get_encumbrance_modifier()
	velocity = move_input * current_speed
	move_and_slide()
	NetworkManager.send_move(global_position)


func _get_encumbrance_modifier() -> float:
	if carry_weight <= max_carry_weight:
		return 1.0
	var overweight_ratio: float = carry_weight / max_carry_weight
	if overweight_ratio >= 1.5:
		return 0.0
	return 1.0 - ((overweight_ratio - 1.0) / 0.5)


# ----- HELPERS -----

func _facing_vector() -> Vector3:
	return Vector3(sin(facing_yaw), 0, cos(facing_yaw))


func _facing_to_sector() -> int:
	var angle: float = facing_yaw
	if angle < 0:
		angle += TAU
	return int(round(angle / (TAU / 8.0))) % 8

class_name PlayerController
extends CharacterBody3D

# Player controller integrating combat + inventory + skills + gathering.

@onready var camera = $PlayerCamera
@onready var model: Node3D = $PlayerModel
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var combat_sm: CombatStateMachine = $CombatStateMachine
@onready var health_component: HealthComponent = $HealthComponent
@onready var inventory: Inventory = $Inventory
@onready var equipment: EquipmentManager = $EquipmentManager
@onready var skills: SkillSystem = $SkillSystem
@onready var crafting: CraftingSystem = $CraftingSystem

# Crafting station tracking — set by being near a workbench/forge/campfire structure.
var nearest_station_type: String = ""
var nearest_station_id: int = 0
var crafting_station_id: int = 0  # alias for the netmsg payload

# Currently-selected seed to plant. Cycle with R.
var selected_seed: String = "seed_wheat"

var move_target: Vector3 = Vector3.ZERO
var is_moving: bool = false
var is_sprinting: bool = false
var current_speed: float = Config.WALK_SPEED

# Combat target
var attack_target: Node = null
var equipped_weapon: String = "bronze_sword"
var equipped_armor: String = "none"

# Gathering
var gather_target: Node = null   # ResourceNode being gathered
var gather_progress: float = 0.0
var gather_total: float = 0.0
var is_gathering: bool = false

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
		health_component.damaged.connect(func(_a): health = health_component.health)
		health_component.healed.connect(func(_a): health = health_component.health)
		health = health_component.health
		max_health = health_component.max_health
	if inventory:
		inventory.weight_changed.connect(func(w): carry_weight = w)
		# Starter kit
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
	GameManager.log("info", "Player ready, weapon=%s, inventory=%s" % [equipped_weapon, inventory.summary()])


func _on_craft_completed(_recipe_id: String, output_item: String, qty: int, _quality: String) -> void:
	inventory.add_item(output_item, qty)
	# XP — small fixed amount; refine later
	var def: Dictionary = RecipeDefs.get_recipe(_recipe_id)
	if not def.is_empty() and skills:
		skills.add_xp(def["skill"], 10 + def["skill_req"] / 2)
	GameManager.log("info", "Crafted %s ×%d  [inv: %s]" % [output_item, qty, inventory.summary()])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _set_weapon("flint_knife")
			KEY_2: _set_weapon("bronze_sword")
			KEY_3: _set_weapon("iron_sword")
			KEY_4: _set_weapon("bronze_spear")
			KEY_5: _set_weapon("iron_spear")
			KEY_6: _set_weapon("bronze_mace")
			KEY_7: _set_weapon("iron_mace")
			KEY_8: _equip_tool("stone_axe")
			KEY_9: _equip_tool("stone_pickaxe")
			KEY_F: _try_open_crafting()
			KEY_R: _cycle_seed()


func _cycle_seed() -> void:
	# Cycle through any seed (category=="seed") items in inventory.
	var seeds: Array[String] = []
	for item in inventory.items:
		var def: Dictionary = ItemDefs.get_item(item["item_type"])
		if def.get("category", "") == "seed":
			if not seeds.has(item["item_type"]):
				seeds.append(item["item_type"])
	if seeds.is_empty():
		GameManager.log("warn", "No seeds in inventory")
		return
	var idx: int = seeds.find(selected_seed)
	idx = (idx + 1) % seeds.size() if idx >= 0 else 0
	selected_seed = seeds[idx]
	var name: String = ItemDefs.get_item(selected_seed).get("display_name", selected_seed)
	GameManager.log("info", "Selected seed → %s" % name)


func _try_open_crafting() -> void:
	# Open inventory crafting (no station) if not near a station; otherwise open station-specific.
	var station: String = nearest_station_type if not nearest_station_type.is_empty() else "inventory"
	crafting_station_id = nearest_station_id
	var ui: Node = get_tree().current_scene.get_node_or_null("UIContainer/CraftingScreen")
	if ui == null:
		ui = get_tree().current_scene.get_node_or_null("CraftingScreen")
	if ui and ui.has_method("open"):
		ui.open(station)


func _set_weapon(weapon_id: String) -> void:
	equipped_weapon = weapon_id
	var w: Dictionary = WeaponDefs.get_weapon(weapon_id)
	GameManager.log("info", "Weapon → %s (dmg=%d, range=%.1fm)" % [w["display_name"], w["damage"], w["range"]])


func _equip_tool(tool_type: String) -> void:
	# For testing; later goes through proper equip flow
	if not inventory.has_item(tool_type):
		GameManager.log("warn", "Don't have %s" % tool_type)
		return
	# Unequip whatever's in main_hand, equip the tool
	equipment.unequip("main_hand")
	for item in inventory.items:
		if item["item_type"] == tool_type:
			equipment.equip(item["id"], "main_hand", inventory)
			GameManager.log("info", "Equipped %s" % ItemDefs.get_item(tool_type).get("display_name", tool_type))
			return


func _physics_process(delta: float) -> void:
	total_playtime += delta
	_update_sprint(delta)
	_update_stamina(delta)
	_update_hunger(delta)
	_update_nearest_station()
	_process_gathering(delta)
	_process_attack_target()
	_process_structure_interact()
	_process_animal_interact()
	_process_movement(delta)


func _update_nearest_station() -> void:
	# Find nearest non-blueprint structure with a station_type within 3m.
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


func _handle_left_click(screen_pos: Vector2) -> void:
	# Don't intercept clicks while a blueprint placer is active — let it handle.
	var bp: Node = get_tree().current_scene.get_node_or_null("BlueprintPlacer")
	if bp == null:
		bp = get_node_or_null("/root/Main/BlueprintPlacer")
	if bp and bp.has_method("is_active") and bp.is_active():
		return
	_cancel_gather()
	var space_state := get_world_3d().direct_space_state
	var from: Vector3 = camera.project_ray_origin(screen_pos)
	var to: Vector3 = from + camera.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [self.get_rid()])
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit and hit.collider:
		var c = hit.collider
		# Resource node?
		if c.is_in_group("resource_node"):
			gather_target = c
			attack_target = null
			_set_move_target(c.global_position)
			GameManager.log("info", "Targeted %s" % c.resource_type)
			return
		# Structure (blueprint contribute, or station interact)?
		if c.is_in_group("structure"):
			_set_move_target(c.global_position)
			_pending_structure = c
			return
		# Animal?
		if c.is_in_group("animal"):
			_set_move_target(c.global_position)
			_pending_animal = c
			return
		# Enemy?
		if c.has_method("take_damage") and c != self:
			attack_target = c
			gather_target = null
			_set_move_target(c.global_position)
			GameManager.log("info", "Targeted enemy")
			return
	# Ground move
	attack_target = null
	gather_target = null
	_pending_structure = null
	var ground_pos: Vector3 = camera.screen_to_ground(screen_pos)
	_set_move_target(ground_pos)


var _pending_structure: Node = null
var _pending_animal: Node = null


func _process_structure_interact() -> void:
	if _pending_structure == null:
		return
	if not is_instance_valid(_pending_structure):
		_pending_structure = null
		return
	var d: float = global_position.distance_to(_pending_structure.global_position)
	if d > 2.5:
		return
	is_moving = false
	if _pending_structure.has_method("interact"):
		_pending_structure.interact(self)
	_pending_structure = null


func _process_animal_interact() -> void:
	if _pending_animal == null:
		return
	if not is_instance_valid(_pending_animal):
		_pending_animal = null
		return
	var d: float = global_position.distance_to(_pending_animal.global_position)
	if d > 2.0:
		return
	is_moving = false
	if _pending_animal.has_method("interact"):
		_pending_animal.interact(self)
	_pending_animal = null


func _set_move_target(target_pos: Vector3) -> void:
	move_target = target_pos
	if nav_agent:
		nav_agent.target_position = target_pos
	is_moving = true
	NetworkManager.send_move(target_pos)


# --- Gathering ---

func _process_gathering(delta: float) -> void:
	if gather_target == null:
		return
	if not is_instance_valid(gather_target):
		_cancel_gather()
		return
	if gather_target.is_depleted:
		_cancel_gather()
		return
	# Move toward node, then start gather when close
	var dist: float = global_position.distance_to(gather_target.global_position)
	if dist > 2.0:
		# Still walking
		is_gathering = false
		return
	# In range — face it and gather
	is_moving = false
	_face(gather_target.global_position)
	if not is_gathering:
		_start_gather()
	# Tick progress
	gather_progress += delta
	if gather_progress >= gather_total:
		_finish_gather_hit()


func _start_gather() -> void:
	# Auto-equip the appropriate tool from inventory if needed
	if gather_target.required_tool != "":
		var current: String = ""
		if equipment:
			var main: String = equipment.get_equipped_item_type("main_hand", inventory)
			if not main.is_empty():
				current = ItemDefs.get_item(main).get("tool_type", "")
		if current != gather_target.required_tool:
			_auto_equip_tool(gather_target.required_tool)
	# Validate tool + skill
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
	# Find any item in inventory with matching tool_type
	for item in inventory.items:
		var def: Dictionary = ItemDefs.get_item(item["item_type"])
		if def.get("tool_type", "") == tool_type:
			equipment.unequip("main_hand")
			equipment.equip(item["id"], "main_hand", inventory)
			GameManager.log("info", "Auto-equipped %s for %s" % [def.get("display_name", item["item_type"]), tool_type])
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
		# XP
		if gather_target.xp_skill != "" and skills:
			skills.add_xp(gather_target.xp_skill, gather_target.xp_amount)
		GameManager.log("info", "Gathered %s ×%d  [inv: %s]" % [item_type, qty, inventory.summary()])
		_cancel_gather()


func _cancel_gather() -> void:
	gather_target = null
	is_gathering = false
	gather_progress = 0.0


# --- Combat ---

func _process_attack_target() -> void:
	if attack_target == null:
		return
	if not is_instance_valid(attack_target):
		attack_target = null
		return
	if attack_target.has_node("HealthComponent"):
		var hp: HealthComponent = attack_target.get_node("HealthComponent")
		if not hp.is_alive():
			attack_target = null
			is_moving = false
			return
	move_target = attack_target.global_position
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	var dist: float = global_position.distance_to(attack_target.global_position)
	if dist <= weapon["range"]:
		is_moving = false
		_face(attack_target.global_position)
		if combat_sm.current_state == CombatStateMachine.State.IDLE:
			_swing_at_target()


func _swing_at_target() -> void:
	var weapon: Dictionary = WeaponDefs.get_weapon(equipped_weapon)
	if not combat_sm.try_attack(1, 0, weapon["speed"], weapon["stamina_cost"]):
		return
	NetworkManager.send_attack(attack_target.get_instance_id(), 1, 0)
	await get_tree().create_timer(weapon["speed"] * 0.5).timeout
	if not is_instance_valid(attack_target):
		return
	if global_position.distance_to(attack_target.global_position) > weapon["range"] * 1.2:
		return
	var skill_lv: int = skills.get_level("melee_weapons") if skills else 0
	var calc: Dictionary = DamageCalculator.calculate_damage(
		weapon["damage"], 1, weapon["damage_type"], "torso",
		"none", skill_lv, false, "none"
	)
	if attack_target.has_method("take_damage"):
		attack_target.take_damage(calc)
		# XP for hits
		if skills:
			skills.add_xp("melee_weapons", 10)


func _face(pos: Vector3) -> void:
	if model == null:
		return
	var to: Vector3 = pos - global_position
	to.y = 0
	if to.length() > 0.1:
		var target_yaw: float = atan2(to.x, to.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 0.5)


func _update_sprint(_delta: float) -> void:
	is_sprinting = Input.is_action_pressed("sprint") and is_moving and stamina > 0.0


func _process_movement(_delta: float) -> void:
	if not is_moving:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var to_target: Vector3 = move_target - global_position
	to_target.y = 0
	# When chasing a gather/attack target, stop earlier
	var arrive_dist: float = Config.PATH_ARRIVE_THRESHOLD
	if gather_target != null:
		arrive_dist = 1.5
	if to_target.length() < arrive_dist:
		is_moving = false
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var direction: Vector3 = to_target.normalized()
	current_speed = Config.WALK_SPEED
	if is_sprinting:
		current_speed = Config.SPRINT_SPEED
	if combat_sm and combat_sm.current_state == CombatStateMachine.State.ATTACKING:
		current_speed *= 0.7
	current_speed *= _get_encumbrance_modifier()
	velocity = direction * current_speed
	move_and_slide()
	if model and direction.length() > 0.1:
		var target_yaw: float = atan2(direction.x, direction.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw, 0.25)


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

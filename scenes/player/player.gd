class_name PlayerController
extends CharacterBody3D

# C-001 + W-004: Click-to-move player controller.

@onready var camera = $PlayerCamera
@onready var model: Node3D = $PlayerModel
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var move_target: Vector3 = Vector3.ZERO
var is_moving: bool = false
var is_sprinting: bool = false
var current_speed: float = Config.WALK_SPEED

# Stats (full versions land in C-002..C-004)
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
	GameManager.log("info", "Player ready at %s" % str(global_position))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)


func _physics_process(delta: float) -> void:
	total_playtime += delta
	_update_sprint(delta)
	_update_stamina(delta)
	_update_hunger(delta)
	_process_movement(delta)


func _handle_left_click(screen_pos: Vector2) -> void:
	var ground_pos: Vector3 = camera.screen_to_ground(screen_pos)
	# TODO (CO-002): if click hits an enemy collider, route to attack instead.
	_set_move_target(ground_pos)


func _set_move_target(target_pos: Vector3) -> void:
	move_target = target_pos
	if nav_agent:
		nav_agent.target_position = target_pos  # kept for future use
	is_moving = true
	NetworkManager.send_move(target_pos)


func _update_sprint(_delta: float) -> void:
	# W-005: holding sprint while moving + stamina available
	is_sprinting = Input.is_action_pressed("sprint") and is_moving and stamina > 0.0


func _process_movement(_delta: float) -> void:
	if not is_moving:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Direct walk toward move_target. NavigationAgent3D will be re-enabled
	# in W-002 once obstacles + a properly-sized navmesh exist.
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
	current_speed *= _get_encumbrance_modifier()

	velocity = direction * current_speed
	move_and_slide()

	# Rotate model to face movement direction
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
	# Base rate; season modifier wired in W-008.
	hunger -= Config.HUNGER_RATE_BASE * delta
	hunger = max(0.0, hunger)
	if hunger <= 0.0:
		health -= int(delta / 10.0)

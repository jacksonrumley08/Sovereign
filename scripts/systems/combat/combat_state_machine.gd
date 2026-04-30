class_name CombatStateMachine
extends Node

# CO-001: Combat state machine skeleton (7 states, transition rules per spec §2.1).
# Owner exposes: stamina (float), and is consumed via owner.stamina -= cost.

enum State {
	IDLE,
	ATTACKING,
	BLOCKING,
	STAGGERED,
	DODGING,
	DOWNED,
	DEAD,
}

var current_state: State = State.IDLE
var state_timer: float = 0.0
var owner_entity: Node = null

# Attack data
var current_attack_tier: int = 0
var attack_direction: int = 0

# Block
var block_direction: int = 0

# Dodge cooldown
var dodge_cooldown_timer: float = 0.0

# Bleedout
var bleedout_timer: float = 0.0

signal state_changed(old_state: int, new_state: int)
signal attack_executed(tier: int, direction: int)
signal block_hit(damage_blocked: float, stamina_cost: float)
signal entity_downed(bleedout_time: float)
signal entity_died()


func _ready() -> void:
	owner_entity = get_parent()


func _process(delta: float) -> void:
	state_timer = max(0.0, state_timer - delta)
	dodge_cooldown_timer = max(0.0, dodge_cooldown_timer - delta)

	match current_state:
		State.ATTACKING:
			if state_timer <= 0:
				_transition_to(State.IDLE)
		State.STAGGERED:
			if state_timer <= 0:
				_transition_to(State.IDLE)
		State.DODGING:
			if state_timer <= 0:
				_transition_to(State.IDLE)
		State.DOWNED:
			bleedout_timer -= delta
			if bleedout_timer <= 0:
				_transition_to(State.DEAD)
				entity_died.emit()


func try_attack(tier: int, direction: int, weapon_speed: float, stamina_cost: float) -> bool:
	if current_state != State.IDLE:
		return false
	if owner_entity.stamina < stamina_cost:
		return false
	current_attack_tier = tier
	attack_direction = direction
	owner_entity.stamina -= stamina_cost
	var duration: float = weapon_speed
	match tier:
		0: duration *= 0.6
		1: duration *= 1.0
		2: duration *= 1.4
	state_timer = duration
	_transition_to(State.ATTACKING)
	attack_executed.emit(tier, direction)
	return true


func try_block(direction: int) -> bool:
	if current_state != State.IDLE:
		return false
	block_direction = direction
	_transition_to(State.BLOCKING)
	return true


func stop_block() -> void:
	if current_state == State.BLOCKING:
		_transition_to(State.IDLE)


func apply_stagger() -> void:
	state_timer = Config.STAGGER_DURATION
	_transition_to(State.STAGGERED)


func enter_downed(bleedout_time: float) -> void:
	bleedout_timer = bleedout_time
	_transition_to(State.DOWNED)
	entity_downed.emit(bleedout_time)


func can_be_hit() -> bool:
	if current_state == State.DODGING and state_timer > 0:
		return false
	if current_state == State.DEAD:
		return false
	return true


func is_blocking_direction(incoming_dir: int) -> bool:
	if current_state != State.BLOCKING:
		return false
	var diff: int = abs(incoming_dir - block_direction)
	if diff > 4:
		diff = 8 - diff
	return diff <= 1


func state_name() -> String:
	return State.keys()[current_state]


func _transition_to(new_state: State) -> void:
	var old: State = current_state
	current_state = new_state
	state_changed.emit(old, new_state)

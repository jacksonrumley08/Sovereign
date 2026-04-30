class_name HealthComponent
extends Node

# C-002: Reusable health component. No natural regen (per spec §3.3).

@export var max_health: int = 100

var health: int = 100

signal damaged(amount: int)
signal healed(amount: int)
signal died()


func _ready() -> void:
	health = max_health


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	damaged.emit(amount)
	if health <= 0:
		died.emit()


func heal(amount: int) -> void:
	if health <= 0:
		return  # Cannot heal the dead
	var before: int = health
	health = min(max_health, health + amount)
	healed.emit(health - before)


func is_alive() -> bool:
	return health > 0

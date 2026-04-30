extends Node3D

# CO-016: Hit effect particle burst at impact point.

@onready var particles: GPUParticles3D = $GPUParticles3D


func _ready() -> void:
	particles.emitting = true
	# Auto-despawn shortly after particles finish
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	queue_free()

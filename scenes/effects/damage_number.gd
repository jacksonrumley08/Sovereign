extends Node3D

# CO-015: Floating damage number that tweens up + fades.

@onready var label: Label3D = $Label3D

const FLOAT_HEIGHT: float = 2.0
const DURATION: float = 1.0


func setup(amount: int, hit_zone: String, blocked: bool) -> void:
	if blocked:
		label.text = "BLOCKED"
		label.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		label.text = str(amount)
		# Color: red for crit/heavy/head, white normal, gray for low
		if hit_zone == "head" or amount >= 30:
			label.modulate = Color(1, 0.3, 0.3, 1)
		elif amount < 5:
			label.modulate = Color(0.7, 0.7, 0.7, 1)
		else:
			label.modulate = Color(1, 1, 1, 1)


func _ready() -> void:
	var start_pos: Vector3 = global_position
	var end_pos: Vector3 = start_pos + Vector3(0, FLOAT_HEIGHT, 0)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", end_pos, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

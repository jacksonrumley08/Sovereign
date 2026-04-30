extends CanvasLayer

# HC-002/003/004: Real HUD bars for HP, stamina, hunger.
# Mounted top-center under nameplate area. Always visible.

@onready var hp_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/HPBar
@onready var sp_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/SPBar
@onready var hg_bar: ProgressBar = $Panel/MarginContainer/VBoxContainer/HGBar
@onready var hp_label: Label = $Panel/MarginContainer/VBoxContainer/HPBar/Label
@onready var sp_label: Label = $Panel/MarginContainer/VBoxContainer/SPBar/Label
@onready var hg_label: Label = $Panel/MarginContainer/VBoxContainer/HGBar/Label


func _process(_delta: float) -> void:
	var p: Node = GameManager.player
	if p == null:
		return
	hp_bar.max_value = p.max_health
	hp_bar.value = p.health
	hp_label.text = "HP %d / %d" % [p.health, p.max_health]

	sp_bar.max_value = p.max_stamina
	sp_bar.value = p.stamina
	sp_label.text = "SP %d / %d" % [int(p.stamina), int(p.max_stamina)]

	hg_bar.max_value = 100
	hg_bar.value = p.hunger
	hg_label.text = "HG %d" % int(p.hunger)
	# Pulse hunger when low
	if p.hunger < 20:
		hg_bar.modulate = Color(1.0, 0.6, 0.6, 1.0)
	else:
		hg_bar.modulate = Color(1, 1, 1, 1)

extends Control

# Popup seed picker. Opens when player clicks an empty farm plot.
# Lists seeds from player inventory; clicking one plants it on the target plot.

@onready var list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/List
@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var cancel_btn: Button = $Panel/MarginContainer/VBoxContainer/CancelButton

var target_plot: Node = null


func _ready() -> void:
	visible = false
	cancel_btn.pressed.connect(close)


func open_for_plot(plot: Node) -> void:
	target_plot = plot
	visible = true
	_populate()


func close() -> void:
	visible = false
	target_plot = null


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _populate() -> void:
	for c in list.get_children():
		c.queue_free()
	var p: Node = GameManager.player
	if p == null or not p.has_node("Inventory"):
		return
	var inv: Inventory = p.get_node("Inventory")
	# Aggregate seed inventory
	var seed_counts: Dictionary = {}
	for item in inv.items:
		var def: Dictionary = ItemDefs.get_item(item["item_type"])
		if def.get("category", "") == "seed":
			seed_counts[item["item_type"]] = seed_counts.get(item["item_type"], 0) + item["quantity"]
	if seed_counts.is_empty():
		var lbl := Label.new()
		lbl.text = "No seeds in inventory."
		lbl.modulate = Color(0.85, 0.7, 0.6)
		list.add_child(lbl)
		return
	for seed_type in seed_counts.keys():
		var def: Dictionary = ItemDefs.get_item(seed_type)
		var crop_id: String = CropDefs.crop_for_seed(seed_type)
		var crop: Dictionary = CropDefs.get_crop(crop_id)
		var btn := Button.new()
		var grow_min: float = crop.get("growth_seconds", 0.0) / 60.0
		btn.text = "%s ×%d  →  %s (%.0f min, yields %d)" % [
			def.get("display_name", seed_type), seed_counts[seed_type],
			crop.get("display_name", crop_id),
			grow_min, crop.get("yield_qty", 0)
		]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_pick.bind(seed_type))
		list.add_child(btn)


func _on_pick(seed_type: String) -> void:
	if target_plot and target_plot.has_method("plant_seed"):
		target_plot.plant_seed(seed_type, GameManager.player)
	close()

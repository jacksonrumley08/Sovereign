extends Control

# CR-009: Crafting UI. Filters recipes by current station + skill + materials.

@onready var list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/List
@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title

var current_station: String = "inventory"


func _ready() -> void:
	visible = false


func open(station: String) -> void:
	current_station = station
	visible = true
	title.text = "Crafting — %s (F to close)" % station.capitalize()
	_populate()


func close() -> void:
	visible = false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F or event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _populate() -> void:
	for c in list.get_children():
		c.queue_free()
	var p = GameManager.player
	if p == null:
		return
	var inv: Inventory = p.get_node("Inventory")
	var skills: SkillSystem = p.get_node("SkillSystem")
	for r in RecipeDefs.recipes_for_station(current_station):
		var have_all := true
		var mats_str := ""
		for m in r["materials"]:
			var have: int = inv.count_item(m["item_type"])
			mats_str += "%s %d/%d  " % [m["item_type"], have, m["quantity"]]
			if have < m["quantity"]:
				have_all = false
		var skill_lv: int = skills.get_level(r["skill"])
		var skill_ok: bool = skill_lv >= r["skill_req"]
		var btn := Button.new()
		btn.text = "→ %s ×%d  [%s %d]\n  %s" % [r["output"], r["output_quantity"], r["skill"], r["skill_req"], mats_str]
		btn.disabled = not (have_all and skill_ok)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_craft.bind(r["id"]))
		list.add_child(btn)


func _on_craft(recipe_id: String) -> void:
	var p = GameManager.player
	if p == null:
		return
	if not p.has_node("CraftingSystem"):
		return
	var cs: CraftingSystem = p.get_node("CraftingSystem")
	cs.attempt_craft(recipe_id, p.get_node("Inventory"), current_station, p.get_node("SkillSystem"))
	NetworkManager.send_craft(recipe_id, p.crafting_station_id)
	# Refresh the list after the consume
	_populate()

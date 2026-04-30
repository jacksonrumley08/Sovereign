extends Control

# B-014: Build menu. Lists buildable structures; clicking one starts BlueprintPlacer.

@onready var list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/List
@onready var title: Label = $Panel/MarginContainer/VBoxContainer/Title

signal structure_selected(structure_type: String)


func _ready() -> void:
	visible = false
	_populate()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		visible = not visible
		if visible:
			_populate()
		get_viewport().set_input_as_handled()


func _populate() -> void:
	for c in list.get_children():
		c.queue_free()
	var p = GameManager.player
	var inv: Inventory = p.get_node("Inventory") if p and p.has_node("Inventory") else null
	var skills: SkillSystem = p.get_node("SkillSystem") if p and p.has_node("SkillSystem") else null
	for s in StructureDefs.all_buildable():
		var btn := Button.new()
		var mats_str: String = ""
		var have_all := true
		for m in s["materials"]:
			var have: int = inv.count_item(m["item_type"]) if inv else 0
			mats_str += "%s %d/%d  " % [m["item_type"], have, m["quantity"]]
			if have < m["quantity"]:
				have_all = false
		var skill_lv: int = skills.get_level(s["skill"]) if skills else 0
		var skill_ok: bool = skill_lv >= s["skill_req"]
		btn.text = "%s [%s %d]\n  %s" % [s["display_name"], s["skill"], s["skill_req"], mats_str]
		btn.disabled = not (have_all and skill_ok)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_pick.bind(s["id"]))
		list.add_child(btn)


func _on_pick(structure_id: String) -> void:
	structure_selected.emit(structure_id)
	visible = false

extends Control

# K-001/002 UI stub. Press K to open. If no kingdom, prompts to declare via Throne.

@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var name_input: LineEdit = $Panel/MarginContainer/VBoxContainer/NameInput
@onready var found_btn: Button = $Panel/MarginContainer/VBoxContainer/FoundButton
@onready var roles_label: Label = $Panel/MarginContainer/VBoxContainer/RolesLabel
@onready var declare_war_btn: Button = $Panel/MarginContainer/VBoxContainer/DeclareWarButton

var pending_throne: Node = null


func _ready() -> void:
	visible = false
	found_btn.pressed.connect(_on_found_pressed)
	declare_war_btn.pressed.connect(_on_declare_war_pressed)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			visible = not visible
			if visible:
				_refresh()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			visible = false


func open_with_throne(throne: Node) -> void:
	pending_throne = throne
	visible = true
	_refresh()


func _refresh() -> void:
	var ks: KingdomSystem = _get_ks()
	if ks == null or not ks.has_kingdom():
		status_label.text = "No Kingdom"
		if pending_throne:
			status_label.text += " — Throne placed, name your kingdom:"
			name_input.visible = true
			found_btn.visible = true
		else:
			status_label.text += " — Place a Throne first (build menu)"
			name_input.visible = false
			found_btn.visible = false
		roles_label.text = ""
		declare_war_btn.visible = false
	else:
		var k: Dictionary = ks.current_kingdom
		status_label.text = "Kingdom: %s" % k["name"]
		name_input.visible = false
		found_btn.visible = false
		var lines: PackedStringArray = []
		lines.append("Sovereign: %s" % k["sovereign"])
		lines.append("Marshal: %s" % (k["marshal"] if k["marshal"] else "(unassigned)"))
		lines.append("Chancellor: %s" % (k["chancellor"] if k["chancellor"] else "(unassigned)"))
		lines.append("Treasurer: %s" % (k["treasurer"] if k["treasurer"] else "(unassigned)"))
		lines.append("Steward: %s" % (k["steward"] if k["steward"] else "(unassigned)"))
		lines.append("Tax: %.0f%%" % (k["tax_rate"] * 100))
		roles_label.text = "\n".join(lines)
		declare_war_btn.visible = true


func _on_found_pressed() -> void:
	var ks: KingdomSystem = _get_ks()
	if ks == null:
		return
	var name: String = name_input.text.strip_edges()
	if name.is_empty():
		name = "Unnamed Kingdom"
	if pending_throne:
		ks.found_kingdom(name, pending_throne.global_position)
		pending_throne = null
	_refresh()


func _on_declare_war_pressed() -> void:
	var ks: KingdomSystem = _get_ks()
	if ks:
		ks.declare_war("Phantom Realm")  # stub target until other kingdoms exist
	_refresh()


func _get_ks() -> KingdomSystem:
	var p: Node = GameManager.player
	if p and p.has_node("KingdomSystem"):
		return p.get_node("KingdomSystem")
	return null

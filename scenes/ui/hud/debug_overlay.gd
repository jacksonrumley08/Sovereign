extends CanvasLayer

# TB-001: Debug overlay. F3 toggles. Shows FPS, position, velocity, state, etc.

@onready var label: Label = $Panel/MarginContainer/Label

var _visible_state: bool = true


func _ready() -> void:
	# Monospaced font helps numbers stay aligned
	label.add_theme_font_size_override("font_size", 14)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_visible_state = not _visible_state
			visible = _visible_state


func _process(_delta: float) -> void:
	if not _visible_state:
		return
	var fps: int = int(Engine.get_frames_per_second())
	var lines: PackedStringArray = []
	lines.append("FPS: %d" % fps)
	lines.append("Game: day %d, %05.2fh, season=%d" % [GameManager.game_day, GameManager.game_time, GameManager.current_season])

	var p = GameManager.player
	if p:
		lines.append("")
		lines.append("Pos:    %6.2f, %6.2f, %6.2f" % [p.global_position.x, p.global_position.y, p.global_position.z])
		lines.append("Vel:    %6.2f, %6.2f, %6.2f" % [p.velocity.x, p.velocity.y, p.velocity.z])
		lines.append("Speed:  %5.2f m/s" % p.velocity.length())
		lines.append("Moving: %s   Sprint: %s" % [str(p.is_moving), str(p.is_sprinting)])
		if p.has_node("CombatStateMachine"):
			var sm = p.get_node("CombatStateMachine")
			lines.append("Combat: %s" % sm.state_name())
		# Show actual main_hand item from equipment manager
		var main_label: String = p.equipped_weapon
		if p.has_node("EquipmentManager") and p.has_node("Inventory"):
			var eq: EquipmentManager = p.get_node("EquipmentManager")
			var inv: Inventory = p.get_node("Inventory")
			var hand_type: String = eq.get_equipped_item_type("main_hand", inv)
			if not hand_type.is_empty():
				main_label = ItemDefs.get_item(hand_type).get("display_name", hand_type)
		lines.append("Hand:   %s" % main_label)
		lines.append("Target: %s" % ("yes" if p.attack_target else ("gathering" if p.gather_target else "—")))
		lines.append("HP:    %d / %d" % [p.health, p.max_health])
		lines.append("SP:    %5.1f / %5.1f" % [p.stamina, p.max_stamina])
		lines.append("HG:    %5.1f / %5.1f" % [p.hunger, 100.0])
		lines.append("Wt:    %5.1f / %5.1f kg" % [p.carry_weight, p.max_carry_weight])
		lines.append("Play:  %5.1fs" % p.total_playtime)
		# Inventory + gathering
		if p.has_node("Inventory"):
			var inv: Inventory = p.get_node("Inventory")
			lines.append("")
			lines.append("Inv: %s" % inv.summary())
		# Selected seed (R to cycle)
		if "selected_seed" in p:
			var sname: String = ItemDefs.get_item(p.selected_seed).get("display_name", p.selected_seed)
			lines.append("Seed: %s (R to cycle)" % sname)
		if p.is_gathering:
			lines.append("Gather: %.1fs / %.1fs (%s)" % [p.gather_progress, p.gather_total, p.gather_target.resource_type])
		if p.has_node("CraftingSystem"):
			var cs: CraftingSystem = p.get_node("CraftingSystem")
			if cs.is_crafting():
				lines.append("Crafting: %.0f%%  (%s)" % [cs.progress() * 100, cs.active_recipe_id])
		if not p.nearest_station_type.is_empty():
			lines.append("Station: %s (F to craft)" % p.nearest_station_type)
		if p.has_node("KingdomSystem"):
			var kg: KingdomSystem = p.get_node("KingdomSystem")
			if kg.has_kingdom():
				lines.append("Kingdom: %s" % kg.current_kingdom["name"])
			else:
				lines.append("Kingdom: none (K)")
		# Top skills
		if p.has_node("SkillSystem"):
			var sk: SkillSystem = p.get_node("SkillSystem")
			var top: Array = []
			for skill in ["woodcutting", "mining", "quarrying", "farming", "melee_weapons"]:
				var lv: int = sk.get_level(skill)
				var xp: int = sk.get_xp(skill)
				if lv > 1 or xp > 0:
					top.append("%s L%d (%d xp)" % [skill, lv, xp])
			if top.size() > 0:
				lines.append("")
				lines.append("Skills: " + ", ".join(top))
	else:
		lines.append("(no player)")

	lines.append("")
	lines.append("Net: %s   Tick: %d" % ["LOCAL" if NetworkManager.is_local_mode else "ONLINE", NetworkManager.server_tick])
	lines.append("F3 = toggle this overlay")

	label.text = "\n".join(lines)

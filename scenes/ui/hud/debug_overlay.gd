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
		lines.append("HP:    %d / %d" % [p.health, p.max_health])
		lines.append("SP:    %5.1f / %5.1f" % [p.stamina, p.max_stamina])
		lines.append("HG:    %5.1f / %5.1f" % [p.hunger, 100.0])
		lines.append("Wt:    %5.1f / %5.1f kg" % [p.carry_weight, p.max_carry_weight])
		lines.append("Play:  %5.1fs" % p.total_playtime)
	else:
		lines.append("(no player)")

	lines.append("")
	lines.append("Net: %s   Tick: %d" % ["LOCAL" if NetworkManager.is_local_mode else "ONLINE", NetworkManager.server_tick])
	lines.append("F3 = toggle this overlay")

	label.text = "\n".join(lines)

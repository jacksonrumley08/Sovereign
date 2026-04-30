extends Node

enum GameState { MENU, PLAYING, PAUSED, DEAD, LOADING }

var current_state: GameState = GameState.MENU
var player: Node = null  # PlayerController; typed as Node to avoid forward-decl issues in F-002
var current_zone_id: int = 0
var game_time: float = 12.0  # In-game hours (0-24); start at noon
var game_day: int = 1
var current_season: int = 0  # 0=summer, 1=winter
var is_admin: bool = false

signal state_changed(new_state: GameState)
signal time_updated(hours: float, day: int)
signal season_changed(season: int)


func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		_update_game_time(delta)


func _update_game_time(delta: float) -> void:
	# 2 real hours = 1 game day (24 game hours)
	# 1 real second = 24 / 7200 game hours
	game_time += delta * (24.0 / 7200.0)
	if game_time >= 24.0:
		game_time -= 24.0
		game_day += 1
	time_updated.emit(game_time, game_day)


func is_night() -> bool:
	return game_time < 6.0 or game_time > 20.0


func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)


# Lightweight log helper used by other systems (to avoid a separate Logger autoload).
# Levels: "info", "warn", "error", "debug".
func log(level: String, msg: String) -> void:
	var prefix: String = "[%s]" % level.to_upper()
	match level:
		"error":
			push_error("%s %s" % [prefix, msg])
		"warn":
			push_warning("%s %s" % [prefix, msg])
		_:
			print("%s %s" % [prefix, msg])

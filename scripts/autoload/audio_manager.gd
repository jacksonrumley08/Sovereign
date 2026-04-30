extends Node

# F-002 stub; AU2-001 builds the bus layout, AU2-002+ wire actual SFX.
# Exposes the API combat/movement/UI tickets will call.


func play_sfx(_stream: AudioStream, _world_position: Vector3 = Vector3.ZERO) -> void:
	# Stub: AU2-001 implements 3D positional playback.
	pass


func play_music(_stream: AudioStream) -> void:
	pass


func play_ambient(_stream: AudioStream) -> void:
	pass


func set_bus_volume(_bus_name: String, _volume_db: float) -> void:
	pass

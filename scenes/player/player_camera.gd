extends Camera3D

# W-003: Isometric orthographic camera with zoom + follow.
# (No class_name to avoid load-order issues with autoload Config.)

var target: Node3D = null
var current_zoom: float = 12.0  # Set properly in _ready() once Config is available


func _ready() -> void:
	current_zoom = Config.CAMERA_ZOOM_DEFAULT
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = current_zoom
	rotation_degrees = Vector3(Config.CAMERA_ANGLE_X, Config.CAMERA_ANGLE_Y, 0.0)
	GameManager.log("info", "PlayerCamera ready, projection=ORTHO, size=%.1f, rot=%s" % [size, str(rotation_degrees)])


func _process(delta: float) -> void:
	if target:
		global_position = global_position.lerp(
			target.global_position + _get_camera_offset(),
			Config.CAMERA_FOLLOW_SPEED * delta
		)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = max(Config.CAMERA_ZOOM_MIN, current_zoom - Config.CAMERA_ZOOM_SPEED)
			size = current_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = min(Config.CAMERA_ZOOM_MAX, current_zoom + Config.CAMERA_ZOOM_SPEED)
			size = current_zoom


func _get_camera_offset() -> Vector3:
	# Position the camera so it looks at the target from the isometric angle.
	var distance: float = 20.0
	var angle_x_rad: float = deg_to_rad(Config.CAMERA_ANGLE_X)
	var angle_y_rad: float = deg_to_rad(Config.CAMERA_ANGLE_Y)
	return Vector3(
		distance * cos(angle_x_rad) * sin(angle_y_rad),
		distance * sin(-angle_x_rad),
		distance * cos(angle_x_rad) * cos(angle_y_rad)
	)


# Project a screen-space position to the y=0 ground plane.
func screen_to_ground(screen_pos: Vector2) -> Vector3:
	var from: Vector3 = project_ray_origin(screen_pos)
	var dir: Vector3 = project_ray_normal(screen_pos)
	if abs(dir.y) < 0.0001:
		return Vector3.ZERO
	var t: float = -from.y / dir.y
	return from + dir * t

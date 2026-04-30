extends Node3D

# W-002: Flat terrain mesh + NavigationRegion3D bake.
# Replaced by heightmap-based per-zone terrain post-MVP.

const ZONE_SIZE: float = 500.0  # meters per zone (per spec §2.1)
const WORLD_ZONES: int = 3       # 3x3 starting grid

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	GameManager.log("info", "Terrain ready, baking navmesh...")
	_bake_navigation()


func _bake_navigation() -> void:
	# Use the existing navmesh on the NavigationRegion3D; bake at runtime.
	var nav_mesh: NavigationMesh = nav_region.navigation_mesh
	if nav_mesh == null:
		GameManager.log("warn", "NavigationRegion3D has no NavigationMesh resource; creating default")
		nav_mesh = NavigationMesh.new()
		nav_mesh.agent_radius = 0.4
		nav_mesh.agent_height = 1.8
		nav_region.navigation_mesh = nav_mesh
	nav_region.bake_navigation_mesh()
	GameManager.log("info", "Navmesh baked")

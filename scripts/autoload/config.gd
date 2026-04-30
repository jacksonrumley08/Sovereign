extends Node

# Camera
const CAMERA_ANGLE_X: float = -45.0
const CAMERA_ANGLE_Y: float = 45.0
const CAMERA_ZOOM_MIN: float = 5.0
const CAMERA_ZOOM_MAX: float = 25.0
const CAMERA_ZOOM_DEFAULT: float = 12.0
const CAMERA_ZOOM_SPEED: float = 2.0
const CAMERA_FOLLOW_SPEED: float = 8.0

# Movement
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const SPRINT_STAMINA_COST: float = 10.0
const ROAD_SPEED_BONUS: float = 0.25
const PATH_ARRIVE_THRESHOLD: float = 0.3

# Server / tick
const TICK_RATE: int = 20
const TICK_DELTA: float = 0.05

# Lamports
const LAMPORTS_PER_SOL: int = 1_000_000_000

# Hunger
const HUNGER_RATE_BASE: float = 1.0 / 60.0  # per second; modified by season

# Stamina regen
const STAMINA_REGEN_RATE: float = 5.0  # SP/sec when not acting

# Combat (referenced from CombatStateMachine)
const STAGGER_DURATION: float = 0.5
const DODGE_DURATION: float = 0.3
const DODGE_SPEED: float = 15.0
const DODGE_STAMINA_COST: float = 20.0
const DODGE_COOLDOWN: float = 1.0

extends Node

# OLOV
const TORCH_FUEL_MAX: float = 100.0
const TORCH_DRAIN_RATE: float = 5.0
const BEACON_FUEL_MAX: float = 100.0
const BEACON_DRAIN_RATE: float = 2.0
const BEACON_COST: float = 20.0
const WOLF_BEACON_DRAIN_MULT: float = 5.0

# HARAKAT
const PLAYER_SPEED: float = 150.0
const PLAYER_JUMP_FORCE: float = -300.0
const GRAVITY: float = 600.0
const WOLF_SPEED_BASE: float = 80.0
const WOLF_SPEED_MAX: float = 180.0
const PATH_CENTER_Y: float = 250.0
const PATH_HALF_WIDTH: float = 118.0

# SPAWN
const WOLF_SPAWN_INTERVAL_START: float = 8.0
const WOLF_SPAWN_INTERVAL_MIN: float = 2.0
const FAMILY_PER_BEACON_MIN: int = 1
const FAMILY_PER_BEACON_MAX: int = 3

# SCORE
const SCORE_PER_METER: float = 1.0
const SCORE_PER_BEACON: int = 100
const SCORE_PER_FAMILY: int = 50
const SACRIFICE_BONUS: int = 1000
const SACRIFICE_MULTIPLIER: float = 3.0

# QIYINLIK
const DIFFICULTY_RAMP_TIME: float = 30.0

func path_y(x: float) -> float:
	return PATH_CENTER_Y + sin(x * 0.006) * 70.0 + sin(x * 0.019 + 1.7) * 24.0

func path_normal(x: float) -> Vector2:
	var y1 := path_y(x - 8.0)
	var y2 := path_y(x + 8.0)
	return Vector2(-(y2 - y1), 16.0).normalized()

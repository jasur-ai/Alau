extends Node

func get_wolf_spawn_interval() -> float:
	var distance = PlayerStats.distance_traveled
	return max(Constants.WOLF_SPAWN_INTERVAL_MIN, Constants.WOLF_SPAWN_INTERVAL_START - distance / 10.0)

func get_wolf_speed() -> float:
	return clamp(Constants.WOLF_SPEED_BASE + PlayerStats.distance_traveled / 20.0, Constants.WOLF_SPEED_BASE, Constants.WOLF_SPEED_MAX)

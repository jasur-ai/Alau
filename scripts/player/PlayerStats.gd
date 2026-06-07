extends Node

var torch_fuel: float = 100.0
var score: float = 0.0
var beacon_count: int = 0
var distance_traveled: float = 0.0
var families_saved: int = 0
var sacrificed: bool = false

func reset() -> void:
	torch_fuel = 100.0
	score = 0.0
	beacon_count = 0
	distance_traveled = 0.0
	families_saved = 0
	sacrificed = false

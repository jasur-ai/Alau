extends Node2D

var beacon_positions: Array[Vector2] = []
var trail_positions: Array[Vector2] = []
var active_count: int = 0
var total_placed: int = 0

func _ready() -> void:
	SignalBus.beacon_placed.connect(_on_beacon_placed)
	SignalBus.beacon_extinguished.connect(_on_beacon_extinguished)

func _on_beacon_placed(position: Vector2) -> void:
	beacon_positions.append(position)
	trail_positions.append(position)
	active_count = beacon_positions.size()
	total_placed += 1

func _on_beacon_extinguished(position: Vector2) -> void:
	beacon_positions = beacon_positions.filter(func(p): return p != position)
	active_count = beacon_positions.size()

func get_all_positions() -> Array:
	return trail_positions.duplicate()

func refuel_all() -> void:
	for beacon in get_tree().get_nodes_in_group("beacons"):
		if beacon.has_method("take_damage"):
			beacon.fuel = Constants.BEACON_FUEL_MAX
			beacon.light.energy = remap(beacon.fuel, 0.0, Constants.BEACON_FUEL_MAX, 0.1, 1.5)

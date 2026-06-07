extends Node

func _ready() -> void:
	SignalBus.beacon_extinguished.connect(_on_beacon_extinguished)

func _process(_delta: float) -> void:
	if PlayerStats.torch_fuel <= 20.0:
		SignalBus.fire_low.emit(PlayerStats.torch_fuel / Constants.TORCH_FUEL_MAX)

func _on_beacon_extinguished(_position: Vector2) -> void:
	# When a beacon goes out, the world feels darker.
	pass

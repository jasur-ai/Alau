extends Node2D

@export var family_scene: PackedScene = preload("res://scenes/npcs/Family.tscn")

func _ready() -> void:
	SignalBus.beacon_placed.connect(_on_beacon_placed)
	SignalBus.beacon_extinguished.connect(_on_beacon_extinguished)

func _on_beacon_placed(position: Vector2) -> void:
	var count = randi() % (Constants.FAMILY_PER_BEACON_MAX - Constants.FAMILY_PER_BEACON_MIN + 1) + Constants.FAMILY_PER_BEACON_MIN
	for i in range(count):
		var family = family_scene.instantiate()
		get_parent().add_child(family)
		var side = -1.0 if i % 2 == 0 else 1.0
		family.global_position = position + Vector2(randf_range(-90.0, -45.0), side * randf_range(42.0, 86.0))

func _on_beacon_extinguished(_position: Vector2) -> void:
	# Families pause when their beacon dies.
	pass

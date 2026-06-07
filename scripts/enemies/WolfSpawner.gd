extends Node2D

@export var wolf_scene: PackedScene = preload("res://scenes/enemies/Wolf.tscn")
@onready var player = get_parent().get_node("Player")
@onready var timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_Timer_timeout)
	var manager = _get_difficulty_manager()
	timer.wait_time = manager.get_wolf_spawn_interval() if manager else Constants.WOLF_SPAWN_INTERVAL_START
	timer.start()

func _on_Timer_timeout() -> void:
	spawn_wolf()
	var manager = _get_difficulty_manager()
	timer.wait_time = manager.get_wolf_spawn_interval() if manager else Constants.WOLF_SPAWN_INTERVAL_START
	timer.start()

func _get_difficulty_manager() -> Node:
	var scene = get_tree().get_current_scene()
	if scene and scene.has_node("DifficultyManager"):
		return scene.get_node("DifficultyManager")
	return null

func spawn_wolf() -> void:
	var wolf = wolf_scene.instantiate()
	get_parent().add_child(wolf)
	var spawn_x = player.global_position.x + randf_range(520.0, 780.0)
	var side = -1.0 if randf() < 0.5 else 1.0
	var spawn_y = Constants.path_y(spawn_x) + side * randf_range(Constants.PATH_HALF_WIDTH + 70.0, Constants.PATH_HALF_WIDTH + 170.0)
	wolf.global_position = Vector2(spawn_x, spawn_y)

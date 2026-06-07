extends CharacterBody2D

const BEACON_SCENE = preload("res://scenes/fire/beacon.tscn")

var _last_x: float = 0.0
var _sacrificing: bool = false
var _flame_time: float = 0.0
var _lane_offset: float = 0.0

func _ready() -> void:
	_last_x = global_position.x
	global_position.y = Constants.path_y(global_position.x)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_flame_time += delta
	var forward_input: float = Input.get_axis("ui_left", "ui_right")
	var lane_input: float = Input.get_axis("ui_up", "ui_down")
	var forward_speed: float = Constants.PLAYER_SPEED + max(0.0, forward_input) * 65.0
	_lane_offset = clamp(_lane_offset + lane_input * 170.0 * delta, -Constants.PATH_HALF_WIDTH + 18.0, Constants.PATH_HALF_WIDTH - 18.0)

	global_position.x += forward_speed * delta
	global_position.y = lerp(global_position.y, Constants.path_y(global_position.x) + _lane_offset, min(1.0, delta * 9.0))
	velocity = Vector2(forward_speed, 0.0)

	PlayerStats.distance_traveled += max(0.0, global_position.x - _last_x)
	_last_x = global_position.x

	if Input.is_action_just_pressed("place_beacon") or Input.is_action_just_pressed("ui_select"):
		_place_beacon()

	if Input.is_action_just_pressed("sacrifice") and not _sacrificing:
		_trigger_sacrifice()

	if not _sacrificing:
		PlayerStats.torch_fuel -= Constants.TORCH_DRAIN_RATE * delta
		if PlayerStats.torch_fuel <= 0:
			PlayerStats.torch_fuel = 0
			SignalBus.game_over.emit()

	queue_redraw()

func _draw() -> void:
	if _sacrificing:
		var pulse = 1.0 + sin(_flame_time * 12.0) * 0.18
		draw_circle(Vector2.ZERO, 42.0 * pulse, Color(1.0, 0.22, 0.02, 0.28))
		draw_circle(Vector2(0, -8), 28.0 * pulse, Color(1.0, 0.68, 0.08, 0.72))
		draw_circle(Vector2(0, -18), 14.0 * pulse, Color(1.0, 0.95, 0.35, 0.9))
		return

	var step = sin(_flame_time * 16.0) * 2.2
	draw_rect(Rect2(Vector2(-17, 12), Vector2(34, 9)), Color(0, 0, 0, 0.18))
	draw_line(Vector2(-7, 7), Vector2(-10, 18 + step), Color(0.16, 0.09, 0.04), 4.0)
	draw_line(Vector2(7, 7), Vector2(10, 18 - step), Color(0.16, 0.09, 0.04), 4.0)
	draw_circle(Vector2.ZERO, 15.0, Color(0.54, 0.25, 0.08))
	draw_circle(Vector2(0, -4), 10.0, Color(0.86, 0.52, 0.18))
	draw_circle(Vector2(0, -16), 8.0, Color(0.68, 0.36, 0.16))
	draw_rect(Rect2(Vector2(-12, -24), Vector2(24, 6)), Color(0.22, 0.12, 0.05))
	draw_line(Vector2(8, -2), Vector2(24, -14), Color(0.16, 0.09, 0.04), 3.0)
	draw_line(Vector2(24, -14), Vector2(30, -27), Color(0.2, 0.12, 0.04), 3.0)
	_draw_flame(Vector2(32, -33), 9.0)

func _draw_flame(center: Vector2, radius: float) -> void:
	var pulse = 1.0 + sin(_flame_time * 18.0) * 0.14
	draw_circle(center, radius * 1.75 * pulse, Color(1.0, 0.25, 0.0, 0.22))
	draw_circle(center, radius * pulse, Color(1.0, 0.34, 0.02))
	draw_circle(center + Vector2(0, -3), radius * 0.56 * pulse, Color(1.0, 0.88, 0.22))

func _place_beacon() -> void:
	if PlayerStats.torch_fuel < Constants.BEACON_COST:
		return
	PlayerStats.torch_fuel -= Constants.BEACON_COST
	var beacon = BEACON_SCENE.instantiate()
	var parent = get_tree().current_scene if get_tree().current_scene else get_parent()
	parent.add_child(beacon)
	beacon.global_position = global_position
	SignalBus.beacon_placed.emit(global_position)
	PlayerStats.beacon_count += 1

func _trigger_sacrifice() -> void:
	_sacrificing = true
	PlayerStats.sacrificed = true
	PlayerStats.torch_fuel = 0.0
	SignalBus.sacrifice_triggered.emit()

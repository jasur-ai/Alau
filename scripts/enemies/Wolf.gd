extends CharacterBody2D

enum State {
	WANDER,
	CHASE_BEACON,
	ATTACK,
	HOWL,
}

var current_state: State = State.WANDER
var target: Node = null
var wander_timer: float = 0.0
var howl_timer: float = 0.0
var _time: float = 0.0

func _physics_process(delta: float) -> void:
	_time += delta
	match current_state:
		State.WANDER:
			_wander(delta)
			_try_find_beacon()
		State.CHASE_BEACON:
			_chase_beacon(delta)
		State.ATTACK:
			_attack(delta)
		State.HOWL:
			_howl(delta)

	move_and_slide()
	queue_redraw()

func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(1.0, 2.5)
		velocity = Vector2(randf_range(-1.0, 1.0), randf_range(-0.65, 0.65)).normalized() * get_wander_speed()

func _try_find_beacon() -> void:
	var next_beacon = _get_target_beacon()
	if next_beacon:
		target = next_beacon
		current_state = State.CHASE_BEACON

func _chase_beacon(delta: float) -> void:
	if not is_instance_valid(target):
		current_state = State.WANDER
		return
	var manager = _get_difficulty_manager()
	var speed = manager.get_wolf_speed() if manager else Constants.WOLF_SPEED_BASE
	velocity = (target.global_position - global_position).normalized() * speed
	if global_position.distance_to(target.global_position) < 24.0:
		current_state = State.ATTACK

func _get_difficulty_manager() -> Node:
	var scene = get_tree().get_current_scene()
	if scene and scene.has_node("DifficultyManager"):
		return scene.get_node("DifficultyManager")
	return null

func _attack(delta: float) -> void:
	if not is_instance_valid(target):
		current_state = State.WANDER
		return
	velocity = Vector2.ZERO
	if target.has_method("take_damage"):
		target.take_damage(Constants.BEACON_DRAIN_RATE * Constants.WOLF_BEACON_DRAIN_MULT * delta)
	if target.has_method("take_damage") and target.fuel <= 0.0:
		current_state = State.HOWL
		howl_timer = 1.0
		return
	if global_position.distance_to(target.global_position) > 40.0:
		current_state = State.CHASE_BEACON

func _howl(delta: float) -> void:
	howl_timer -= delta
	velocity = Vector2.ZERO
	if howl_timer <= 0.0:
		current_state = State.WANDER

func _get_target_beacon() -> Node:
	var beacons = get_tree().get_nodes_in_group("beacons")
	if beacons.is_empty():
		return null
	return beacons.min_by(func(b): return global_position.distance_to(b.global_position))

func get_wander_speed() -> float:
	return Constants.WOLF_SPEED_BASE

func _draw() -> void:
	var attack := current_state == State.ATTACK
	var body_color := Color(0.09, 0.10, 0.10)
	var fur_color := Color(0.18, 0.18, 0.16)
	var eye_color := Color(1.0, 0.14, 0.05) if attack else Color(0.95, 0.55, 0.12)
	var step := sin(_time * 14.0) * 4.0

	draw_rect(Rect2(Vector2(-20, 12), Vector2(43, 9)), Color(0, 0, 0, 0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(-28, 0), Vector2(-47, -10), Vector2(-35, 7)]), body_color)
	draw_circle(Vector2(-10, 0), 17.0, body_color)
	draw_circle(Vector2(13, -1), 14.0, fur_color)
	draw_colored_polygon(PackedVector2Array([Vector2(25, -2), Vector2(44, -11), Vector2(39, 8)]), fur_color)
	draw_colored_polygon(PackedVector2Array([Vector2(5, -14), Vector2(10, -30), Vector2(17, -13)]), body_color)
	draw_colored_polygon(PackedVector2Array([Vector2(18, -13), Vector2(29, -25), Vector2(28, -8)]), body_color)
	draw_circle(Vector2(30, -6), 2.4, eye_color)
	draw_circle(Vector2(31, 3), 2.4, eye_color)
	draw_line(Vector2(-12, 12), Vector2(-20, 25 + step), body_color, 4.0)
	draw_line(Vector2(7, 12), Vector2(1, 25 - step), body_color, 4.0)
	draw_line(Vector2(-13, -11), Vector2(-23, -23 - step), body_color, 4.0)
	draw_line(Vector2(8, -11), Vector2(2, -24 + step), body_color, 4.0)
	if attack:
		draw_arc(Vector2(22, 0), 32.0, -0.9, 0.9, 16, Color(1.0, 0.18, 0.0, 0.38), 3.0)

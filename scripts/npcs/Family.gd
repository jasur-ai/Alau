extends CharacterBody2D

var target_beacon: Node = null
var safe: bool = false
var speed: float = 25.0
var _time: float = 0.0

func _ready() -> void:
	SignalBus.beacon_placed.connect(_on_beacon_placed)
	SignalBus.beacon_extinguished.connect(_on_beacon_extinguished)
	queue_redraw()

func _physics_process(delta: float) -> void:
	_time += delta
	if safe:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if not is_instance_valid(target_beacon):
		target_beacon = _find_nearest_beacon()
	if target_beacon:
		var direction = (target_beacon.global_position - global_position)
		velocity = direction.normalized() * speed
		move_and_slide()
		if global_position.distance_to(target_beacon.global_position) < 20.0:
			safe = true
			PlayerStats.families_saved += 1
	else:
		velocity = Vector2.ZERO
	queue_redraw()

func _on_beacon_placed(_position: Vector2) -> void:
	target_beacon = _find_nearest_beacon()

func _on_beacon_extinguished(_position: Vector2) -> void:
	if is_instance_valid(target_beacon) and target_beacon.global_position == _position:
		target_beacon = null

func _find_nearest_beacon() -> Node:
	var beacons = get_tree().get_nodes_in_group("beacons")
	if beacons.is_empty():
		return null
	return beacons.min_by(func(b): return global_position.distance_to(b.global_position))

func _draw() -> void:
	var body_color := Color(0.23, 0.42, 0.46) if safe else Color(0.34, 0.22, 0.12)
	var cloth_color := Color(0.88, 0.68, 0.28) if safe else Color(0.62, 0.42, 0.18)
	var step := sin(_time * 9.0) * 2.0
	_draw_person(Vector2(-13, 0), 0.82, body_color, cloth_color, step)
	_draw_person(Vector2(2, 1), 0.9, body_color.darkened(0.08), cloth_color.lightened(0.08), -step)
	_draw_person(Vector2(15, 5), 0.58, body_color.lightened(0.12), cloth_color, step)
	if safe:
		draw_arc(Vector2(0, -21), 23.0, PI * 1.08, PI * 1.92, 16, Color(1.0, 0.7, 0.16, 0.7), 2.0)

func _draw_person(origin: Vector2, scale: float, body_color: Color, cloth_color: Color, step: float) -> void:
	draw_circle(origin + Vector2(0, 8) * scale, 8.0 * scale, Color(0, 0, 0, 0.18))
	draw_circle(origin, 7.0 * scale, cloth_color)
	draw_circle(origin + Vector2(0, -7) * scale, 4.5 * scale, Color(0.66, 0.38, 0.18))
	draw_line(origin + Vector2(-3, 3) * scale, origin + Vector2(-9, 9 + step) * scale, body_color, 2.0 * scale)
	draw_line(origin + Vector2(4, 3) * scale, origin + Vector2(10, 9 - step) * scale, body_color, 2.0 * scale)

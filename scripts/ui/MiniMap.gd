extends Control

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.025, 0.022, 0.015, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.58, 0.18, 0.85), false, 2.0)
	draw_string(get_theme_default_font(), Vector2(10, 18), "IZ MAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.83, 0.45))

	var scene = get_tree().current_scene
	if not scene or not scene.has_method("get_player_map_position"):
		return

	var player_pos: Vector2 = scene.get_player_map_position()
	var trail: Array = scene.get_beacon_trail() if scene.has_method("get_beacon_trail") else []
	var families: Array = scene.get_family_map_positions() if scene.has_method("get_family_map_positions") else []
	var wolves: Array = scene.get_wolf_map_positions() if scene.has_method("get_wolf_map_positions") else []
	var pickups: Array = scene.get_pickup_map_positions() if scene.has_method("get_pickup_map_positions") else []

	var origin_x := player_pos.x - 70.0
	var end_x := player_pos.x + 45.0
	var map_rect := Rect2(10.0, 28.0, size.x - 20.0, size.y - 38.0)

	var road := PackedVector2Array()
	var x := origin_x
	while x <= end_x:
		road.append(_map_point(Vector2(x, _path_z(x)), origin_x, end_x, player_pos.y, map_rect))
		x += 4.0
	if road.size() > 1:
		draw_polyline(road, Color(0.46, 0.31, 0.12, 0.95), 7.0)

	for i in range(1, trail.size()):
		var a: Vector2 = trail[i - 1]
		var b: Vector2 = trail[i]
		if b.x < origin_x or a.x > end_x:
			continue
		draw_line(_map_point(a, origin_x, end_x, player_pos.y, map_rect), _map_point(b, origin_x, end_x, player_pos.y, map_rect), Color(1.0, 0.24, 0.02, 0.75), 2.0)

	for pos in trail:
		if pos.x >= origin_x and pos.x <= end_x:
			draw_circle(_map_point(pos, origin_x, end_x, player_pos.y, map_rect), 3.2, Color(1.0, 0.75, 0.12))
	for pos in families:
		if pos.x >= origin_x and pos.x <= end_x:
			draw_circle(_map_point(pos, origin_x, end_x, player_pos.y, map_rect), 2.7, Color(0.35, 1.0, 0.72))
	for pos in pickups:
		if pos.x >= origin_x and pos.x <= end_x:
			draw_circle(_map_point(pos, origin_x, end_x, player_pos.y, map_rect), 2.4, Color(0.9, 0.9, 0.55))
	for pos in wolves:
		if pos.x >= origin_x and pos.x <= end_x:
			draw_circle(_map_point(pos, origin_x, end_x, player_pos.y, map_rect), 3.4, Color(0.1, 0.5, 1.0))

	draw_circle(_map_point(player_pos, origin_x, end_x, player_pos.y, map_rect), 4.6, Color(1.0, 0.96, 0.48))

func _map_point(world_pos: Vector2, origin_x: float, end_x: float, center_z: float, map_rect: Rect2) -> Vector2:
	var x_ratio := inverse_lerp(origin_x, end_x, world_pos.x)
	var y_ratio := inverse_lerp(center_z - 35.0, center_z + 35.0, world_pos.y)
	return Vector2(map_rect.position.x + clamp(x_ratio, 0.0, 1.0) * map_rect.size.x, map_rect.position.y + clamp(y_ratio, 0.0, 1.0) * map_rect.size.y)

func _path_z(x: float) -> float:
	return sin(x * 0.055) * 7.2 + sin(x * 0.017 + 1.2) * 12.0

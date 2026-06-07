extends Node2D

@onready var player = get_parent().get_node_or_null("Player")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var center_x := 0.0
	if is_instance_valid(player):
		center_x = player.global_position.x

	var left := center_x - 900.0
	var right := center_x + 1000.0
	draw_rect(Rect2(left, -1400.0, right - left, 2800.0), Color(0.13, 0.21, 0.15))
	_draw_ground_texture(left, right)
	_draw_path(left, right)
	_draw_beacon_light()
	_draw_old_trail()

func _draw_path(left: float, right: float) -> void:
	var center_line := PackedVector2Array()
	var step := 26.0
	var x := left - 80.0
	while x <= right + 80.0:
		center_line.append(Vector2(x, Constants.path_y(x)))
		x += step

	draw_polyline(center_line, Color(0.24, 0.16, 0.07, 0.78), Constants.PATH_HALF_WIDTH * 2.15)
	draw_polyline(center_line, Color(0.38, 0.27, 0.13), Constants.PATH_HALF_WIDTH * 1.82)
	draw_polyline(center_line, Color(0.47, 0.34, 0.16, 0.35), Constants.PATH_HALF_WIDTH * 0.56)

	for point in center_line:
		var normal := Constants.path_normal(point.x)
		draw_circle(point - normal * Constants.PATH_HALF_WIDTH, 3.0, Color(0.25, 0.18, 0.08, 0.35))
		draw_circle(point + normal * Constants.PATH_HALF_WIDTH, 3.0, Color(0.25, 0.18, 0.08, 0.35))

	x = left - 50.0
	while x <= right + 50.0:
		var c := Vector2(x, Constants.path_y(x))
		var n := Constants.path_normal(x)
		draw_line(c - n * 92.0, c + n * 92.0, Color(0.47, 0.34, 0.16, 0.18), 2.0)
		x += 72.0

func _draw_ground_texture(left: float, right: float) -> void:
	var start := int(floor(left / 42.0)) - 4
	var finish := int(ceil(right / 42.0)) + 4
	for i in range(start, finish):
		var x := float(i) * 42.0
		for j in range(-8, 9):
			if (i * 31 + j * 17) % 5 == 0:
				var y := float(j) * 70.0 + sin(float(i + j) * 2.1) * 18.0
				var color := Color(0.20, 0.32, 0.14) if abs(Constants.path_y(x) - y) > Constants.PATH_HALF_WIDTH + 20.0 else Color(0.42, 0.32, 0.15)
				draw_line(Vector2(x, y), Vector2(x + 7.0, y - 10.0), color, 2.0)
			if (i * 13 + j * 11) % 19 == 0:
				var sy := float(j) * 70.0 + 28.0
				draw_circle(Vector2(x + 15.0, sy), 3.0, Color(0.08, 0.10, 0.08, 0.55))

func _draw_beacon_light() -> void:
	for beacon in get_tree().get_nodes_in_group("beacons"):
		if not is_instance_valid(beacon):
			continue
		var level = beacon.get("fuel") / Constants.BEACON_FUEL_MAX
		draw_circle(beacon.global_position, 140.0 * level, Color(1.0, 0.42, 0.04, 0.12))
		draw_circle(beacon.global_position, 68.0 * level, Color(1.0, 0.66, 0.12, 0.10))

func _draw_old_trail() -> void:
	var manager = get_parent().get_node_or_null("BeaconManager")
	if not manager:
		return
	var positions: Array = manager.get_all_positions()
	for i in range(1, positions.size()):
		draw_line(positions[i - 1], positions[i], Color(1.0, 0.28, 0.02, 0.33), 4.0)

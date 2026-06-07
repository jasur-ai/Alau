extends Control

var positions: Array = []
var sacrificed: bool = false

func set_trail(new_positions: Array, did_sacrifice: bool) -> void:
	positions = new_positions.duplicate()
	sacrificed = did_sacrifice
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.018, 0.016, 0.026, 0.98))
	for y in range(16, int(size.y), 28):
		draw_line(Vector2(0, y), Vector2(size.x, y + sin(float(y) * 0.04) * 12.0), Color(0.20, 0.14, 0.08, 0.32), 1.0)
	for x in range(0, int(size.x), 52):
		draw_line(Vector2(x, size.y), Vector2(x + 36, size.y - 24), Color(0.12, 0.20, 0.10, 0.35), 2.0)

	if positions.is_empty():
		draw_circle(size * 0.5, 44.0, Color(0.1, 0.55, 1.0, 0.12))
		draw_string(get_theme_default_font(), Vector2(24, size.y * 0.5), "Iz qolmadi. Ko'k Bo'ri jim turib kuzatadi.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(1, 0.8, 0.45))
		return

	var min_x: float = positions[0].x
	var max_x: float = positions[0].x
	for pos in positions:
		min_x = min(min_x, pos.x)
		max_x = max(max_x, pos.x)

	var span: float = max(1.0, max_x - min_x)
	var mapped: Array[Vector2] = []
	for i in range(positions.size()):
		var pos: Vector2 = positions[i]
		var x: float = 24.0 + ((pos.x - min_x) / span) * max(1.0, size.x - 48.0)
		var y: float = size.y * 0.55 + sin(float(i) * 1.7) * 26.0
		mapped.append(Vector2(x, y))

	for i in range(1, mapped.size()):
		draw_line(mapped[i - 1], mapped[i], Color(0.32, 0.19, 0.08, 0.75), 8.0)
		draw_line(mapped[i - 1], mapped[i], Color(1.0, 0.26, 0.02, 0.9), 3.0)

	for i in range(mapped.size()):
		var radius := 7.0
		if sacrificed and i == mapped.size() - 1:
			radius = 13.0
		draw_circle(mapped[i], radius + 8.0, Color(1.0, 0.35, 0.02, 0.14))
		draw_circle(mapped[i], radius, Color(1.0, 0.74, 0.10))
		draw_circle(mapped[i] + Vector2(0, -3), radius * 0.45, Color(1.0, 0.96, 0.42))

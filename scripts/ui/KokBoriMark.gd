extends Control

func _draw() -> void:
	var c := size * 0.5
	var blue := Color(0.1, 0.68, 1.0, 0.96)
	var blue_dark := Color(0.02, 0.18, 0.34, 0.94)
	var glow := Color(0.15, 0.72, 1.0, 0.18)
	draw_circle(c, min(size.x, size.y) * 0.42, glow)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-58, -8),
		c + Vector2(-34, -74),
		c + Vector2(-6, -28),
		c + Vector2(34, -76),
		c + Vector2(58, -6),
		c + Vector2(46, 42),
		c + Vector2(0, 72),
		c + Vector2(-48, 42),
	]), blue_dark)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-48, -3),
		c + Vector2(-26, -48),
		c + Vector2(-2, -17),
		c + Vector2(27, -50),
		c + Vector2(49, -1),
		c + Vector2(35, 28),
		c + Vector2(0, 52),
		c + Vector2(-36, 28),
	]), blue)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-34, 6),
		c + Vector2(-9, 18),
		c + Vector2(0, 45),
		c + Vector2(9, 18),
		c + Vector2(34, 6),
		c + Vector2(12, 36),
		c + Vector2(0, 64),
		c + Vector2(-12, 36),
	]), Color(0.0, 0.08, 0.18, 0.78))
	draw_circle(c + Vector2(-18, -2), 4.2, Color(1.0, 0.95, 0.48))
	draw_circle(c + Vector2(18, -2), 4.2, Color(1.0, 0.95, 0.48))
	draw_line(c + Vector2(-12, 20), c + Vector2(0, 31), Color(0.85, 0.96, 1.0), 2.0)
	draw_line(c + Vector2(12, 20), c + Vector2(0, 31), Color(0.85, 0.96, 1.0), 2.0)

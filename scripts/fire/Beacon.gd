extends Area2D

var fuel: float = 100.0
var _time: float = 0.0
var _extinguished := false

@onready var light = $PointLight2D
@onready var timer = $Timer

func _ready() -> void:
	timer.wait_time = 30.0
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	add_to_group("beacons")
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	fuel -= Constants.BEACON_DRAIN_RATE * delta
	fuel = clamp(fuel, 0, Constants.BEACON_FUEL_MAX)
	
	light.energy = remap(fuel, 0.0, Constants.BEACON_FUEL_MAX, 0.15, 1.8)
	queue_redraw()
	
	if fuel <= 0:
		_extinguish()

func take_damage(amount: float) -> void:
	fuel -= amount

func _extinguish() -> void:
	if _extinguished:
		return
	_extinguished = true
	SignalBus.beacon_extinguished.emit(global_position)
	queue_free()

func _on_timer_timeout() -> void:
	_extinguish()

func _draw() -> void:
	var level := fuel / Constants.BEACON_FUEL_MAX
	var pulse := 1.0 + sin(_time * 12.0) * 0.12
	var flame_color := Color(1.0, 0.28 + level * 0.25, 0.02)
	var core_color := Color(1.0, 0.82, 0.18)

	draw_circle(Vector2.ZERO, 76.0 * level, Color(1.0, 0.33, 0.02, 0.11))
	draw_circle(Vector2.ZERO, 24.0, Color(0.10, 0.07, 0.04))
	draw_line(Vector2(-18, -8), Vector2(18, 8), Color(0.22, 0.12, 0.05), 6.0)
	draw_line(Vector2(-16, 10), Vector2(16, -9), Color(0.22, 0.12, 0.05), 6.0)
	draw_circle(Vector2.ZERO, 17.0 * pulse * max(0.35, level), flame_color)
	draw_circle(Vector2(0, -2), 8.0 * pulse * max(0.35, level), core_color)
	if level < 0.28:
		draw_line(Vector2(-4, -14), Vector2(-14, -31), Color(0.35, 0.35, 0.34, 0.55), 3.0)
		draw_line(Vector2(7, -13), Vector2(20, -26), Color(0.35, 0.35, 0.34, 0.45), 2.0)

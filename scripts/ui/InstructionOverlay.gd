extends CanvasLayer

const AUTO_HIDE_SECONDS := 7.0

var _dismissed := false
var _timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)
	if OS.get_cmdline_user_args().has("skip_intro"):
		_dismiss(false)
		return
	get_tree().paused = false
	show()

func _process(delta: float) -> void:
	if _dismissed:
		return
	_timer += delta
	if _timer >= AUTO_HIDE_SECONDS:
		_dismiss(false)

func _input(event: InputEvent) -> void:
	if _dismissed:
		return
	if _is_start_event(event):
		_dismiss(true)

func _unhandled_input(event: InputEvent) -> void:
	if _dismissed:
		return
	if _is_start_event(event):
		_dismiss(true)

func _is_start_event(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("place_beacon"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]
	if event is InputEventMouseButton and event.pressed:
		return true
	return false

func _dismiss(mark_handled := true) -> void:
	if _dismissed:
		return
	_dismissed = true
	get_tree().paused = false
	if mark_handled:
		get_viewport().set_input_as_handled()
	hide()

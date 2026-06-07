extends CanvasLayer

@onready var title_label = $Title
@onready var score_label = $ScoreLabel
@onready var beacon_label = $BeaconLabel
@onready var family_label = $FamilyLabel
@onready var highscore_label = $HighscoreLabel
@onready var legacy_label = $LegacyLabel
@onready var trail_map = $TrailMap

func _ready() -> void:
	hide()

func show_result(score: float, active_beacons: int, families_saved: int, highscore: int) -> void:
	title_label.text = "Ko'k Bo'ri so'zi"
	score_label.text = "Final Score: %d" % int(score)
	beacon_label.text = "Active beacons: %d" % active_beacons
	family_label.text = "Families saved: %d" % families_saved
	highscore_label.text = "Highscore: %d" % highscore
	legacy_label.text = "Olov so'ndi, lekin iz yo'qolmadi.\nKo'k Bo'ri seni ko'rdi: %d oila sening olovingda issiqlik topdi.\nOta-bobolar ruhi yo'lingni eslaydi." % families_saved
	var scene = get_tree().current_scene
	if scene and scene.has_method("get_all_positions") and trail_map.has_method("set_trail"):
		trail_map.set_trail(scene.get_all_positions(), PlayerStats.sacrificed)
	show()

func _input(event) -> void:
	if event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()

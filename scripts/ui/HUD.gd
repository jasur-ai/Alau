extends CanvasLayer

@onready var fire_bar = $FireBar
@onready var beacon_label = $BeaconCount
@onready var score_label = $ScoreLabel
@onready var family_label = $FamilyCount
@onready var status_label = $StatusLabel
@onready var warning_label = $WarningLabel
@onready var darkness_overlay = $DarknessOverlay

func _ready() -> void:
	pass

func update_display() -> void:
	var scene = get_tree().current_scene
	var torch_lit: bool = scene.is_torch_lit() if scene and scene.has_method("is_torch_lit") else PlayerStats.torch_fuel > 0.0
	fire_bar.visible = torch_lit
	beacon_label.visible = torch_lit
	score_label.visible = torch_lit
	family_label.visible = torch_lit
	fire_bar.value = PlayerStats.torch_fuel
	var active_beacons = scene.get_active_beacon_count() if scene and scene.has_method("get_active_beacon_count") else 0
	beacon_label.text = "Beacons: %d" % active_beacons
	score_label.text = "Score: %d" % int(PlayerStats.score)
	family_label.text = "Families warmed: %d" % PlayerStats.families_saved
	if scene and scene.has_method("get_status_text"):
		status_label.text = scene.get_status_text()
	if scene and scene.has_method("get_warning_text"):
		warning_label.text = scene.get_warning_text()
	if scene and scene.has_method("get_darkness_alpha"):
		darkness_overlay.color = Color(0.0, 0.0, 0.025, scene.get_darkness_alpha())

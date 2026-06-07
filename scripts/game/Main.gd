extends Node3D

const WORLD_LENGTH := 2600.0
const PLAYER_WALK_SPEED := 5.4
const PLAYER_RUN_SPEED := 9.2
const PLAYER_REVERSE_SPEED := 3.8
const PLAYER_TURN_SPEED := 2.55
const PLAYER_ACCEL := 7.5
const PLAYER_DECEL := 9.0
const ROAD_HALF_WIDTH := 5.2
const TORCH_LIGHT_FUEL := 72.0
const TORCH_DRAIN := 1.35
const TORCH_WOLF_DRAIN := 2.4
const BEACON_DRAIN := 0.42
const WOLF_DRAIN := 3.6
const PLAYER_HEALTH_MAX := 100.0
const FAMILY_FIRE_RADIUS := 17.0
const MAX_WOLVES_PER_AMBUSH := 12

@onready var hud = $HUD
@onready var end_screen = $EndScreen

var camera: Camera3D
var player: Node3D
var player_x := 0.0
var lane_offset := 0.0
var last_x := 0.0
var run_time := 0.0
var game_ended := false

var beacons: Array[Dictionary] = []
var families: Array[Dictionary] = []
var wolves: Array[Dictionary] = []
var trail: Array[Vector2] = []
var pickups: Array[Dictionary] = []
var active_beacon_count := 0
var next_wolf_time := 5.0
var health := PLAYER_HEALTH_MAX
var wood := 4
var flint := 2
var torch_lit := false
var equipped_weapon := 0
var current_move_speed := 0.0
var forward_hold_time := 0.0
var attack_cooldown := 0.0
var weapon_swing_time := 0.0
var wolf_warning := ""
var weapon_names := ["qamchi", "nayza", "qilich", "kamon"]
var weapon_ranges := [2.5, 3.5, 2.9, 8.5]
var weapon_damage := [34.0, 52.0, 110.0, 52.0]
var weapon_unlocked := [true, false, false, false]

var mat_grass: StandardMaterial3D
var mat_road: StandardMaterial3D
var mat_fire: StandardMaterial3D
var mat_fire_core: StandardMaterial3D
var mat_nomad: StandardMaterial3D
var mat_skin: StandardMaterial3D
var mat_wolf: StandardMaterial3D
var mat_blue: StandardMaterial3D
var mat_family: StandardMaterial3D
var mat_wood: StandardMaterial3D
var mat_flint: StandardMaterial3D
var mat_weapon: StandardMaterial3D
var environment: Environment
var sun: DirectionalLight3D
var sky_root: Node3D
var darkness_overlay: ColorRect

func _ready() -> void:
	_ensure_input_actions()
	PlayerStats.reset()
	PlayerStats.torch_fuel = 0.0
	SaveManager.load_data()
	_make_materials()
	_build_world()
	_build_sky_details()
	_build_intro_symbol()
	player = _make_nomad()
	add_child(player)
	player.global_position = _road_position(0.0, 0.0)
	player.rotation.y = atan2(_road_tangent(0.0).x, _road_tangent(0.0).z)
	_setup_camera_and_light()
	_update_torch_visual()
	end_screen.hide()
	if OS.get_cmdline_user_args().has("auto_beacon_test"):
		call_deferred("_place_beacon")

func _process(delta: float) -> void:
	if game_ended:
		return
	run_time += delta
	attack_cooldown = max(0.0, attack_cooldown - delta)
	weapon_swing_time = max(0.0, weapon_swing_time - delta)
	_update_player(delta)
	_update_beacons(delta)
	_update_families(delta)
	_update_wolves(delta)
	_update_pickups()
	_update_spawns(delta)
	_update_night(delta)
	_update_camera(delta)
	_update_score()
	hud.update_display()

func _unhandled_input(event: InputEvent) -> void:
	if game_ended:
		return
	if event.is_action_pressed("place_beacon"):
		_place_beacon()
	if event.is_action_pressed("toggle_fire"):
		_toggle_torch()
	if event.is_action_pressed("sacrifice"):
		_sacrifice()
	if event.is_action_pressed("attack"):
		_attack()
	if event.is_action_pressed("weapon_1"):
		_try_equip_weapon(0)
	if event.is_action_pressed("weapon_2"):
		_try_equip_weapon(1)
	if event.is_action_pressed("weapon_3"):
		_try_equip_weapon(2)
	if event.is_action_pressed("weapon_4"):
		_try_equip_weapon(3)

func _try_equip_weapon(index: int) -> void:
	if index < 0 or index >= weapon_names.size():
		return
	if not weapon_unlocked[index]:
		wolf_warning = "%s hali topilmadi" % weapon_names[index].capitalize()
		return
	equipped_weapon = index

func _ensure_input_actions() -> void:
	for action_name in ["place_beacon", "toggle_fire", "ui_left", "ui_right", "ui_up", "ui_down", "attack"]:
		_reset_action(action_name)
	_add_key_action("place_beacon", [KEY_E])
	_add_key_action("toggle_fire", [KEY_F])
	_add_key_action("sacrifice", [KEY_Q])
	_add_key_action("ui_left", [KEY_A, KEY_LEFT])
	_add_key_action("ui_right", [KEY_D, KEY_RIGHT])
	_add_key_action("ui_up", [KEY_W, KEY_UP])
	_add_key_action("ui_down", [KEY_S, KEY_DOWN])
	_add_key_action("attack", [KEY_C])
	_add_key_action("weapon_1", [KEY_1])
	_add_key_action("weapon_2", [KEY_2])
	_add_key_action("weapon_3", [KEY_3])
	_add_key_action("weapon_4", [KEY_4])

func _reset_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)

func _add_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var exists := false
		for input_event in InputMap.action_get_events(action_name):
			if input_event is InputEventKey and input_event.keycode == keycode:
				exists = true
				break
		if exists:
			continue
		var event := InputEventKey.new()
		event.keycode = keycode
		InputMap.action_add_event(action_name, event)

func _add_mouse_button_action(action_name: StringName, button_index: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventMouseButton and input_event.button_index == button_index:
			return
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action_name, event)

func _make_materials() -> void:
	mat_grass = _mat(Color(0.12, 0.24, 0.13), 0.85)
	mat_road = _mat(Color(0.42, 0.28, 0.12), 0.72)
	mat_fire = _emissive_mat(Color(1.0, 0.28, 0.02), 2.5)
	mat_fire_core = _emissive_mat(Color(1.0, 0.85, 0.18), 3.8)
	mat_nomad = _mat(Color(0.56, 0.24, 0.08), 0.55)
	mat_skin = _mat(Color(0.72, 0.42, 0.2), 0.5)
	mat_wolf = _mat(Color(0.08, 0.085, 0.09), 0.72)
	mat_blue = _emissive_mat(Color(0.08, 0.62, 1.0), 1.7)
	mat_family = _mat(Color(0.22, 0.48, 0.44), 0.56)
	mat_wood = _mat(Color(0.28, 0.13, 0.04), 0.82)
	mat_flint = _mat(Color(0.45, 0.48, 0.48), 0.7)
	mat_weapon = _mat(Color(0.72, 0.65, 0.48), 0.38)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _emissive_mat(color: Color, energy: float) -> StandardMaterial3D:
	var material := _mat(color, 0.35)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _cone_mesh(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	return mesh

func _build_world() -> void:
	var env := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.10, 0.08, 0.10)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.17, 0.18, 0.23)
	environment.ambient_light_energy = 0.22
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.08, 0.08, 0.10)
	environment.fog_density = 0.018
	env.environment = environment
	add_child(env)

	var ground := MeshInstance3D.new()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(WORLD_LENGTH, 420.0)
	ground.mesh = ground_mesh
	ground.material_override = mat_grass
	ground.position = Vector3(WORLD_LENGTH * 0.48, -0.05, 0)
	add_child(ground)

	var x := -60.0
	while x < WORLD_LENGTH:
		_add_road_segment(x)
		x += 3.0
	for i in range(0, 260):
		_add_steppe_detail(float(i) * 10.0 - 80.0)
	for i in range(0, 105):
		_add_pickup_cluster(float(i) * 24.0 + 14.0)
	for i in range(0, 64):
		_spawn_waiting_family(55.0 + float(i) * 40.0)

func _build_sky_details() -> void:
	sky_root = Node3D.new()
	sky_root.name = "NightSky"
	add_child(sky_root)
	var moon := _mesh(SphereMesh.new(), _emissive_mat(Color(0.78, 0.86, 1.0), 1.4), Vector3(22.0, 34.0, -82.0), Vector3(3.2, 3.2, 0.2))
	moon.name = "Moon"
	sky_root.add_child(moon)
	var moon_light := DirectionalLight3D.new()
	moon_light.name = "MoonLight"
	moon_light.light_color = Color(0.55, 0.64, 0.88)
	moon_light.light_energy = 0.32
	moon_light.rotation_degrees = Vector3(-55, 24, 0)
	sky_root.add_child(moon_light)
	for i in range(90):
		var seed: float = abs(sin(float(i) * 17.73) * 1000.0)
		var star := _mesh(SphereMesh.new(), _emissive_mat(Color(0.70, 0.82, 1.0), 0.9), Vector3(fmod(seed * 2.7, 140.0) - 70.0, 22.0 + fmod(seed, 20.0), -95.0 + fmod(seed * 1.9, 32.0)), Vector3.ONE * (0.045 + fmod(seed, 0.08)))
		star.name = "Star"
		sky_root.add_child(star)

func _add_road_segment(x: float) -> void:
	var z := _path_z(x)
	var next := Vector3(x + 5.0, 0.01, _path_z(x + 5.0))
	var current := Vector3(x, 0.01, z)
	var middle := (current + next) * 0.5
	var road := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(current.distance_to(next) + 1.2, 0.08, ROAD_HALF_WIDTH * 2.05)
	road.mesh = mesh
	road.material_override = mat_road
	road.position = middle
	road.rotation.y = -atan2(next.z - current.z, next.x - current.x)
	add_child(road)

func _add_steppe_detail(x: float) -> void:
	var rng := sin(x * 12.989) * 43758.5453
	var side := -1.0 if fmod(abs(rng), 2.0) < 1.0 else 1.0
	var z := _path_z(x) + side * (ROAD_HALF_WIDTH + 7.0 + fmod(abs(rng), 32.0))
	var grass := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.09
	mesh.height = 0.7 + fmod(abs(rng), 0.6)
	grass.mesh = mesh
	grass.material_override = _mat(Color(0.14, 0.26, 0.11), 0.9)
	grass.position = Vector3(x, mesh.height * 0.5, z)
	grass.rotation.z = fmod(abs(rng), 0.5) - 0.25
	add_child(grass)

	if int(abs(rng)) % 7 == 0:
		var rock := MeshInstance3D.new()
		var rock_mesh := SphereMesh.new()
		rock_mesh.radius = 0.42 + fmod(abs(rng), 0.5)
		rock_mesh.height = rock_mesh.radius * 1.1
		rock.mesh = rock_mesh
		rock.material_override = _mat(Color(0.10, 0.11, 0.10), 0.8)
		rock.position = Vector3(x + 1.4, 0.18, z + side * 2.1)
		rock.scale.y = 0.38
		add_child(rock)

	if int(abs(rng)) % 17 == 0:
		_add_yurt(Vector3(x + 3.0, 0, z + side * 8.5), side)

	if int(abs(rng)) % 23 == 0:
		_add_tree(Vector3(x - 1.8, 0, z + side * 4.0), 0.85 + fmod(abs(rng), 0.55))

func _add_yurt(pos: Vector3, side: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = side * 0.4
	add_child(root)
	var base := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.8
	mesh.bottom_radius = 2.0
	mesh.height = 1.25
	base.mesh = mesh
	base.material_override = _mat(Color(0.30, 0.23, 0.15), 0.76)
	base.position.y = 0.65
	root.add_child(base)
	var roof := MeshInstance3D.new()
	var roof_mesh := _cone_mesh(2.05, 1.1)
	roof_mesh.top_radius = 0.16
	roof.mesh = roof_mesh
	roof.material_override = _mat(Color(0.18, 0.08, 0.04), 0.75)
	roof.position.y = 1.82
	root.add_child(roof)

func _add_tree(pos: Vector3, scale_value: float) -> void:
	var root := Node3D.new()
	root.name = "SparseTree"
	root.position = pos
	root.rotation.y = randf_range(-0.4, 0.4)
	root.scale = Vector3.ONE * scale_value
	add_child(root)
	var trunk := _mesh(CylinderMesh.new(), _mat(Color(0.20, 0.10, 0.04), 0.82), Vector3(0, 0.85, 0), Vector3(0.16, 1.65, 0.16))
	root.add_child(trunk)
	var crown_a := _mesh(_cone_mesh(0.95, 1.55), _mat(Color(0.07, 0.22, 0.10), 0.88), Vector3(0, 2.0, 0), Vector3(1.0, 1.0, 1.0))
	root.add_child(crown_a)
	var crown_b := _mesh(_cone_mesh(0.70, 1.20), _mat(Color(0.09, 0.28, 0.12), 0.86), Vector3(0, 2.75, 0), Vector3(1.0, 1.0, 1.0))
	root.add_child(crown_b)

func _add_pickup_cluster(x: float) -> void:
	var seed: float = abs(sin(x * 8.17) * 1000.0)
	var seed_i := int(seed)
	var kind := "wood"
	if seed_i % 17 == 0:
		kind = weapon_names[int(seed_i / 17) % weapon_names.size()]
	elif seed_i % 2 == 0:
		kind = "flint"
	else:
		kind = "wood"
	var side := -1.0 if seed_i % 2 == 0 else 1.0
	var pos := _road_position(x, side * randf_range(0.8, ROAD_HALF_WIDTH - 0.45))
	var node := _make_pickup(kind)
	add_child(node)
	node.global_position = pos + Vector3(0, 0.18, 0)
	pickups.append({"node": node, "kind": kind, "taken": false, "pos": _xz(node.global_position), "amount": _pickup_amount(kind, seed)})

func _pickup_amount(kind: String, seed: float) -> int:
	if kind == "wood":
		return 1 + int(seed) % 2
	if kind == "flint":
		return 1
	return 1

func _make_pickup(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Pickup_%s" % kind
	match kind:
		"wood":
			for i in range(3):
				var stick := _mesh(CylinderMesh.new(), mat_wood, Vector3((i - 1) * 0.18, 0.08, 0), Vector3(0.06, 0.55, 0.06))
				stick.rotation_degrees.z = 82
				stick.rotation_degrees.y = i * 33
				root.add_child(stick)
		"flint":
			var stone := _mesh(SphereMesh.new(), mat_flint, Vector3.ZERO, Vector3(0.34, 0.18, 0.28))
			root.add_child(stone)
		_:
			var shaft := _mesh(CylinderMesh.new(), mat_weapon, Vector3(0, 0.16, 0), Vector3(0.045, 0.95, 0.045))
			shaft.rotation_degrees.z = 90
			root.add_child(shaft)
			var head := _mesh(_cone_mesh(0.5, 1.0), mat_weapon, Vector3(0.56, 0.16, 0), Vector3(0.16, 0.32, 0.16))
			head.rotation_degrees.z = -90
			root.add_child(head)
	return root

func _setup_camera_and_light() -> void:
	sun = DirectionalLight3D.new()
	sun.light_energy = 2.8
	sun.rotation_degrees = Vector3(-48, -28, 0)
	add_child(sun)

	var warm := OmniLight3D.new()
	warm.name = "TorchLight"
	warm.light_color = Color(1.0, 0.48, 0.1)
	warm.light_energy = 1.8
	warm.omni_range = 9.0
	player.add_child(warm)
	warm.position = Vector3(0.7, 2.0, -0.5)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 58.0
	add_child(camera)
	_update_camera(1.0)

func _update_camera(delta: float) -> void:
	var target := player.global_position + Vector3(0, 1.4, 0)
	var desired := target + Vector3(-8.0, 6.4, 8.8)
	camera.global_position = camera.global_position.lerp(desired, min(1.0, delta * 5.0))
	camera.look_at(target + Vector3(4.0, 0.0, 0.0), Vector3.UP)
	if sky_root:
		sky_root.global_position = Vector3(player.global_position.x + 8.0, 0.0, player.global_position.z)

func _update_player(delta: float) -> void:
	var previous_position := player.global_position
	var turn_input := Input.get_axis("ui_left", "ui_right")
	var move_input := Input.get_axis("ui_down", "ui_up")
	var starting_x: float = clamp(player.global_position.x, -60.0, WORLD_LENGTH)
	var starting_lane: float = (player.global_position - _road_position(starting_x, 0.0)).dot(_road_normal(starting_x))
	var starting_offroad: float = max(0.0, abs(starting_lane) - ROAD_HALF_WIDTH)
	var offroad_penalty: float = clamp(1.0 - starting_offroad * 0.09, 0.38, 1.0)
	if abs(turn_input) > 0.01:
		player.rotate_y(-turn_input * PLAYER_TURN_SPEED * delta)
	var player_forward := player.global_transform.basis.z.normalized()
	var target_speed := 0.0
	if move_input > 0.01:
		forward_hold_time += delta
		target_speed = PLAYER_WALK_SPEED if forward_hold_time < 0.55 else PLAYER_RUN_SPEED
	elif move_input < -0.01:
		forward_hold_time = 0.0
		target_speed = -PLAYER_REVERSE_SPEED
	else:
		forward_hold_time = 0.0
	var speed_change := PLAYER_ACCEL if abs(target_speed) > abs(current_move_speed) else PLAYER_DECEL
	current_move_speed = move_toward(current_move_speed, target_speed, speed_change * delta)
	if abs(current_move_speed) > 0.01:
		player.global_position += player_forward * current_move_speed * offroad_penalty * delta
	player_x = clamp(player.global_position.x, -60.0, WORLD_LENGTH)
	var road_center := _road_position(player_x, 0.0)
	lane_offset = (player.global_position - road_center).dot(_road_normal(player_x))
	var offroad_amount: float = max(0.0, abs(lane_offset) - ROAD_HALF_WIDTH)
	var moved_distance := previous_position.distance_to(player.global_position)
	if moved_distance > 0.01:
		_animate_human(player, delta, turn_input)
	else:
		_idle_human(player)
	_update_weapon_visual()
	_update_torch_visual()

	if offroad_amount > 1.0 and run_time > 4.0:
		wolf_warning = "Yo'ldan tashqarida sekinlashasan. Bu yerda bo'rilar ko'p."
		if next_wolf_time > 2.4:
			next_wolf_time = 2.4

	PlayerStats.distance_traveled += moved_distance * 10.0
	last_x = player_x
	if torch_lit and not PlayerStats.sacrificed:
		PlayerStats.torch_fuel -= TORCH_DRAIN * delta * (1.0 + offroad_amount * 0.035)
		if PlayerStats.torch_fuel <= 0.0:
			PlayerStats.torch_fuel = 0.0
			torch_lit = false
			wolf_warning = "Mash'al so'ndi. F bilan yana yoq: yog'och + chaqmoqtosh kerak."

func _toggle_torch() -> void:
	if torch_lit:
		torch_lit = false
		wolf_warning = "Mash'al yopildi. Olov vaqti endi kamaymaydi."
		_update_torch_visual()
		return
	if PlayerStats.torch_fuel <= 1.0:
		if wood <= 0 or flint <= 0:
			wolf_warning = "Mash'al uchun yog'och va chaqmoqtosh kerak."
			return
		wood -= 1
		flint -= 1
		PlayerStats.torch_fuel = TORCH_LIGHT_FUEL
		wolf_warning = "Mash'al yoqildi: bo'rilar yaqinlasha olmaydi."
	else:
		wolf_warning = "Mash'al qayta yoqildi."
	torch_lit = true
	_update_torch_visual()

func _place_beacon() -> void:
	var nearby_beacon = _nearest_active_beacon(_xz(player.global_position), 3.2)
	if nearby_beacon != null:
		if wood <= 0:
			wolf_warning = "O'choqni boqish uchun yog'och kerak"
			return
		wood -= 1
		nearby_beacon.fuel = min(Constants.BEACON_FUEL_MAX, nearby_beacon.fuel + 62.0)
		wolf_warning = "Yog'och tashlandi: o'choq yana kuchaydi"
		return

	if wood <= 0 or flint <= 0:
		wolf_warning = "Yangi o'choq uchun yog'och + chaqmoqtosh kerak"
		return
	wood -= 1
	flint -= 1
	var node := _make_beacon()
	add_child(node)
	node.global_position = player.global_position + Vector3(-1.5, 0, 0)
	var entry := {"node": node, "fuel": Constants.BEACON_FUEL_MAX, "pos": _xz(node.global_position)}
	beacons.append(entry)
	trail.append(entry.pos)
	PlayerStats.beacon_count += 1
	SignalBus.beacon_placed.emit(entry.pos)
	_activate_nearby_families(entry.pos)

func _update_pickups() -> void:
	for pickup in pickups:
		if pickup.taken or not is_instance_valid(pickup.node):
			continue
		pickup.node.rotation.y += 0.035
		if pickup.node.global_position.distance_to(player.global_position) > 1.45:
			continue
		pickup.taken = true
		pickup.node.hide()
		var amount: int = int(pickup.get("amount", 1))
		match String(pickup.kind):
			"wood":
				wood += amount
				wolf_warning = "Yog'och yig'ildi: +%d" % amount
			"flint":
				flint += amount
				wolf_warning = "Chaqmoqtosh topildi: +%d" % amount
			"qamchi":
				equipped_weapon = 0
				wolf_warning = "Qamchi olindi: C bilan bo'rini hayda"
			"nayza":
				weapon_unlocked[1] = true
				equipped_weapon = 1
				wolf_warning = "Nayza olindi: uzoqroq zarba"
			"qilich":
				weapon_unlocked[2] = true
				equipped_weapon = 2
				wolf_warning = "Qilich olindi: kuchli yaqin hujum"
			"kamon":
				weapon_unlocked[3] = true
				equipped_weapon = 3
				wolf_warning = "Kamon olindi: uzoqdan himoya"

func _attack() -> void:
	if attack_cooldown > 0.0:
		return
	attack_cooldown = 0.55
	weapon_swing_time = 0.28
	var range_value: float = weapon_ranges[equipped_weapon]
	var damage_value: float = weapon_damage[equipped_weapon]
	var target_wolf = null
	var best_distance := INF
	for wolf in wolves:
		if not is_instance_valid(wolf.node) or wolf.get("dead", false):
			continue
		var distance: float = wolf.node.global_position.distance_to(player.global_position)
		if distance > range_value or distance >= best_distance:
			continue
		var forward := player.global_transform.basis.z.normalized()
		var to_wolf: Vector3 = (wolf.node.global_position - player.global_position).normalized()
		if equipped_weapon != 3 and forward.dot(to_wolf) < 0.08:
			continue
		best_distance = distance
		target_wolf = wolf
	if target_wolf == null:
		wolf_warning = "%s havoni kesdi" % weapon_names[equipped_weapon].capitalize()
		return
	target_wolf.health -= damage_value
	target_wolf.node.scale *= 0.92
	if target_wolf.health <= 0.0:
		target_wolf.dead = true
		target_wolf.node.hide()
		wolf_warning = "Bo'ri chekindi. Oloving saqlandi."
	else:
		wolf_warning = "%s zarbasi tegdi" % weapon_names[equipped_weapon].capitalize()

func _make_beacon() -> Node3D:
	var root := Node3D.new()
	root.name = "OlovBeacon"
	var stones := 8
	for i in range(stones):
		var stone := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.34, 0.16, 0.22)
		stone.mesh = mesh
		stone.material_override = _mat(Color(0.08, 0.07, 0.06), 0.8)
		var a := TAU * float(i) / float(stones)
		stone.position = Vector3(cos(a) * 0.78, 0.1, sin(a) * 0.78)
		stone.rotation.y = a
		root.add_child(stone)
	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.42
	flame_mesh.height = 0.95
	flame.mesh = flame_mesh
	flame.material_override = mat_fire
	flame.position = Vector3(0, 0.62, 0)
	root.add_child(flame)
	var core := MeshInstance3D.new()
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.22
	core_mesh.height = 0.5
	core.mesh = core_mesh
	core.material_override = mat_fire_core
	core.position = Vector3(0, 0.72, 0)
	root.add_child(core)
	var light := OmniLight3D.new()
	light.name = "BeaconLight"
	light.light_color = Color(1.0, 0.45, 0.08)
	light.light_energy = 4.2
	light.omni_range = 14.0
	root.add_child(light)
	light.position = Vector3(0, 1.0, 0)
	return root

func _update_beacons(delta: float) -> void:
	active_beacon_count = 0
	for beacon in beacons:
		if not is_instance_valid(beacon.node):
			continue
		beacon.fuel = max(0.0, beacon.fuel - BEACON_DRAIN * delta)
		var level: float = beacon.fuel / Constants.BEACON_FUEL_MAX
		beacon.node.scale = Vector3.ONE * (0.65 + level * 0.45)
		var light: Node = beacon.node.get_node_or_null("BeaconLight")
		if light:
			light.light_energy = 0.2 + level * 4.6
			light.omni_range = 5.0 + level * 12.0
		if beacon.fuel > 0.0:
			active_beacon_count += 1
		else:
			beacon.node.hide()

func _spawn_waiting_family(x: float) -> void:
	var seed_i := int(abs(sin(x * 3.93) * 1000.0))
	var side := -1.0 if seed_i % 2 == 0 else 1.0
	var center := _road_position(x, side * randf_range(ROAD_HALF_WIDTH + 4.0, ROAD_HALF_WIDTH + 8.5))
	var root := Node3D.new()
	root.name = "WaitingFamily"
	add_child(root)
	root.global_position = center
	var mother := _make_human(0.72, mat_family)
	mother.position = Vector3(0, 0, 0)
	root.add_child(mother)
	var child_a := _make_human(0.48, mat_family)
	child_a.position = Vector3(-0.9, 0, 0.55)
	root.add_child(child_a)
	var child_b := _make_human(0.48, mat_family)
	child_b.position = Vector3(0.85, 0, 0.45)
	root.add_child(child_b)
	var small_fire := _mesh(CylinderMesh.new(), mat_wood, Vector3(0.0, 0.12, -0.85), Vector3(0.16, 0.22, 0.16))
	small_fire.name = "ColdHearth"
	root.add_child(small_fire)
	families.append({
		"node": root,
		"members": [mother, child_a, child_b],
		"target": Vector2.ZERO,
		"has_fire": false,
		"safe": false,
		"time": randf() * 10.0
	})

func _activate_nearby_families(beacon_pos: Vector2) -> void:
	var activated := 0
	for family in families:
		if family.safe or family.has_fire or not is_instance_valid(family.node):
			continue
		if _xz(family.node.global_position).distance_to(beacon_pos) > FAMILY_FIRE_RADIUS:
			continue
		family.target = beacon_pos
		family.has_fire = true
		activated += 1
	if activated == 0:
		wolf_warning = "O'choq yoqildi, lekin oila uzoqroqda. Xaritadagi yashil belgilarga yaqinlash."
	else:
		wolf_warning = "%d oila olovni ko'rdi va yo'lga chiqdi." % activated

func _update_families(delta: float) -> void:
	for family in families:
		if not is_instance_valid(family.node) or family.safe:
			continue
		family.time += delta
		var members: Array = family.get("members", [])
		if not family.has_fire:
			var nearest = _nearest_active_beacon(_xz(family.node.global_position), FAMILY_FIRE_RADIUS)
			if nearest != null:
				family.target = nearest.pos
				family.has_fire = true
			for member in members:
				if is_instance_valid(member):
					_animate_human(member, delta, sin(family.time) * 0.15)
			continue
		var target := Vector3(family.target.x, 0, family.target.y)
		var direction: Vector3 = target - family.node.global_position
		if direction.length() < 0.8:
			family.safe = true
			PlayerStats.families_saved += 1
			family.node.scale *= 1.08
			continue
		family.node.global_position += direction.normalized() * delta * 1.75
		family.node.look_at(target, Vector3.UP)
		for member in members:
			if is_instance_valid(member):
				_animate_human(member, delta, 0.0)

func _update_spawns(delta: float) -> void:
	next_wolf_time -= delta
	if next_wolf_time <= 0.0:
		var offroad_amount: float = max(0.0, abs(lane_offset) - ROAD_HALF_WIDTH)
		var pack_size := randi_range(1, 3)
		if offroad_amount > 2.0:
			pack_size = randi_range(2, 5)
		pack_size = min(pack_size, MAX_WOLVES_PER_AMBUSH)
		for i in range(pack_size):
			_spawn_wolf()
		next_wolf_time = max(4.0, Constants.WOLF_SPAWN_INTERVAL_START + 4.0 - run_time * 0.035 - offroad_amount * 0.10)

func _spawn_wolf() -> void:
	var wolf := _make_wolf()
	var x := player.global_position.x + randf_range(20.0, 36.0)
	var side := -1.0 if randf() < 0.5 else 1.0
	add_child(wolf)
	wolf.global_position = Vector3(x, 0, _path_z(x) + side * randf_range(9.0, 17.0))
	wolves.append({"node": wolf, "target": -1, "state": "hunt", "time": 0.0, "health": 100.0, "dead": false, "bite": 0.0})

func _update_wolves(delta: float) -> void:
	for wolf in wolves:
		if not is_instance_valid(wolf.node):
			continue
		if wolf.get("dead", false):
			continue
		wolf.time += delta
		wolf.bite = max(0.0, wolf.bite - delta)
		var player_distance: float = wolf.node.global_position.distance_to(player.global_position)
		var close_fire = _nearest_active_beacon(_xz(wolf.node.global_position), 8.5)
		if close_fire != null:
			var fire_pos := Vector3(close_fire.pos.x, 0.0, close_fire.pos.y)
			var away_from_fire: Vector3 = (wolf.node.global_position - fire_pos).normalized()
			wolf.node.global_position += away_from_fire * delta * 5.3
			wolf.node.look_at(fire_pos, Vector3.UP)
			continue
		if torch_lit:
			if player_distance > 7.2:
				_move_node_towards(wolf.node, player.global_position, delta * 3.2)
			elif player_distance < 4.7:
				var away: Vector3 = (wolf.node.global_position - player.global_position).normalized()
				wolf.node.global_position += away * delta * 4.0
				wolf.node.look_at(player.global_position, Vector3.UP)
			else:
				wolf.node.look_at(player.global_position, Vector3.UP)
				wolf.node.scale = Vector3.ONE * (1.0 + sin(wolf.time * 10.0) * 0.025)
			if player_distance < 8.0:
				PlayerStats.torch_fuel = max(0.0, PlayerStats.torch_fuel - TORCH_WOLF_DRAIN * delta)
				wolf_warning = "Bo'rilar olovdan cho'chiyapti, lekin mash'al tezroq so'nadi."
				if PlayerStats.torch_fuel <= 0.0:
					torch_lit = false
					wolf_warning = "Mash'al bo'rilar bosimida so'ndi!"
			continue
		if player_distance > 1.5:
			_move_node_towards(wolf.node, player.global_position, delta * 3.9)
		elif wolf.bite <= 0.0:
			wolf.bite = 1.1
			health = max(0.0, health - 8.0)
			wolf_warning = "Bo'ri tashlandi! F bilan olov yoq yoki C bilan ur."
			if health <= 0.0:
				_game_over(false)

func _nearest_active_beacon(pos: Vector2, max_distance: float = INF):
	var nearest = null
	var nearest_distance := INF
	for beacon in beacons:
		if beacon.fuel <= 0.0:
			continue
		var distance: float = pos.distance_to(beacon.pos)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = beacon
	if nearest_distance > max_distance:
		return null
	return nearest

func _move_node_towards(node: Node3D, target: Vector3, amount: float) -> void:
	var direction := target - node.global_position
	if direction.length() <= 0.01:
		return
	node.global_position += direction.normalized() * amount
	node.look_at(target, Vector3.UP)

func _update_score() -> void:
	var total_score := PlayerStats.distance_traveled * Constants.SCORE_PER_METER
	total_score += PlayerStats.beacon_count * Constants.SCORE_PER_BEACON
	total_score += PlayerStats.families_saved * Constants.SCORE_PER_FAMILY
	if PlayerStats.sacrificed:
		total_score = total_score * Constants.SACRIFICE_MULTIPLIER + Constants.SACRIFICE_BONUS
	PlayerStats.score = total_score

func _sacrifice() -> void:
	if PlayerStats.sacrificed:
		return
	PlayerStats.sacrificed = true
	PlayerStats.torch_fuel = 0.0
	for beacon in beacons:
		beacon.fuel = Constants.BEACON_FUEL_MAX
	_game_over(true)

func _game_over(sacrificed: bool) -> void:
	if game_ended:
		return
	game_ended = true
	SaveManager.highscore = max(SaveManager.highscore, int(PlayerStats.score))
	SaveManager.save()
	get_tree().paused = true
	if end_screen.has_method("show_result"):
		end_screen.show_result(PlayerStats.score, active_beacon_count, PlayerStats.families_saved, SaveManager.highscore)

func get_player_map_position() -> Vector2:
	return Vector2(player_x, _xz(player.global_position).y)

func get_beacon_trail() -> Array:
	return trail.duplicate()

func get_family_map_positions() -> Array:
	var result: Array[Vector2] = []
	for family in families:
		if is_instance_valid(family.node):
			result.append(_xz(family.node.global_position))
	return result

func get_wolf_map_positions() -> Array:
	var result: Array[Vector2] = []
	for wolf in wolves:
		if is_instance_valid(wolf.node) and not wolf.get("dead", false):
			result.append(_xz(wolf.node.global_position))
	return result

func get_pickup_map_positions() -> Array:
	var result: Array[Vector2] = []
	for pickup in pickups:
		if not pickup.taken and is_instance_valid(pickup.node):
			result.append(_xz(pickup.node.global_position))
	return result

func get_status_text() -> String:
	if not torch_lit:
		return "Health %d | Wood %d | Flint %d | Weapon %s | F: torch | C: hujum" % [int(health), wood, flint, weapon_names[equipped_weapon].capitalize()]
	return "Health %d | Fire %d | Wood %d | Flint %d | Weapon %s" % [int(health), int(PlayerStats.torch_fuel), wood, flint, weapon_names[equipped_weapon].capitalize()]

func get_warning_text() -> String:
	return wolf_warning

func get_active_beacon_count() -> int:
	return active_beacon_count

func is_torch_lit() -> bool:
	return torch_lit

func get_all_positions() -> Array:
	return trail.duplicate()

func _path_z(x: float) -> float:
	return sin(x * 0.055) * 7.2 + sin(x * 0.017 + 1.2) * 12.0

func _update_night(_delta: float) -> void:
	if not environment:
		return
	environment.background_color = Color(0.022, 0.035, 0.085)
	environment.ambient_light_color = Color(0.15, 0.18, 0.30)
	environment.ambient_light_energy = 0.20
	environment.fog_light_color = Color(0.04, 0.05, 0.10)
	environment.fog_density = 0.026
	if sun:
		sun.light_energy = 0.26
	var torch: OmniLight3D = player.get_node_or_null("TorchLight")
	if torch:
		var fuel_factor: float = clamp(PlayerStats.torch_fuel / Constants.TORCH_FUEL_MAX, 0.0, 1.0) if torch_lit else 0.0
		torch.light_energy = 6.5 * fuel_factor
		torch.omni_range = 16.0

func get_darkness_alpha() -> float:
	return 0.22

func _road_tangent(x: float) -> Vector3:
	return Vector3(3.0, 0, _path_z(x + 3.0) - _path_z(x)).normalized()

func _road_normal(x: float) -> Vector3:
	var tangent := _road_tangent(x)
	return Vector3(-tangent.z, 0, tangent.x).normalized()

func _road_position(x: float, offset: float) -> Vector3:
	return Vector3(x, 0.0, _path_z(x)) + _road_normal(x) * offset

func _xz(pos: Vector3) -> Vector2:
	return Vector2(pos.x, pos.z)

func _make_nomad() -> Node3D:
	var rig := _make_human(1.0, mat_nomad)
	rig.name = "Nomad"
	var torch := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.06
	mesh.height = 1.2
	torch.mesh = mesh
	torch.material_override = _mat(Color(0.14, 0.07, 0.03), 0.75)
	torch.position = Vector3(0.62, 1.55, -0.25)
	torch.rotation_degrees.z = 18
	rig.add_child(torch)
	var flame := MeshInstance3D.new()
	flame.name = "TorchFlame"
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.24
	flame_mesh.height = 0.58
	flame.mesh = flame_mesh
	flame.material_override = mat_fire
	flame.position = Vector3(0.78, 2.14, -0.36)
	rig.add_child(flame)
	var weapons := Node3D.new()
	weapons.name = "Weapons"
	rig.add_child(weapons)
	_add_weapon_visuals(weapons)
	return rig

func _update_torch_visual() -> void:
	if not player:
		return
	var flame: Node3D = player.get_node_or_null("TorchFlame")
	if flame:
		flame.visible = torch_lit
		var level: float = clamp(PlayerStats.torch_fuel / Constants.TORCH_FUEL_MAX, 0.0, 1.0)
		flame.scale = Vector3.ONE * (0.55 + level * 0.55)
	var torch: OmniLight3D = player.get_node_or_null("TorchLight")
	if torch and not torch_lit:
		torch.light_energy = 0.0

func _add_weapon_visuals(root: Node3D) -> void:
	var whip := _mesh(CylinderMesh.new(), mat_weapon, Vector3(-0.62, 1.25, -0.2), Vector3(0.035, 0.8, 0.035))
	whip.name = "qamchi"
	whip.rotation_degrees.z = -42
	root.add_child(whip)

	var spear := _mesh(CylinderMesh.new(), mat_weapon, Vector3(-0.7, 1.32, -0.1), Vector3(0.04, 1.35, 0.04))
	spear.name = "nayza"
	spear.rotation_degrees.z = -25
	root.add_child(spear)
	var spear_tip := _mesh(_cone_mesh(0.5, 1.0), mat_weapon, Vector3(-1.15, 2.4, -0.1), Vector3(0.16, 0.34, 0.16))
	spear_tip.name = "nayza_tip"
	spear_tip.rotation_degrees.z = 155
	root.add_child(spear_tip)

	var sword := _mesh(BoxMesh.new(), mat_weapon, Vector3(-0.63, 1.36, -0.12), Vector3(0.08, 0.85, 0.035))
	sword.name = "qilich"
	sword.rotation_degrees.z = -28
	root.add_child(sword)

	var bow := _mesh(TorusMesh.new(), mat_weapon, Vector3(-0.68, 1.35, -0.15), Vector3(0.4, 0.72, 0.12))
	bow.name = "kamon"
	bow.rotation_degrees.z = 15
	root.add_child(bow)

func _update_weapon_visual() -> void:
	var root := player.get_node_or_null("Weapons")
	if not root:
		return
	var swing: float = clamp(weapon_swing_time / 0.28, 0.0, 1.0)
	var swing_curve: float = sin(swing * PI)
	for child in root.get_children():
		var visible: bool = child.name == weapon_names[equipped_weapon] or (weapon_names[equipped_weapon] == "nayza" and child.name == "nayza_tip")
		child.visible = visible
		if not visible:
			continue
		match String(child.name):
			"qamchi":
				child.rotation_degrees = Vector3(-32.0 * swing_curve, 0.0, -42.0 - 78.0 * swing_curve)
			"nayza":
				child.rotation_degrees = Vector3(-22.0 * swing_curve, 0.0, -25.0 - 34.0 * swing_curve)
			"nayza_tip":
				child.rotation_degrees = Vector3(-22.0 * swing_curve, 0.0, 155.0 - 34.0 * swing_curve)
			"qilich":
				child.rotation_degrees = Vector3(-38.0 * swing_curve, 0.0, -28.0 - 86.0 * swing_curve)
			"kamon":
				child.rotation_degrees = Vector3(0.0, 18.0 * swing_curve, 15.0 + 24.0 * swing_curve)

func _make_human(scale_value: float, cloth: Material) -> Node3D:
	var rig := Node3D.new()
	rig.scale = Vector3.ONE * scale_value
	var pelvis := _mesh(CapsuleMesh.new(), _mat(Color(0.18, 0.08, 0.03), 0.68), Vector3(0, 0.68, 0), Vector3(0.38, 0.22, 0.34))
	pelvis.name = "Pelvis"
	pelvis.rotation_degrees.z = 90
	rig.add_child(pelvis)
	var body := _mesh(CapsuleMesh.new(), cloth, Vector3(0, 1.05, 0), Vector3(0.42, 0.62, 0.42))
	body.name = "Body"
	rig.add_child(body)
	var coat := _mesh(CylinderMesh.new(), cloth, Vector3(0, 1.0, -0.03), Vector3(0.48, 0.46, 0.48))
	coat.name = "Coat"
	rig.add_child(coat)
	var belt := _mesh(CylinderMesh.new(), _mat(Color(0.08, 0.035, 0.015), 0.7), Vector3(0, 0.92, 0), Vector3(0.49, 0.045, 0.49))
	belt.name = "Belt"
	rig.add_child(belt)
	var shoulders := _mesh(CapsuleMesh.new(), cloth, Vector3(0, 1.45, 0), Vector3(0.28, 0.16, 0.62))
	shoulders.name = "Shoulders"
	shoulders.rotation_degrees.z = 90
	rig.add_child(shoulders)
	var neck := _mesh(CylinderMesh.new(), mat_skin, Vector3(0, 1.66, 0), Vector3(0.16, 0.18, 0.16))
	neck.name = "Neck"
	rig.add_child(neck)
	var head := _mesh(SphereMesh.new(), mat_skin, Vector3(0, 1.9, 0), Vector3(0.34, 0.34, 0.34))
	head.name = "Head"
	rig.add_child(head)
	var hat := _mesh(CylinderMesh.new(), _mat(Color(0.18, 0.08, 0.03), 0.6), Vector3(0, 2.18, 0), Vector3(0.54, 0.16, 0.54))
	hat.name = "Hat"
	rig.add_child(hat)
	for side in [-1.0, 1.0]:
		var sleeve := _mesh(CapsuleMesh.new(), cloth, Vector3(side * 0.43, 1.28, 0), Vector3(0.18, 0.28, 0.18))
		sleeve.rotation_degrees.z = side * 10
		rig.add_child(sleeve)
		var arm := _mesh(CapsuleMesh.new(), mat_skin, Vector3(side * 0.58, 1.06, 0), Vector3(0.15, 0.36, 0.15))
		arm.name = "ArmL" if side < 0 else "ArmR"
		rig.add_child(arm)
		var hand := _mesh(SphereMesh.new(), mat_skin, Vector3(side * 0.62, 0.66, 0), Vector3(0.12, 0.12, 0.12))
		hand.name = "HandL" if side < 0 else "HandR"
		rig.add_child(hand)
		var leg := _mesh(CapsuleMesh.new(), _mat(Color(0.16, 0.08, 0.03), 0.65), Vector3(side * 0.18, 0.38, 0), Vector3(0.16, 0.40, 0.16))
		leg.name = "LegL" if side < 0 else "LegR"
		rig.add_child(leg)
		var foot := _mesh(BoxMesh.new(), _mat(Color(0.07, 0.035, 0.018), 0.7), Vector3(side * 0.18, 0.08, -0.12), Vector3(0.18, 0.08, 0.31))
		foot.name = "FootL" if side < 0 else "FootR"
		rig.add_child(foot)
	return rig

func _animate_human(rig: Node3D, _delta: float, lean: float) -> void:
	var step := sin(run_time * 10.0)
	var arm_l: Node3D = rig.get_node_or_null("ArmL")
	var arm_r: Node3D = rig.get_node_or_null("ArmR")
	var leg_l: Node3D = rig.get_node_or_null("LegL")
	var leg_r: Node3D = rig.get_node_or_null("LegR")
	var foot_l: Node3D = rig.get_node_or_null("FootL")
	var foot_r: Node3D = rig.get_node_or_null("FootR")
	var body: Node3D = rig.get_node_or_null("Body")
	var head: Node3D = rig.get_node_or_null("Head")
	if arm_l:
		arm_l.rotation.x = step * 0.55
	if arm_r:
		arm_r.rotation.x = -step * 0.55
	if leg_l:
		leg_l.rotation.x = -step * 0.42
	if leg_r:
		leg_r.rotation.x = step * 0.42
	if foot_l:
		foot_l.rotation.x = step * 0.16
	if foot_r:
		foot_r.rotation.x = -step * 0.16
	if body:
		body.position.y = 1.05 + abs(step) * 0.025
	if head:
		head.position.y = 1.9 + abs(step) * 0.018
	rig.rotation.z = lerp(rig.rotation.z, -lean * 0.045, 0.18)

func _idle_human(rig: Node3D) -> void:
	for name in ["ArmL", "ArmR", "LegL", "LegR", "FootL", "FootR"]:
		var limb: Node3D = rig.get_node_or_null(name)
		if limb:
			limb.rotation.x = lerp(limb.rotation.x, 0.0, 0.18)
	var body: Node3D = rig.get_node_or_null("Body")
	if body:
		body.position.y = lerp(body.position.y, 1.05, 0.18)
	var head: Node3D = rig.get_node_or_null("Head")
	if head:
		head.position.y = lerp(head.position.y, 1.9, 0.18)
	rig.rotation.z = lerp(rig.rotation.z, 0.0, 0.18)

func _make_wolf() -> Node3D:
	var rig := Node3D.new()
	rig.name = "Wolf"
	var body := _mesh(CapsuleMesh.new(), mat_wolf, Vector3(0, 0.55, 0), Vector3(0.46, 0.34, 1.05))
	body.rotation_degrees.x = 90
	rig.add_child(body)
	var mane := _mesh(CapsuleMesh.new(), _mat(Color(0.02, 0.025, 0.03), 0.82), Vector3(0, 0.92, -0.25), Vector3(0.32, 0.25, 0.7))
	mane.rotation_degrees.x = 90
	rig.add_child(mane)
	var chest := _mesh(SphereMesh.new(), _mat(Color(0.14, 0.15, 0.16), 0.7), Vector3(0, 0.62, -0.58), Vector3(0.44, 0.36, 0.38))
	rig.add_child(chest)
	var head := _mesh(SphereMesh.new(), mat_wolf, Vector3(0, 0.78, -1.03), Vector3(0.32, 0.28, 0.38))
	rig.add_child(head)
	var snout := _mesh(CapsuleMesh.new(), mat_wolf, Vector3(0, 0.72, -1.36), Vector3(0.17, 0.17, 0.38))
	snout.rotation_degrees.x = 90
	rig.add_child(snout)
	for side in [-1.0, 1.0]:
		var eye := _mesh(SphereMesh.new(), mat_blue, Vector3(side * 0.13, 0.86, -1.36), Vector3(0.035, 0.035, 0.035))
		rig.add_child(eye)
	for side in [-1.0, 1.0]:
		var ear := _mesh(CylinderMesh.new(), mat_wolf, Vector3(side * 0.24, 1.06, -1.02), Vector3(0.1, 0.34, 0.1))
		ear.rotation_degrees.z = side * 24
		rig.add_child(ear)
		for z in [-0.42, 0.38]:
			var leg := _mesh(CapsuleMesh.new(), mat_wolf, Vector3(side * 0.32, 0.24, z), Vector3(0.11, 0.34, 0.11))
			rig.add_child(leg)
			var paw := _mesh(SphereMesh.new(), mat_wolf, Vector3(side * 0.32, 0.04, z - 0.08), Vector3(0.16, 0.07, 0.23))
			rig.add_child(paw)
	var tail := _mesh(CapsuleMesh.new(), mat_wolf, Vector3(0, 0.67, 0.9), Vector3(0.14, 0.14, 0.56))
	tail.rotation_degrees.x = 72
	rig.add_child(tail)
	return rig

func _build_intro_symbol() -> void:
	var symbol := Node3D.new()
	symbol.name = "KokBoriSiymosi"
	symbol.position = Vector3(14, 3.0, -18)
	symbol.rotation_degrees = Vector3(0, -24, 0)
	add_child(symbol)
	var body := _mesh(CapsuleMesh.new(), mat_blue, Vector3(0, 0.8, 0), Vector3(1.0, 0.7, 1.9))
	body.rotation_degrees.x = 90
	symbol.add_child(body)
	var head := _mesh(SphereMesh.new(), mat_blue, Vector3(0, 1.08, -1.85), Vector3(0.75, 0.55, 0.85))
	symbol.add_child(head)
	var snout := _mesh(CapsuleMesh.new(), mat_blue, Vector3(0, 1.02, -2.55), Vector3(0.34, 0.34, 0.82))
	snout.rotation_degrees.x = 90
	symbol.add_child(snout)
	for side in [-1.0, 1.0]:
		var ear := _mesh(CylinderMesh.new(), mat_blue, Vector3(side * 0.55, 1.82, -1.7), Vector3(0.18, 0.82, 0.18))
		ear.rotation_degrees.z = side * 25
		symbol.add_child(ear)
	var halo := OmniLight3D.new()
	halo.light_color = Color(0.1, 0.58, 1)
	halo.light_energy = 5.0
	halo.omni_range = 18.0
	symbol.add_child(halo)

func _mesh(mesh: Mesh, material: Material, position: Vector3, scale_value: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position
	instance.scale = scale_value
	return instance

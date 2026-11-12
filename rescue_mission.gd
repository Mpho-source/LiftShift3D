
extends Node3D

const FLOOR_HEIGHT: float = 4.5
const MISSION_TIME: float = 85.0

var player: CharacterBody3D
var vip: Node3D
var safe_zone: Node3D

var objective_label: Label
var time_label: Label
var score_label: Label
var hint_label: Label

var mission_state: String = "waiting"
var pickup_floor: int = 1
var destination_floor: int = 2

var pickup_position: Vector3
var destination_position: Vector3

var time_left: float = MISSION_TIME
var next_mission_timer: float = 0.0

var score: int = 0
var rescued: int = 0
var combo: int = 0
var animation_time: float = 0.0

func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as CharacterBody3D

	if player == null:
		push_error("RescueMission needs a Player node under World.")
		set_process(false)
		set_process_unhandled_input(false)
		return

	create_vip()
	create_safe_zone()
	create_hud()
	start_mission()

func make_material(
	color: Color,
	glowing: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.5

	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0

	return material

func add_mesh(
	parent: Node3D,
	mesh: Mesh,
	pos: Vector3,
	material: StandardMaterial3D,
	tilt: float = 0.0
) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = pos
	visual.rotation.z = deg_to_rad(tilt)
	visual.material_override = material
	parent.add_child(visual)

func add_box(
	parent: Node3D,
	size: Vector3,
	pos: Vector3,
	material: StandardMaterial3D,
	tilt: float = 0.0
) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	add_mesh(parent, mesh, pos, material, tilt)

func create_vip() -> void:
	vip = Node3D.new()
	vip.name = "RescueVIP"
	add_child(vip)

	var suit := make_material(Color("#38BDF8"))
	var skin := make_material(Color("#FACC15"))
	var boots := make_material(Color("#172131"))
	var glow := make_material(Color("#FB7185"), true)

	var head := SphereMesh.new()
	head.radius = 0.19
	head.height = 0.38
	add_mesh(vip, head, Vector3(0, 1.72, 0), skin)

	add_box(
		vip,
		Vector3(0.3, 0.68, 0.2),
		Vector3(0, 1.12, 0),
		suit
	)

	add_box(
		vip,
		Vector3(0.12, 0.66, 0.13),
		Vector3(-0.13, 0.43, 0),
		boots,
		-12
	)

	add_box(
		vip,
		Vector3(0.12, 0.66, 0.13),
		Vector3(0.13, 0.43, 0),
		boots,
		12
	)

	add_box(
		vip,
		Vector3(0.11, 0.63, 0.12),
		Vector3(-0.26, 1.12, 0),
		skin,
		-30
	)

	add_box(
		vip,
		Vector3(0.11, 0.63, 0.12),
		Vector3(0.26, 1.12, 0),
		skin,
		30
	)

	var beacon := SphereMesh.new()
	beacon.radius = 0.12
	beacon.height = 0.24
	add_mesh(
		vip,
		beacon,
		Vector3(0, 2.35, 0),
		glow
	)

	var label := Label3D.new()
	label.text = "HELP ME!"
	label.font_size = 52
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#FB7185")
	label.position = Vector3(0, 2.7, 0)
	vip.add_child(label)

func create_safe_zone() -> void:
	safe_zone = Node3D.new()
	safe_zone.name = "SafeZone"
	add_child(safe_zone)

	var green := make_material(Color("#4ADE80"), true)

	var disk := CylinderMesh.new()
	disk.top_radius = 1.0
	disk.bottom_radius = 1.0
	disk.height = 0.05

	add_mesh(
		safe_zone,
		disk,
		Vector3(0, 0.04, 0),
		green
	)

	var beacon := SphereMesh.new()
	beacon.radius = 0.18
	beacon.height = 0.36

	add_mesh(
		safe_zone,
		beacon,
		Vector3(0, 1.65, 0),
		green
	)

	var label := Label3D.new()
	label.text = "SAFE ZONE"
	label.font_size = 48
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#4ADE80")
	label.position = Vector3(0, 2.3, 0)
	safe_zone.add_child(label)

	safe_zone.hide()

func create_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "MissionHUD"
	canvas.layer = 3
	add_child(canvas)

	var panel := ColorRect.new()
	panel.position = Vector2(20, 20)
	panel.size = Vector2(390, 152)
	panel.color = Color(0.035, 0.06, 0.11, 0.88)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(panel)

	objective_label = create_label(
		panel,
		Vector2(16, 12),
		19,
		Color("#F1F5F9")
	)

	time_label = create_label(
		panel,
		Vector2(16, 54),
		20,
		Color("#FB7185")
	)

	score_label = create_label(
		panel,
		Vector2(16, 91),
		17,
		Color("#FACC15")
	)

	hint_label = create_label(
		canvas,
		Vector2(22, 182),
		18,
		Color("#4ADE80")
	)

func create_label(
	parent: Node,
	pos: Vector2,
	font_size: int,
	color: Color
) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override(
		"font_size",
		font_size
	)
	label.add_theme_color_override(
		"font_color",
		color
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func start_mission() -> void:
	pickup_floor = clampi(
		roundi(player.global_position.y / FLOOR_HEIGHT) + 1,
		1,
		2
	)

	destination_floor = 3 - pickup_floor

	pickup_position = Vector3(
		3.0,
		float(pickup_floor - 1) * FLOOR_HEIGHT,
		-1.5
	)

	destination_position = Vector3(
		-3.0,
		float(destination_floor - 1) * FLOOR_HEIGHT,
		-1.5
	)

	vip.position = pickup_position
	safe_zone.position = destination_position

	vip.show()
	safe_zone.hide()

	mission_state = "waiting"
	time_left = MISSION_TIME

	objective_label.text = (
        "EMERGENCY: VIP ON FLOOR "
		+ str(pickup_floor)
	)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode != KEY_F:
		return

	if mission_state != "waiting":
		return

	var rescue_point := (
		pickup_position + Vector3(0, 0.9, 0)
	)

	if player.global_position.distance_to(rescue_point) <= 2.5:
		mission_state = "following"
		safe_zone.show()

		objective_label.text = (
            "ESCORT VIP TO FLOOR "
			+ str(destination_floor)
		)

func _process(delta: float) -> void:
	animation_time += delta

	if mission_state == "waiting" or mission_state == "following":
		time_left -= delta

		if time_left <= 0.0:
			fail_mission()
			return

		if mission_state == "waiting":
			vip.position = (
				pickup_position
				+ Vector3(
					0,
					sin(animation_time * 3.0) * 0.05,
					0
				)
			)

			var rescue_point := (
				pickup_position + Vector3(0, 0.9, 0)
			)

			if player.global_position.distance_to(rescue_point) < 2.5:
				hint_label.text = "PRESS F TO RESCUE VIP"
			else:
				hint_label.text = "FIND THE VIP"

		elif mission_state == "following":
			var offset := (
				player.global_transform.basis
				* Vector3(0.65, -0.9, 0.65)
			)

			vip.global_position = vip.global_position.lerp(
				player.global_position + offset,
				minf(1.0, delta * 6.0)
			)

			hint_label.text = "REACH THE GREEN SAFE ZONE"

			var goal := (
				destination_position + Vector3(0, 0.9, 0)
			)

			if player.global_position.distance_to(goal) < 2.0:
				complete_mission()

	elif mission_state == "complete" or mission_state == "failed":
		next_mission_timer -= delta

		if next_mission_timer <= 0.0:
			start_mission()

	time_label.text = (
        "TIME LEFT: "
		+ str(int(ceil(maxf(time_left, 0.0))))
		+ "s"
	)

	score_label.text = (
        "SCORE: "
		+ str(score)
		+ "   RESCUED: "
		+ str(rescued)
		+ "   COMBO: "
		+ str(combo)
	)

func complete_mission() -> void:
	mission_state = "complete"
	combo += 1
	rescued += 1

	var points := (
		100
		+ int(ceil(time_left))
		+ (combo - 1) * 50
	)

	score += points

	objective_label.text = (
        "RESCUE COMPLETE! +"
		+ str(points)
		+ " POINTS"
	)

	hint_label.text = "SHIT GOT REAL!!!"

	vip.hide()
	safe_zone.hide()
	next_mission_timer = 3.0

func fail_mission() -> void:
	mission_state = "failed"
	combo = 0
	time_left = 0.0

	objective_label.text = "MISSION FAILED!"
	hint_label.text = "NEW EMERGENCY INCOMING"

	vip.hide()
	safe_zone.hide()
	next_mission_timer = 3.0

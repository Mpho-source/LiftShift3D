
extends AnimatableBody3D

const FLOOR_HEIGHT: float = 4.5
const TRAVEL_SPEED: float = 1.5
const DOOR_SPEED: float = 2.0

var current_floor: int = 1
var target_floor: int = 1
var state: String = "idle"
var doors_open: bool = false

var left_door: AnimatableBody3D
var right_door: AnimatableBody3D
var left_x: float = -0.725
var right_x: float = 0.725

var player: CharacterBody3D
var look_ray: RayCast3D
var hint_label: Label
var floor_display: Label3D
var status_display: Label3D

var materials: Dictionary = {}

func _ready() -> void:
	player = get_parent().get_node_or_null("Player") as CharacterBody3D

	create_materials()
	create_cabin()
	create_doors()
	create_panels()
	create_lighting()

	create_landing_button(1)
	create_landing_button(2)

	create_interaction_ray()
	create_interface()

func make_material(
	color: Color,
	metal: float,
	rough: float,
	glowing: bool = false
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = rough

	if glowing:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.0

	return material

func create_materials() -> void:
	materials["steel"] = make_material(
		Color("#8494A8"), 0.85, 0.28
	)
	materials["dark"] = make_material(
		Color("#172131"), 0.35, 0.42
	)
	materials["black"] = make_material(
		Color("#080F1B"), 0.15, 0.35
	)
	materials["trim"] = make_material(
		Color("#C1CDDB"), 0.9, 0.2
	)
	materials["floor"] = make_material(
		Color("#26384F"), 0.15, 0.65
	)
	materials["blue"] = make_material(
		Color("#258BFF"), 0.15, 0.3, true
	)

func add_visual(
	parent: Node3D,
	part_name: String,
	size: Vector3,
	part_position: Vector3,
	material: StandardMaterial3D
) -> void:
	var visual := MeshInstance3D.new()
	visual.name = part_name

	var mesh := BoxMesh.new()
	mesh.size = size

	visual.mesh = mesh
	visual.position = part_position
	visual.material_override = material

	parent.add_child(visual)

func add_piece(
	part_name: String,
	part_position: Vector3,
	size: Vector3,
	material: StandardMaterial3D,
	solid: bool = true
) -> void:
	add_visual(
		self,
		part_name,
		size,
		part_position,
		material
	)

	if solid:
		var collision := CollisionShape3D.new()
		collision.name = part_name + "Collision"

		var shape := BoxShape3D.new()
		shape.size = size

		collision.shape = shape
		collision.position = part_position
		add_child(collision)

func create_cabin() -> void:
	add_piece(
		"CabinFloor",
		Vector3(0, -0.035, 0),
		Vector3(3.25, 0.12, 2.85),
		materials["floor"]
	)

	add_piece(
		"LeftWall",
		Vector3(-1.65, 1.4, 0),
		Vector3(0.18, 2.8, 2.9),
		materials["dark"]
	)

	add_piece(
		"RightWall",
		Vector3(1.65, 1.4, 0),
		Vector3(0.18, 2.8, 2.9),
		materials["dark"]
	)

	add_piece(
		"BackWall",
		Vector3(0, 1.4, -1.45),
		Vector3(3.5, 2.8, 0.18),
		materials["steel"]
	)

	add_piece(
		"Roof",
		Vector3(0, 2.8, 0),
		Vector3(3.5, 0.18, 3.0),
		materials["black"]
	)

	for side in [-1.0, 1.0]:
		add_piece(
			"DoorFrame" + str(side),
			Vector3(side * 1.55, 1.3, 1.5),
			Vector3(0.18, 2.6, 0.25),
			materials["steel"]
		)

		add_piece(
			"Handrail" + str(side),
			Vector3(side * 1.48, 1.05, 0),
			Vector3(0.08, 0.08, 2.25),
			materials["trim"],
			false
		)

	add_piece(
		"TopFrame",
		Vector3(0, 2.5, 1.5),
		Vector3(3.3, 0.38, 0.25),
		materials["steel"]
	)

	add_piece(
		"CeilingLight",
		Vector3(0, 2.68, 0),
		Vector3(1.8, 0.035, 0.65),
		materials["blue"],
		false
	)

func create_door(
	door_name: String,
	x_position: float
) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = door_name

	get_parent().add_child(body)

	add_visual(
		body,
		"MetalPanel",
		Vector3(1.45, 2.26, 0.12),
		Vector3.ZERO,
		materials["steel"]
	)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.45, 2.26, 0.12)

	collision.shape = shape
	body.add_child(collision)

	body.global_position = to_global(
		Vector3(x_position, 1.13, 1.49)
	)

	return body

func create_doors() -> void:
	left_door = create_door("LeftDoor", left_x)
	right_door = create_door("RightDoor", right_x)

func create_text(
	message: String,
	text_position: Vector3,
	size: int
) -> Label3D:
	var label := Label3D.new()
	label.text = message
	label.font_size = size
	label.pixel_size = 0.004
	label.modulate = Color("#60A5FA")
	label.position = text_position

	add_child(label)
	return label

func create_panels() -> void:
	add_piece(
		"InsidePanel",
		Vector3(0.85, 1.45, -1.3),
		Vector3(1.1, 0.9, 0.08),
		materials["black"],
		false
	)

	create_floor_button(1, 0.58)
	create_floor_button(2, 1.10)

	create_text(
		"SELECT FLOOR",
		Vector3(0.85, 1.72, -1.17),
		25
	)

	floor_display = create_text(
		"01",
		Vector3(0, 2.45, 1.7),
		64
	)

	status_display = create_text(
		"READY",
		Vector3(0, 2.07, 1.7),
		38
	)

func create_floor_button(
	floor_number: int,
	x_position: float
) -> void:
	var button := Area3D.new()
	button.name = "FloorButton" + str(floor_number)
	button.position = Vector3(
		x_position,
		1.33,
		-1.22
	)

	button.collision_layer = 2
	button.collision_mask = 0
	button.set_meta("action", "floor")
	button.set_meta("floor", floor_number)
	button.add_to_group("lift_controls")

	add_child(button)

	add_visual(
		button,
		"ButtonVisual",
		Vector3(0.25, 0.25, 0.06),
		Vector3.ZERO,
		materials["blue"]
	)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.32, 0.32, 0.15)
	collision.shape = shape
	button.add_child(collision)

	var label := Label3D.new()
	label.text = str(floor_number)
	label.font_size = 48
	label.pixel_size = 0.004
	label.position = Vector3(0, 0, 0.05)
	label.modulate = Color.WHITE
	button.add_child(label)

func create_landing_button(floor_number: int) -> void:
	var button := Area3D.new()
	button.name = "LandingButton" + str(floor_number)

	button.collision_layer = 2
	button.collision_mask = 0
	button.set_meta("action", "call")
	button.set_meta("floor", floor_number)
	button.add_to_group("lift_controls")

	get_parent().add_child(button)

	button.global_position = Vector3(
		global_position.x + 1.82,
		(floor_number - 1) * FLOOR_HEIGHT + 1.2,
		global_position.z + 1.7
	)

	add_visual(
		button,
		"Panel",
		Vector3(0.34, 0.6, 0.09),
		Vector3.ZERO,
		materials["black"]
	)

	add_visual(
		button,
		"GlowingButton",
		Vector3(0.15, 0.15, 0.04),
		Vector3(0, 0, 0.07),
		materials["blue"]
	)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.4, 0.65, 0.2)
	collision.shape = shape
	button.add_child(collision)

	var label := Label3D.new()
	label.text = "CALL"
	label.font_size = 28
	label.pixel_size = 0.004
	label.position = Vector3(0, 0.4, 0.04)
	label.modulate = Color("#93C5FD")
	button.add_child(label)

func create_lighting() -> void:
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.5, 0)
	light.light_color = Color("#C8E4FF")
	light.light_energy = 1.8
	light.omni_range = 4.5
	light.shadow_enabled = false
	add_child(light)

func create_interaction_ray() -> void:
	if player == null:
		return

	var camera := player.get_node_or_null("Camera3D") as Camera3D

	if camera == null:
		return

	look_ray = RayCast3D.new()
	look_ray.name = "InteractionRay"
	look_ray.target_position = Vector3(0, 0, -2.7)
	look_ray.collision_mask = 2
	look_ray.collide_with_areas = true
	look_ray.collide_with_bodies = false

	camera.add_child(look_ray)

func create_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "InteractionUI"
	add_child(layer)

	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 26)

	layer.add_child(crosshair)

	crosshair.set_anchors_preset(
		Control.PRESET_CENTER
	)

	crosshair.offset_left = -7
	crosshair.offset_top = -16

	hint_label = Label.new()
	hint_label.add_theme_font_size_override(
		"font_size", 17
	)

	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layer.add_child(hint_label)

	hint_label.set_anchors_preset(
		Control.PRESET_CENTER
	)

	hint_label.offset_left = -150
	hint_label.offset_right = 150
	hint_label.offset_top = 32
	hint_label.offset_bottom = 65

func get_aimed_button() -> Area3D:
	if look_ray == null:
		return null

	if not look_ray.is_colliding():
		return null

	var hit = look_ray.get_collider()

	if hit is Area3D:
		var area := hit as Area3D

		if area.is_in_group("lift_controls"):
			return area

	return null

func player_inside() -> bool:
	if player == null:
		return false

	var local_pos := to_local(
		player.global_position
	)

	return (
		absf(local_pos.x) < 1.35
		and local_pos.z > -1.25
		and local_pos.z < 1.0
		and local_pos.y > 0.1
		and local_pos.y < 2.8
	)

func update_interaction_hint() -> void:
	if hint_label == null:
		return

	if state != "idle":
		hint_label.text = "Travelling to Floor " + str(target_floor)
		return

	var button := get_aimed_button()

	if button == null:
		if player_inside():
			hint_label.text = "Look at a floor button"
		else:
			hint_label.text = ""
		return

	var action: String = str(
		button.get_meta("action", "")
	)

	if action == "call":
		hint_label.text = "E - CALL ELEVATOR"

	elif action == "floor":
		var number: int = int(
			button.get_meta("floor", 1)
		)

		hint_label.text = "E - GO TO FLOOR " + str(number)

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.keycode == KEY_E:
		interact()

	elif event.keycode == KEY_1:
		if player_inside():
			request_floor(1)

	elif event.keycode == KEY_2:
		if player_inside():
			request_floor(2)

func interact() -> void:
	var button := get_aimed_button()

	if button == null:
		return

	var action: String = str(
		button.get_meta("action", "")
	)

	var floor_number: int = int(
		button.get_meta("floor", 1)
	)

	if action == "call":
		call_elevator(floor_number)

	elif action == "floor":
		if player_inside():
			request_floor(floor_number)

func call_elevator(floor_number: int) -> void:
	if state != "idle":
		return

	if floor_number == current_floor:
		doors_open = not doors_open

		if doors_open:
			status_display.text = "OPEN"
		else:
			status_display.text = "CLOSED"

	else:
		target_floor = floor_number
		doors_open = false
		state = "closing_for_trip"
		status_display.text = "CALL RECEIVED"

func request_floor(floor_number: int) -> void:
	if state != "idle":
		return

	if floor_number == current_floor:
		doors_open = true
		status_display.text = "OPEN"
		return

	target_floor = floor_number
	doors_open = false
	state = "closing_for_trip"
	status_display.text = "GOING TO " + str(floor_number)

func _physics_process(delta: float) -> void:
	var left_target: float = -0.725
	var right_target: float = 0.725

	if doors_open:
		left_target = -2.15
		right_target = 2.15

	left_x = move_toward(
		left_x,
		left_target,
		DOOR_SPEED * delta
	)

	right_x = move_toward(
		right_x,
		right_target,
		DOOR_SPEED * delta
	)

	left_door.global_position = to_global(
		Vector3(left_x, 1.13, 1.49)
	)

	right_door.global_position = to_global(
		Vector3(right_x, 1.13, 1.49)
	)

	if state == "closing_for_trip":
		if (
			is_equal_approx(left_x, -0.725)
			and is_equal_approx(right_x, 0.725)
		):
			state = "moving"

	elif state == "moving":
		var destination_y: float = (
			target_floor - 1
		) * FLOOR_HEIGHT

		position.y = move_toward(
			position.y,
			destination_y,
			TRAVEL_SPEED * delta
		)

		if is_equal_approx(position.y, destination_y):
			position.y = destination_y
			current_floor = target_floor
			state = "idle"
			doors_open = true

			floor_display.text = "0" + str(current_floor)
			status_display.text = "FLOOR " + str(current_floor)

	update_interaction_hint()

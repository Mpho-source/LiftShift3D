
extends Node3D

const FLOOR_HEIGHT: float = 4.5

func _ready() -> void:
	var old_ceiling = get_node_or_null("Ceiling")

	if old_ceiling:
		old_ceiling.queue_free()

	create_upper_floor()
	create_upper_walls()
	create_upper_light()

func create_block(
	block_name: String,
	position: Vector3,
	size: Vector3,
	color: Color
) -> void:
	var body := StaticBody3D.new()
	body.name = block_name
	body.position = position
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	mesh.material_override = material

	body.add_child(mesh)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape

	body.add_child(collision)

func create_upper_floor() -> void:
	var floor_color = Color("#35445C")

	create_block(
		"UpperFloorLeft",
		Vector3(-4.925, 4.25, 0),
		Vector3(6.15, 0.5, 16),
		floor_color
	)

	create_block(
		"UpperFloorRight",
		Vector3(4.925, 4.25, 0),
		Vector3(6.15, 0.5, 16),
		floor_color
	)

	create_block(
		"UpperFloorBack",
		Vector3(0, 4.25, -7.375),
		Vector3(3.7, 0.5, 1.25),
		floor_color
	)

	create_block(
		"UpperFloorFront",
		Vector3(0, 4.25, 2.25),
		Vector3(3.7, 0.5, 11.5),
		floor_color
	)

func create_upper_walls() -> void:
	var wall_color = Color("#59677B")

	create_block(
		"UpperBackWall",
		Vector3(0, 6.5, -7.8),
		Vector3(16, 4, 0.4),
		wall_color
	)

	create_block(
		"UpperLeftWall",
		Vector3(-7.8, 6.5, 0),
		Vector3(0.4, 4, 16),
		wall_color
	)

	create_block(
		"UpperRightWall",
		Vector3(7.8, 6.5, 0),
		Vector3(0.4, 4, 16),
		wall_color
	)

func create_upper_light() -> void:
	var light := OmniLight3D.new()
	light.name = "UpperLobbyLight"
	light.position = Vector3(0, 7.5, 1)
	light.light_color = Color("#DCEAFF")
	light.light_energy = 2.0
	light.omni_range = 12.0

	add_child(light)

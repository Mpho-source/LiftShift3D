
extends CharacterBody3D

const WALK_SPEED: float = 4.5
const RUN_SPEED: float = 7.5
const JUMP_FORCE: float = 4.5
const GRAVITY: float = 9.8
const MOUSE_SENSITIVITY: float = 0.0025

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

			camera.rotate_x(
				-event.relative.y * MOUSE_SENSITIVITY
			)

			camera.rotation.x = clampf(
				camera.rotation.x,
				deg_to_rad(-80.0),
				deg_to_rad(80.0)
			)

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_key_pressed(KEY_SPACE):
		velocity.y = JUMP_FORCE

	var input_direction := Vector2.ZERO

	if Input.is_key_pressed(KEY_W):
		input_direction.y -= 1.0

	if Input.is_key_pressed(KEY_S):
		input_direction.y += 1.0

	if Input.is_key_pressed(KEY_A):
		input_direction.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		input_direction.x += 1.0

	input_direction = input_direction.normalized()

	var direction: Vector3 = (
		transform.basis *
		Vector3(input_direction.x, 0.0, input_direction.y)
	).normalized()

	var speed: float = WALK_SPEED

	if Input.is_key_pressed(KEY_SHIFT):
		speed = RUN_SPEED

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()

extends CharacterBody3D

const SAVE_PATH = "user://settings.cfg"
@export var MAX_SPEED = 3.0
@export var MAX_SPRINT_SPEED = 4.0
@export var ACCEL = 15.0
@export var FRICTION = 8.0
@export var JUMP_VELOCITY = 4.5
@export var SPRINT_FOV_MULTIPLIER = 1.10
var FOV = 75

@export var MOUSE_SENSITIVITY = 0.001

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $Camera3D


func _ready():
	load_settings()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	FOV = camera.fov

func _input(event):

	if event.is_action_pressed("ui_cancel"):
		var settings = $settings
		settings.visible = !settings.visible
		settings.get_node("PanelContainer/VBoxContainer/fov_slider").value = FOV
		if settings.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			save_settings()
			get_tree().paused = false

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):

	change_fov(FOV, 0.25)

	if get_tree().paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_pressed("jump"): 
		velocity.y = JUMP_VELOCITY
		

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_speed = MAX_SPEED

	var is_sprinting = Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward")

	var sprint_fov = FOV * SPRINT_FOV_MULTIPLIER
	if is_sprinting:
		target_speed = MAX_SPRINT_SPEED
		change_fov(sprint_fov, 0.25)
	else:
		change_fov(FOV, 0.25)

	if is_on_floor():
		apply_friction(delta)
		accelerate(wish_dir, target_speed, ACCEL, delta)
	else:
		accelerate(wish_dir, MAX_SPEED, 1.0, delta)

	move_and_slide()

func change_fov(target_fov: float, fov_change_speed):
	if camera.fov != target_fov:
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(camera, "fov", target_fov, fov_change_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func apply_friction(delta):
	var current_speed = Vector2(velocity.x, velocity.z).length()
	if current_speed == 0:
		return

	var drop = current_speed * FRICTION * delta
	var new_speed = max(0, current_speed - drop)

	velocity.x *= new_speed / current_speed
	velocity.z *= new_speed / current_speed

func accelerate(wish_dir, wish_speed, accel, delta):
	var current_speed_in_direction = velocity.dot(wish_dir)
	var add_speed = wish_speed - current_speed_in_direction

	if add_speed > 0:
		var accel_speed = min(accel * delta * wish_speed, add_speed)
		velocity += wish_dir * accel_speed

func save_settings():
	var config = ConfigFile.new()

	config.set_value("Video", "fov", FOV)

	config.save(SAVE_PATH)

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)

	if err != OK:
		return

	FOV = config.get_value("Video", "fov", 75.0)

	camera.fov = FOV

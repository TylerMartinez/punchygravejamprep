extends CharacterBody3D

@export_group("Movement")
## Character maximum run speed on the ground in meters per second.
@export var move_speed := 30.0
## Character maximum push speed on the ground in meters per second.
@export var push_speed := 5.0
## Ground movement acceleration in meters per second squared.
@export var acceleration := 30.0
## When the player is on the ground and presses the jump button, the vertical
## velocity is set to this value.
@export var jump_impulse := 20.0
## Player model rotation speed in arbitrary units. Controls how fast the
## character skin orients to the movement or camera direction.
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character skin's
## animation tree changes between the idle and running states.
@export var stopping_speed := 1.0
## Force in which the character moves other RigidBodies
@export var push_force := 100
## The amount of time to stay in the push animation unit we revert to walk or idle
@export var push_anim_delay := 0.2

@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensitivity := 0.20
@export var tilt_upper_limit := PI / 2.0   # look up max 45°
@export var tilt_lower_limit := 0.0        # look down max 0° (straight ahead)


## Each frame, we find the height of the ground below the player and store it here.
## The camera uses this to keep a fixed height while the player jumps, for example.
var ground_height := 0.0

var _gravity := -30.0
var _was_on_floor_last_frame := true
var _camera_input_direction := Vector2.ZERO

#nonsense about the goddam jump animation
var has_decended = null
var _is_pushing = false


## The last movement or aim direction input by the player. We use this to orient
## the character model.
@onready var _last_input_direction := global_basis.z
# We store the initial position of the player to reset to it when the player falls off the map.
	#CURRENTLY NOT USING ON READY BUT PROBABLY USEFUL LOL--------------------------------------------------------------------------------------------------------------
#@onready var _start_position := global_position
@onready var _model: Node3D = %DkSkin
@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
# _model points to your instanced DkSkin.tscn
@onready var _anim_player: AnimationPlayer = $DkSkin/AnimationPlayer
@onready var _push_timer: Timer = $PushTimer


func _ready() -> void:
	_push_timer.wait_time = push_anim_delay # Set the duration
	_push_timer.one_shot = false # Set to true for a single timeout
	_push_timer.autostart = false # Control starting manually
	_push_timer.connect("timeout", Callable(self, "_on_push_timer_timeout"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	var player_is_using_mouse := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if player_is_using_mouse:
		_camera_input_direction.x = event.relative.x * mouse_sensitivity
		_camera_input_direction.y = event.relative.y * mouse_sensitivity




##NOTE You can set the physics Layer and Mask to "1" on the player3d and interact with physics blocks... im not sure why it works like this if im honest
##I think it has to do with one directional physics vs kinicmatic or something idk..


func _physics_process(delta: float) -> void:
# Inverted camera tilt
	_camera_pivot.rotation.x += _camera_input_direction.y * delta  # inverted Y
	_camera_pivot.rotation.x = clamp(_camera_pivot.rotation.x, tilt_lower_limit, tilt_upper_limit)
	_camera_pivot.rotation.y += -_camera_input_direction.x * delta  # horizontal stays the same
	_camera_input_direction = Vector2.ZERO


	# Movement input
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.4)
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := forward * raw_input.y + right * raw_input.x
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	# Filter input for rotation
	if move_direction.length() > 0.2:
		_last_input_direction = move_direction.normalized()

	# Smoothly rotate the character model toward movement direction
	if _last_input_direction.length() > 0.0:
		var target_angle := Vector3.BACK.signed_angle_to(_last_input_direction, Vector3.UP)
		var current_yaw := _model.rotation.y

		var t: float = clamp(rotation_speed * delta, 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t) # smoothstep easing


		_model.rotation.y = lerp_angle(current_yaw, target_angle, t)

	# Velocity & gravity
	var y_velocity := velocity.y
	velocity.y = 0.0
	
	var current_speed = move_speed
	if _is_pushing:
		current_speed = push_speed
	
	velocity = velocity.move_toward(move_direction * current_speed, acceleration * delta)
	if is_equal_approx(move_direction.length_squared(), 0.0) and velocity.length_squared() < stopping_speed:
		velocity = Vector3.ZERO
	velocity.y = y_velocity + _gravity * delta

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_impulse

	_was_on_floor_last_frame = is_on_floor()
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider() 
		if collider is RigidBody3D:
			var push_direction = -collision.get_normal()
			collider.apply_force(push_direction * push_force)
			_is_pushing = true
			_push_timer.start(push_anim_delay)
			velocity = collider.linear_velocity
	
	# Animation control
	var ground_speed = Vector2(velocity.x, velocity.z).length()
	var input_magnitude = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.4).length()

	# Reset jump flag
	if is_on_floor():
		has_decended = null

	if _anim_player != null:
		if not is_on_floor() and !_is_pushing:
			# Play jump once on takeoff

			if _anim_player.current_animation != "jump" and _anim_player.has_animation("jump"):
				if has_decended == null:
					_anim_player.play("jump", 0.1)
					has_decended = 1
		elif _is_pushing or (input_magnitude > 0.1 and ground_speed < 0.1):
			# Player is trying to move but is blocked -> push animation
			if _anim_player.current_animation != "push" and _anim_player.has_animation("push"):
				_anim_player.play("push", 0.1)
		elif ground_speed > stopping_speed:
			# Walk animation
			if _anim_player.current_animation != "walk" and _anim_player.has_animation("walk"):
				_anim_player.play("walk", 0.1)
		else:
			# Idle animation
			if _anim_player.current_animation != "idle" and _anim_player.has_animation("idle"):
				_anim_player.play("idle", 0.1)

func _on_push_timer_timeout():
	_is_pushing = false

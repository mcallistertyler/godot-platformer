extends KinematicBody

export var speed : float = 20
export var acceleration : float = 15 # rate of reaching max speed
export var angular_acceleration : float = 20
export var air_acceleration : float = 5 # controls how you move when in the air, adds less control in the air
export var gravity : float = 0.98 # how fast you fall
export var max_terminal_velocity : float = 20#54 # how fast the player can fall at max speed
export var jump_power : float = 20
export var wall_jump_power : float = 20

export var wall_slide_acceleration = 1
export var max_wall_slide_speed = 1
var wall_sliding = false
var can_jump = false

export(float, 0.1, 1) var mouse_sensitivity : float = 0.3 # mouse sensitivity for left right up and down
export(float, -90, 0) var min_pitch : float = -90 # max and min pitch of the camera
export(float, 0, 90) var max_pitch : float = 90

var velocity : Vector3
var y_velocity : float

#onready var camera_pivot = $CameraPivot
#onready var camera = $CameraPivot/CameraBoom/Camera
onready var camera = get_node("Camera")
onready var camera_pivot = get_node("CameraPivot")
onready var anim = get_node("AnimationPlayer")
onready var character = get_node(".")
func _ready():
	# capture mouse and lock it to the window
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	#runs every frame
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
func set_anim(dir):
	if dir == Vector3(0, 0, 0):
		anim.play("Idle")
	pass

func _on_touched_wall(body):
	if body is StaticBody:
		print("is static body")
		#queue_free()

func handle_movement(delta):
	var direction = Vector3()
	var inputMoveVector = Vector2()
	var cam_global_position = camera.get_global_transform().basis
	var is_moving = false
	# transform.basis gives current direction of the player
	if Input.is_action_pressed("move_forward"):
		inputMoveVector.y += 1
		is_moving = true
		if is_on_floor():
			anim.play("Run")
	if Input.is_action_pressed("move_backward"):
		inputMoveVector.y -= 1
		is_moving = true
		if is_on_floor():
			anim.play_backwards("Run")
	if Input.is_action_pressed("move_left"):
		if not wall_sliding:
			inputMoveVector.x -= 1
			is_moving = true
		if is_on_floor():
			anim.play("Run")
	if Input.is_action_pressed("move_right"):
		if not wall_sliding:
			inputMoveVector.x +=1
			is_moving = true
		if is_on_floor():
			anim.play("Run")
	inputMoveVector = inputMoveVector.normalized()
	direction += -cam_global_position.z * inputMoveVector.y
	direction += cam_global_position.x * inputMoveVector.x
	direction.y = 0
	direction = direction.normalized()

	set_anim(direction)
	
	var accel = acceleration if is_on_floor() else air_acceleration
	
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	
	y_velocity = clamp(y_velocity - gravity, -max_terminal_velocity, max_terminal_velocity)
	
	#if is_on_wall() and !is_on_floor() and Input.is_action_pressed("move_forward") or Input.is_action_pressed("move_backward"):
		#print("Wall sliding conditions met.")
		# slow down tv so it scrapes down the wall
		# lock movement, only allow to jump
		# jump off at a defined angle that still locks movement, e.g. dont allow immediate movement after performing wall jump
		#print(direction)
	#	wall_sliding = true
	#	if velocity.y >= 0:
	#		velocity.y = min(velocity.y + wall_slide_acceleration, max_wall_slide_speed)
	#else:
	#	wall_sliding = false
	#for i in get_slide_count():
	#	var collision = get_slide_collision(i)
	#	print("Collided with: ", collision.collider.name)
	
	if Input.is_action_just_pressed("jump") and (is_on_floor() or wall_sliding):
		y_velocity = jump_power
		if wall_sliding && Input.is_action_just_pressed("jump"):
			velocity.z = velocity.z * -wall_jump_power
	
		
	velocity.y = y_velocity
	velocity = move_and_slide(velocity, Vector3.UP)
	# this handles rotation e.g moving to the right moves player to face that direction
	if is_moving and is_on_floor() and not is_on_wall():
		var angle = atan2(velocity.x, velocity.z)
		var char_rot = $Armature.get_rotation()
		print('angle', angle)
		char_rot.y = angle
		$Armature.set_rotation(char_rot)


func _physics_process(delta):
	handle_movement(delta)
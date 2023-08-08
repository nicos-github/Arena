extends CharacterBody3D

@onready var Head = $Head
@onready var Camera = $Head/Camera3D

const HEAD_LEVEL = 1.5
const SENSITIVITY = 1

var speed = 0
const WALK_SPEED = 3.0
const SPRINT_SPEED = 8.0

var acceleration = 0
const GROUND_ACCELERATION = 8.0
const AIR_ACCELERATION = 2.5

const JUMP_VELOCITY = 6.5

const RESISTANT_FALL_VELOCITY = 12 # over this velocity fall damage is applied

const GRAVITY = 20

# WATER AND SWIMMING
const SWIM_SPEED = 4.0
const SWIM_ACCELERATION = 2.5
const SWIM_VERTICAL_VELOCITY = 4.0
const WATER_EXIT_VELOCITY = 6.0
const WATER_GRAVITY = 2
var water_entry_point := Vector3()
@onready var Effect_Underwater = $UserInterface/Effect_Underwater

# LADDERS
const LADDER_SPEED = 7.0
const LADDER_EXIT_VELOCITY = 5.0

# FOV
const FOV_BASE = 93.0
const FOV_CHANGE = 2.0
const FOV_CHANGE_SPEED = 10.0

# Bob variables
const BOB_FREQUENCY = 2.0
const BOB_AMPLITUDE = 0.05
var bobTime = 0

# View sawy
const VIEW_SWAY_SPEED = 3.0
const VIEW_SWAY_STRENGTH = 1.0

# Wallrunning
@onready var WallLeftRay = $Head/Wallrunning/WallLeftRay
@onready var WallRightRay = $Head/Wallrunning/WallRightRay
@onready var FloorRay = $Head/Wallrunning/FloorRay
const WALL_RUN_SPEED = 9.0
const WALL_JUMP_UP_FORCE = 6.5
const WALL_JUMP_SIDE_FORCE = 10.0
const WALL_RUN_GRAVITY = 1.2
const WALL_RUN_FOV_CHANGE = -5
const WALL_RUN_FOV_CHANGE_SPEED = 5
const WALL_RUN_VIEW_ROLL = 4
const WALL_RUN_VIEW_ROLL_SPEED = 8.0
const WALL_EXIT_TIMER = 0.01
var is_wallrunning = false
var is_exiting_wall = false
var exiting_wall_time = 0.0

enum MOVEMENT {
	NORMAL,
	LADDER,
	SLIDING,
	WALLRUNNING,
	SWIMMING
}

var movement : MOVEMENT = MOVEMENT.NORMAL; 

var last_fall_velocity := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Head.transform.origin.y = HEAD_LEVEL

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		Head.rotate_y(-event.relative.x * SENSITIVITY / 1000)
		Camera.rotate_x(-event.relative.y * SENSITIVITY / 1000)
		Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	match movement:
		MOVEMENT.NORMAL:
			_movement_normal(delta)
		MOVEMENT.SWIMMING:
			_movement_swimming(delta)
		MOVEMENT.LADDER:
			_movement_ladder()
		MOVEMENT.WALLRUNNING:
			_movement_wallrunning(delta)
			


func _movement_normal(delta):
	
	# Fall Damage
	if last_fall_velocity < -RESISTANT_FALL_VELOCITY and is_on_floor(): ## Player Landed
		print(round(exp(-last_fall_velocity/5)/2))
		last_fall_velocity = 0
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		last_fall_velocity = velocity.y
	
	# Handle Jump
	if Input.is_action_just_pressed("move_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Handle slow Walk
	speed = SPRINT_SPEED
	if Input.is_action_pressed("move_walk"):
		speed = WALK_SPEED
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity := Vector3()
	
	if direction:
		target_velocity.x = direction.x * speed
		target_velocity.z = direction.z * speed
	else:
		target_velocity.x = 0.0
		target_velocity.z = 0.0
		
	target_velocity.y = velocity.y
	
	# Handle acceleration
	acceleration = GROUND_ACCELERATION
	if (!is_on_floor()):
		acceleration = AIR_ACCELERATION
	
	velocity = lerp(velocity, target_velocity, delta * acceleration)
	
	move_and_slide()
	
	# HeadBob
	bobTime += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin = _head_bob(bobTime)
	
	# FOV 
	var velocity_clamped = clamp(velocity.length(), 0, SPRINT_SPEED) / (SPRINT_SPEED)
	var target_fov = FOV_BASE + (FOV_CHANGE * velocity_clamped)
	Camera.fov = lerp(Camera.fov, target_fov, delta * FOV_CHANGE_SPEED)
	
	# View Sway
	var view_sway = -(Input.get_axis("move_left","move_right") * deg_to_rad(VIEW_SWAY_STRENGTH) * velocity_clamped) 
	Head.rotation.z = lerp(Head.rotation.z, view_sway, delta * VIEW_SWAY_SPEED)
	Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Wall Running
	if is_on_wall_only() and !FloorRay.is_colliding():
		movement = MOVEMENT.WALLRUNNING
	
func _movement_swimming(delta):

	if not is_on_floor():
		velocity.y -= WATER_GRAVITY * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity := Vector3()
	
	# swim up
	if Input.is_action_pressed("move_jump"):
		target_velocity.y = SWIM_VERTICAL_VELOCITY
	if Input.is_action_pressed("move_crouch"):
		target_velocity.y = -SWIM_VERTICAL_VELOCITY
	
	if direction:
		target_velocity.x = direction.x * SWIM_SPEED
		target_velocity.z = direction.z * SWIM_SPEED
	else:
		target_velocity.x = 0.0
		target_velocity.z = 0.0

	velocity = lerp(velocity, target_velocity, delta * SWIM_ACCELERATION)

	move_and_slide()
	
	# water effect UI when under entry point
	Effect_Underwater.visible = global_transform.origin.y < water_entry_point.y - HEAD_LEVEL

func _movement_ladder():

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity.x = 0
	velocity.z = 0
	
	if direction:
		velocity.y = -direction.z * LADDER_SPEED
		
		if is_on_floor():
			velocity.z = direction.z * LADDER_SPEED
	else:
		velocity.y = 0.0
		
	# exit ladder
	if Input.is_action_pressed("move_jump"):
		velocity = LADDER_EXIT_VELOCITY * Head.transform.basis.z

	move_and_slide()

func _movement_wallrunning(delta):
	
	WallLeftRay.force_raycast_update()
	WallRightRay.force_raycast_update()
	FloorRay.force_raycast_update()
	
	var wall_left = WallLeftRay.is_colliding()
	var wall_right = WallRightRay.is_colliding()
		
	is_wallrunning = (wall_left or wall_right) and !FloorRay.is_colliding() and !is_exiting_wall
	
	if is_exiting_wall:
		exiting_wall_time += delta
	
	if exiting_wall_time >= WALL_EXIT_TIMER:
		exiting_wall_time = 0.0
		is_exiting_wall = false
	
	if is_wallrunning:
		var wall_normal: Vector3 = WallLeftRay.get_collision_normal() if wall_left else WallRightRay.get_collision_normal()
				
		var wall_forward: Vector3 = wall_normal.cross(Vector3.UP)
		
		# wall run from both sides in correct direction
		if (Head.transform.basis.z - wall_forward).length() < (Head.transform.basis.z + wall_forward).length():
			wall_forward = -wall_forward
		
		# no gravity if on wall
		if is_on_wall():
			velocity.y = -WALL_RUN_GRAVITY
		
		velocity += wall_forward * WALL_RUN_SPEED * delta
		velocity -= wall_normal * 5
		
		# jumping off
		if Input.is_action_just_pressed("move_jump"):
			velocity = Vector3.UP * WALL_JUMP_UP_FORCE + wall_normal * WALL_JUMP_SIDE_FORCE + wall_forward * WALL_RUN_SPEED
			is_exiting_wall = true
		
		velocity = velocity.clamp(-Vector3(WALL_RUN_SPEED, WALL_JUMP_UP_FORCE, WALL_RUN_SPEED), Vector3(WALL_RUN_SPEED, WALL_JUMP_UP_FORCE, WALL_RUN_SPEED))
		
		
		# Wallrun FOV
		var target_fov = FOV_BASE - WALL_RUN_FOV_CHANGE
		Camera.fov = lerp(Camera.fov, target_fov, delta * WALL_RUN_FOV_CHANGE_SPEED)
				
		# Wallrun View Roll
		var target_roll = (float(wall_right) - float(wall_left)) * deg_to_rad(WALL_RUN_VIEW_ROLL)
		Head.rotation.z = lerp(Head.rotation.z, target_roll, delta * WALL_RUN_VIEW_ROLL_SPEED )
		
	else:
		movement = MOVEMENT.NORMAL
			
	move_and_slide()

func _head_bob(time) -> Vector3:
	var pos := Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos

# Water
func _enter_water(node):
	if node == self: # only react to player entering
		movement = MOVEMENT.SWIMMING
		water_entry_point = global_transform.origin


func _exit_water(node):
	if node == self: # only react to player entering
		movement = MOVEMENT.NORMAL
		velocity.y = WATER_EXIT_VELOCITY


# Ladders

func _enter_ladder(node):
	if node != self: # only react to player entering
		return
	movement = MOVEMENT.LADDER
	print("LADDER ENTERED")
	
func _exit_ladder(node):
	if node != self: # only react to player entering
		return
	movement = MOVEMENT.NORMAL
	if !is_on_floor():
		velocity.y = LADDER_EXIT_VELOCITY
	print("LADDER EXITED")

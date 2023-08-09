extends CharacterBody3D

@onready var Head = $Head
@onready var Camera = $Head/Camera3D
@onready var CollisionShape = $CollisionShape3D

const HEAD_LEVEL = 0.5
const SENSITIVITY = 1

var speed = 0
const WALK_SPEED = 4.5
var is_sprinting = false
const SPRINT_SPEED = 7.0

# Crouching
@onready var CrouchRay = $CrouchRay
var is_crouching = false
const CROUCH_SPEED = 3.0
const CROUCH_HEIGHT = 0.5 # multiplier for base height of player which is around 1.8m
const CROUCH_HEAD_LEVEL_DECREMENT = 0.5 # how much the head level shrinks

const GROUND_ACCELERATION = 60.0
const GROUND_DRAG = 10.0
const AIR_ACCELERATION = 25.0
const AIR_DRAG = 1.0

const JUMP_VELOCITY = 6.5

const RESISTANT_FALL_VELOCITY = 12 # over this velocity fall damage is applied

const GRAVITY = 20

# WATER AND SWIMMING
var is_swimming = false
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
const FOV_BASE = 90.0
const FOV_SPRINT = 3.0
const FOV_CHANGE = 2.0
const FOV_CHANGE_SPEED = 5.0

# Bob variables
const BOB_FREQUENCY = 3.0
const BOB_AMPLITUDE = 0.03
var bobTime = 0

# View sawy
const VIEW_SWAY_SPEED = 3.0
const VIEW_SWAY_STRENGTH = 1.0

# Wallrunning
@onready var WallLeftRay = $Head/Wallrunning/WallLeftRay
@onready var WallRightRay = $Head/Wallrunning/WallRightRay
@onready var FloorRay = $Head/Wallrunning/FloorRay
const WALL_RUN_SPEED = 10.0
const WALL_JUMP_EXIT_SPEED = 8.0
const WALL_JUMP_UP_FORCE = 5.0
const WALL_JUMP_SIDE_FORCE = 7.0
const WALL_RUN_GRAVITY = 1.2
const WALL_RUN_FOV_CHANGE = -5
const WALL_RUN_FOV_CHANGE_SPEED = 5
const WALL_RUN_VIEW_ROLL = 5
const WALL_RUN_VIEW_ROLL_SPEED = 5.0
const WALL_EXIT_TIMER = 0.01
var is_wallrunning = false
var is_exiting_wall = false
var exiting_wall_time = 0.0

# jump
var wish_jump_time = 0.0
const WISH_JUMP_TIME = 0.2
var double_jumped = false

# Sliding
var is_sliding = false
var slide_time = 0.0
const SLIDING_TIME = 0.75
const SLIDING_SPEED = 7
const SLIDING_ACCEL = 8
const SLIDING_DRAG = 3
const SLIDE_FOV_CHANGE = 10

# Grappling
@onready var GrapplingLine = $Head/GrapplingLine
var is_grappling = false
var started_grappling = false
var grapple_point := Vector3();
var grapple_distance = 0.0
var grappling_time = 0.0;
var grapple_cooldown := 0.0;
var grapple_overshoot_y = 2.0
const GRAPPLE_MAX_DISTANCE := 30.0;
const GRAPPLE_START_TIME := 0.5; 
const GRAPPLE_COOLDOWN := 0.0;
const GRAPPLE_TIME = 5.0
const GRAPPLE_ACCEL = 25
const GRAPPLE_SPEED = 5
const GRAPPLE_STRENGTH = 50
const GRAPPLE_MAX_TIME = 5.0;
const GRAPPLE_PULL_UP = 0.75

# UI
@onready var FPSLabel = $UserInterface/Information/FPSLabel
@onready var SpeedLabel = $UserInterface/Information/SpeedLabel
@onready var VSpeedLabel = $UserInterface/Information/VSpeedLabel
@onready var DoubleJumped = $UserInterface/Information/DoubleJumped
@onready var WishJump = $UserInterface/Information/WishJump

# Audio
@onready var SfxJump = $Audio/Jump/SfxJump
@onready var SfxDoubleJump = $Audio/Jump/SfxDoubleJump

enum MOVEMENT {
	NORMAL,
	LADDER,
	SLIDING,
	WALLRUNNING,
	SWIMMING,
	GRAPPLING
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
		MOVEMENT.SLIDING:
			_movement_sliding(delta)
		MOVEMENT.GRAPPLING:
			_movement_grappling(delta)
			
	# Grappling Line Fix
	if !((movement == MOVEMENT.NORMAL) or (movement == MOVEMENT.GRAPPLING)):
		GrapplingLine.visible = false
	
	# Grapple cooldown
	if grapple_cooldown > 0.0:
		grapple_cooldown -= delta
	
	# swimming
	if is_swimming:
		movement = MOVEMENT.SWIMMING
	
	# UI
	FPSLabel.text = "FPS: " + str(Engine.get_frames_per_second()).pad_zeros(3).pad_decimals(0)
	SpeedLabel.text = "Horizontal Speed: " + str(Vector2(velocity.x,velocity.z).length()).pad_decimals(3)
	VSpeedLabel.text = "Vertical Speed: "  + str(velocity.y).pad_decimals(3)
	DoubleJumped.text = "DoubleJumped: "  + str(double_jumped)
	WishJump.text = "WishJump: " + str(wish_jump_time > 0.0)

func _movement_normal(delta):
	
		
	# Fall Damage
	if last_fall_velocity < -RESISTANT_FALL_VELOCITY and is_on_floor(): ## Player Landed
		print(round(exp(-last_fall_velocity/5)/2))
		last_fall_velocity = 0
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		last_fall_velocity = velocity.y
	else:
		double_jumped = false
	

		
	# Handle sprint
	speed = WALK_SPEED
	if Vector2(velocity.x, velocity.z).length() > 1 and !is_crouching:
		if Input.is_action_pressed("move_sprint") and is_on_floor(): # only tap sprint key to start, not hold it
			is_sprinting = true
	else:
		is_sprinting = false
		
	if is_sprinting:
		speed = SPRINT_SPEED
	
	var head_level = HEAD_LEVEL
	
	# Handle crouch
	if is_crouching:
		speed = CROUCH_SPEED
		head_level = HEAD_LEVEL - CROUCH_HEAD_LEVEL_DECREMENT
		
	if Input.is_action_pressed("move_crouch"):
		# push player in the ground
		if is_crouching == false:
			CollisionShape.shape.height = 1.20;
			CollisionShape.transform.origin.y = -0.3
		
		is_crouching = true
		
	else:
		CrouchRay.force_raycast_update()
		if is_crouching == true and !CrouchRay.is_colliding():
			CollisionShape.transform.origin.y = 0
			CollisionShape.shape.height = 1.80;
			is_crouching = false
	
	
	# Sliding
	# if not on slope, sprint and crouch to slide, else auto slide when crouching
	if is_crouching and is_on_floor() and get_floor_angle(Vector3.UP) != 0:
		movement = MOVEMENT.SLIDING
		is_sprinting = false
	elif is_crouching and is_sprinting:
		movement = MOVEMENT.SLIDING
		is_sprinting = false
		
	# Position camera at head level
	Head.transform.origin.y = lerp(Head.transform.origin.y, head_level, 10 * delta)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Acceleration and drag
	var acceleration := Vector3()

	var accel = GROUND_ACCELERATION
	var drag = GROUND_DRAG
	if !is_on_floor():
		accel = AIR_ACCELERATION
		drag = AIR_DRAG
		
		# disable air drag when crouching
		if is_crouching:
			accel = 0.1
			drag = 0.1
	
	if direction:
		acceleration.x = direction.x * accel
		acceleration.z = direction.z * accel
	else:
		acceleration.x = 0.0
		acceleration.z = 0.0
	
	# limit speed
	var flat_vel = Vector3(velocity.x, 0, velocity.z)
	if flat_vel.length() > speed:
		acceleration = Vector3.ZERO

			
	velocity += acceleration * delta;
	
	# drag
	if acceleration.x == 0.0:
		velocity.x = lerp(velocity.x, 0.0, drag * delta)
	if acceleration.z == 0.0:
		velocity.z = lerp(velocity.z, 0.0, drag * delta)
	
	
	# Handle Jump and wish jump
	if Input.is_action_just_pressed("move_jump"):
		if FloorRay.is_colliding():
			wish_jump_time = WISH_JUMP_TIME
		elif double_jumped == false:
			double_jumped = true
			# change direction of movement with double jump
			velocity = direction * Vector2(velocity.x,velocity.z).length()
			velocity.y = JUMP_VELOCITY
			SfxDoubleJump.play()
		else:
			wish_jump_time = WISH_JUMP_TIME
	
	if wish_jump_time > 0.0:
		wish_jump_time -= delta
	else:
		wish_jump_time = 0.0
	
	if is_on_floor() and wish_jump_time > 0.0:
			velocity.y = JUMP_VELOCITY
			SfxJump.play()
	
	# limit speed
	#var flat_vel = Vector3(velocity.x, 0, velocity.z)
	#if flat_vel.length() > speed:
	#	var limited_vel = flat_vel.normalized() * speed
	#	velocity = Vector3(limited_vel.x, velocity.y, limited_vel.z)
	
	move_and_slide()
	
	# HeadBob
	bobTime += delta * velocity.length() * float(is_on_floor())
	Camera.transform.origin.y = _head_bob(bobTime).y
	$Head/Camera3D/Arms.transform.origin = _head_bob(bobTime) * 0.2 + Vector3(0.05, -0.15, -0.2)
	
	# FOV 
	var velocity_clamped = clamp(Vector2(velocity.x,velocity.z).length(), 0, WALK_SPEED) / (WALK_SPEED)
	var target_fov = FOV_BASE + (FOV_CHANGE * velocity_clamped) + (FOV_SPRINT * float(is_sprinting))
	Camera.fov = lerp(Camera.fov, target_fov, delta * FOV_CHANGE_SPEED)
	
	# View Sway
	var view_sway = -(Input.get_axis("move_left","move_right") * deg_to_rad(VIEW_SWAY_STRENGTH) * velocity_clamped) 
	Head.rotation.z = lerp(Head.rotation.z, view_sway, delta * VIEW_SWAY_SPEED)
	Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	
	# Switch to Wall Running
	if is_on_wall_only() and !FloorRay.is_colliding() and !is_crouching:
		WallLeftRay.force_raycast_update()
		WallRightRay.force_raycast_update()
		# check if strafing into the wall
		if (Input.is_action_pressed("move_left") and WallLeftRay.is_colliding()) or (Input.is_action_pressed("move_right") and WallRightRay.is_colliding()):
			movement = MOVEMENT.WALLRUNNING
			
	# Switch to grappling hook
	if Input.is_action_just_pressed("action_grapple"):
		_check_grappling(delta)
	
	# grappling line
	if !started_grappling:
		
		
		GrapplingLine.visible = (GrapplingLine.scale.z > 1.0)
		#GrapplingLine.global_transform.origin = (((global_transform.origin  - Vector3(0, 2, 0)) + grapple_point) / 2.0)
		if is_grappling:
			GrapplingLine.look_at(grapple_point)
			GrapplingLine.scale.z = lerp(GrapplingLine.scale.z, global_transform.origin.distance_to(grapple_point) * 50, delta * (1/GRAPPLE_START_TIME))
			print(global_transform.origin.distance_to(grapple_point))		
		else:
			GrapplingLine.look_at(grapple_point)
			GrapplingLine.scale.z = lerp(GrapplingLine.scale.z, 0.0, delta * (1/GRAPPLE_START_TIME) * 2.0)
			
	
	
func _movement_swimming(delta):

	if not is_on_floor():
		velocity.y -= WATER_GRAVITY * delta

	# Get the input direction and handle the movement/deceleration.
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
	Effect_Underwater.visible = global_transform.origin.y < water_entry_point.y - HEAD_LEVEL - 0.8

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
		
		double_jumped = false
		
		var wall_normal: Vector3 = WallLeftRay.get_collision_normal() if wall_left else WallRightRay.get_collision_normal()
				
		var wall_forward: Vector3 = wall_normal.cross(Vector3.UP)
		
		# wall run from both sides in correct direction
		if (Head.transform.basis.z - wall_forward).length() < (Head.transform.basis.z + wall_forward).length():
			wall_forward = -wall_forward
		
		# wallrun gravity if on wall
		if is_on_wall():
			velocity.y = -WALL_RUN_GRAVITY
		
		velocity += wall_forward * WALL_RUN_SPEED * delta
		velocity -= wall_normal * 20 * delta
		
		# jumping off
		if Input.is_action_just_pressed("move_jump"):
			velocity = Vector3.UP * WALL_JUMP_UP_FORCE + wall_normal * WALL_JUMP_SIDE_FORCE + wall_forward * WALL_JUMP_EXIT_SPEED
			SfxJump.play()
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

func _movement_sliding(delta):
	
	
	var head_level = HEAD_LEVEL
	
	if is_sliding:
		speed = CROUCH_SPEED
		head_level = HEAD_LEVEL - CROUCH_HEAD_LEVEL_DECREMENT
		
	if Input.is_action_pressed("move_crouch"):
		# push player in the ground
		if is_sliding == false:
			#CollisionShape.scale.y = 0.7
			CollisionShape.shape.height = 1.2;
			CollisionShape.transform.origin.y = -0.3
			
			slide_time = SLIDING_TIME
			
		is_sliding = true
		
	else:
		CrouchRay.force_raycast_update()
		if is_sliding == true and !CrouchRay.is_colliding():
			CollisionShape.transform.origin.y = 0
			CollisionShape.shape.height = 1.8;
			is_sliding = false
			movement = MOVEMENT.NORMAL
	
	# Position camera at head level
	Head.transform.origin.y = lerp(Head.transform.origin.y, head_level, 10 * delta)
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var slide_slope_speed = 0.0
	var slide_slope_accel = 0.0

	
	# Slopes
	if is_on_floor():
		var angle = get_floor_angle(Vector3.UP)
		velocity.y = angle * -30
		if angle != 0:
			
			slide_slope_speed = angle * SLIDING_SPEED * 5
			slide_slope_accel = angle * SLIDING_ACCEL * 3
		else:
			# if sliding on plain ground decrease sliding time
			slide_time -= delta
			print(slide_time)
			
			if slide_time > 0.0:
				slide_slope_speed = SLIDING_SPEED
				slide_slope_accel = SLIDING_ACCEL
			else:
				slide_slope_accel = -SLIDING_ACCEL
				
			if Vector2(velocity.x, velocity.z).length() < CROUCH_SPEED:
				is_sliding = false
				is_crouching = true
				movement = MOVEMENT.NORMAL
			
			
			
	else:
		slide_slope_speed = SLIDING_SPEED * 2
		slide_slope_accel = 0
	
	if Vector2(velocity.x, velocity.z).length() < slide_slope_speed:
		velocity += direction * (slide_slope_accel) * delta
	else:
		velocity.x = lerp(velocity.x, 0.0, SLIDING_DRAG * delta)
		velocity.z = lerp(velocity.z, 0.0, SLIDING_DRAG * delta)
	
	if Input.is_action_just_pressed("move_jump"):
		wish_jump_time = WISH_JUMP_TIME
	
	if wish_jump_time > 0.0:
		wish_jump_time -= delta
	
	if wish_jump_time > 0.0 and is_on_floor():
		#velocity.y = Vector3(velocity.x, 0, velocity.z).length()
		velocity.y = JUMP_VELOCITY
		SfxJump.play()
		velocity = velocity.rotated(Vector3.UP, Input.get_axis("move_right","move_left") * 0.5)
	
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
	
	move_and_slide()
	
	
	# FOV 
	var target_fov = FOV_BASE + SLIDE_FOV_CHANGE
	Camera.fov = lerp(Camera.fov, target_fov, delta * FOV_CHANGE_SPEED)
	
	# View Sway
	var view_sway = deg_to_rad(-1)
	Head.rotation.z = lerp(Head.rotation.z, view_sway, delta * VIEW_SWAY_SPEED)

func _check_grappling(delta):
	
	# check if cooldown isnt active
	if grapple_cooldown > 0.0:
		print("cant grapple now")
		movement = MOVEMENT.NORMAL
		return
	
	if is_grappling == false:
		
		is_grappling = true
		
		# raycast 
		var space_state = get_world_3d().direct_space_state
		# use global coordinates, not local to node
		var origin = global_transform.origin
		var end = global_transform.origin - Camera.global_transform.basis.z * GRAPPLE_MAX_DISTANCE
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		var result := space_state.intersect_ray(query)
		
		print("grapple shot")
		
		if result.has("collider"):
			
			grapple_point = result["position"]
			get_tree().create_timer(GRAPPLE_START_TIME, true, true, false).connect("timeout", _start_grappling.bind(global_transform.origin.distance_to(end)))
			
			
		else:
			
			# end grappling as no point was found
			print("grapple miss")
			grapple_point = end
			
			#await get_tree().create_timer(GRAPPLE_START_TIME, true, true, false).timeout
			
			get_tree().create_timer(GRAPPLE_START_TIME, true, true, false).connect("timeout", _stop_grappling)


func _start_grappling(distance):
	grapple_distance = distance
	grappling_time = GRAPPLE_TIME;
	started_grappling = true
	movement = MOVEMENT.GRAPPLING
	
	
	# go directly to target when crouching
	if Input.is_action_pressed("move_crouch"):
		var origin = global_transform.origin
		var lowest_point = Vector3(origin.x, origin.y - 1, origin.z)
		var grapple_point_relative_y = grapple_point.y - lowest_point.y
		var highest_point = grapple_point_relative_y + grapple_overshoot_y;
		
		if (grapple_point_relative_y < 0):
			highest_point = grapple_overshoot_y

		jump_to_position(grapple_point, highest_point)
		
	
	# max grapling timer 
	get_tree().create_timer(GRAPPLE_MAX_TIME, true, true, false).connect("timeout", _stop_grappling)
	

func _stop_grappling():
	is_grappling = false
	started_grappling = false
	grapple_cooldown = GRAPPLE_COOLDOWN
	movement = MOVEMENT.NORMAL

func _movement_grappling(delta):

	
	if started_grappling:

		GrapplingLine.look_at(grapple_point)
		GrapplingLine.scale.z = global_transform.origin.distance_to(grapple_point) * 50
		print(global_transform.origin.distance_to(grapple_point))		
		
		
		if !is_on_floor():
			velocity.y -= GRAVITY * delta

		if grappling_time > 0:
			grappling_time -= delta
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction = (Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		if global_transform.origin.distance_to(grapple_point) > 1:
			var y_accel = 0
			if Input.is_action_pressed("move_jump"):
				y_accel = GRAPPLE_PULL_UP
			velocity = velocity.lerp((global_transform.origin.direction_to(grapple_point+Vector3(0, grapple_overshoot_y, 0)) * (global_transform.origin.distance_to(grapple_point) / grapple_distance) * GRAPPLE_STRENGTH) + (direction+Vector3(0, y_accel, 0)) * (GRAPPLE_ACCEL * (grappling_time/GRAPPLE_TIME)), GRAPPLE_SPEED * ((GRAPPLE_TIME-grappling_time)/GRAPPLE_TIME) * delta )
		else:
			_stop_grappling()

		move_and_slide()

		if Input.is_action_just_pressed("action_grapple"):
			_stop_grappling()
			
	else:
		_stop_grappling()

func calculate_grapple_velocity(origin: Vector3, end: Vector3, height: float) -> Vector3:
	var displacementY: float = end.y - origin.y;
	var displacementXZ: Vector3 = Vector3(end.x - origin.x, 0.0, end.z - origin.z)
	
	print("DisplacenentXZ:" + str(displacementXZ))
	print("DisplacenentY:" + str(displacementY))
	
	var velocityY := Vector3.UP * sqrt(2.0 * GRAVITY * height)
	var velocityXZ = displacementXZ / (sqrt(2.0 * height / GRAVITY) + sqrt(-2.0 * (displacementY - height) / GRAVITY))
	
	var vel = velocityXZ + velocityY
	print(vel)
	return vel

func jump_to_position(target: Vector3, height: float) -> void:
	velocity = calculate_grapple_velocity(global_transform.origin, target, height)
	
	
func _head_bob(time) -> Vector3:
	var pos := Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	return pos

# Water
func _enter_water(node):
	if node == self: # only react to player entering
		_stop_grappling()
		movement = MOVEMENT.SWIMMING
		water_entry_point = global_transform.origin
		is_swimming = true

func _exit_water(node):
	if node == self: # only react to player entering
		movement = MOVEMENT.NORMAL
		velocity.y = WATER_EXIT_VELOCITY
		is_swimming = false

# Ladders

func _enter_ladder(node):
	
	if node != self: # only react to player entering
		return
	_stop_grappling()
	movement = MOVEMENT.LADDER
	print("LADDER ENTERED")
	
func _exit_ladder(node):
	if node != self: # only react to player entering
		return
	movement = MOVEMENT.NORMAL
	if !is_on_floor():
		velocity.y = LADDER_EXIT_VELOCITY
	print("LADDER EXITED")

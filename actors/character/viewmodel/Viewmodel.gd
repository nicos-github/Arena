extends Node3D

const MODEL_TURN_SPEED = 30 	# how fast the model turns to the position
const MODEL_MAX_SWAY = PI/12		# how much degrees the model can sway ( this is here to prevent clipping )
const MODEL_ACCEL = 10			# how fast the feet react to velocity change

@onready var Head = $character/rig/Skeleton3D/Head
@onready var Body = $character/rig/Skeleton3D/Chest
@onready var Arms = $character/rig/Skeleton3D/Arms
@onready var Legs = $character/rig/Skeleton3D/Legs
@onready var AnimPlayer = $character/AnimationPlayer
@onready var AnimTree = $AnimationTree

var thirdperson = true

var target_model_rotation := 0.0
var target_aim_rotation := Vector3()

var target_velocity := Vector2()
var current_velocity := Vector2()

func _init_third_person():
	thirdperson = true

	# TPS body parts shadow and visibility
	Head.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	Body.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	Arms.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	Legs.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON) # SHADOW_CASTING_SETTING_ON for visible legs
	

func _init_first_person():
	thirdperson = false
	# Materials
	#Arms.set_surface_override_material(0, load("res://actors/character/viewmodel/ViewmodelShader.tres"))

	# FPS body parts shadow and visibility
	Head.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	Body.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	Arms.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	Legs.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_ON) # SHADOW_CASTING_SETTING_ON for visible legs
	
	
func _set_aim_rotation(aim_rot: Vector2):
	var rot = (aim_rot.y / (PI/2))
	var blend_amt = min(abs(rot * 5), 0.8)
	#AnimTree.set("parameters/Aiming/blend_position", rot)
	AnimTree.set("parameters/Aiming/blend_position", rot)
	AnimTree.set("parameters/AimingBlend/blend_amount", blend_amt)

func _set_velocity(velocity: Vector2):
	target_velocity = velocity

func _set_crouching(crouch: bool):
	pass
	#if crouch:
	#	AnimTree.set("parameters/Transition/transition_request", "CROUCHING")
	#else:
	#	AnimTree.set("parameters/Transition/transition_request", "NORMAL")

func _set_sliding(slide: bool):
	if slide:
		AnimTree.set("parameters/STATES/transition_request", "SLIDING")
	else:
		AnimTree.set("parameters/STATES/transition_request", "NORMAL")

func _set_jump():
	print("JUMP!!")
	AnimTree.set("parameters/JumpBlend/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _set_grounded(grounded: bool):
	if grounded:
		AnimTree.set("parameters/MOVESTATE/transition_request", "GROUNDED")
		AnimTree.set("parameters/SLIDE_STATE/transition_request", "GROUNDED")
	else:
		AnimTree.set("parameters/MOVESTATE/transition_request", "AIR")
		AnimTree.set("parameters/SLIDE_STATE/transition_request", "AIR")

func _set_wallrun(wallrun: bool, wall: float):
	if wallrun:
		AnimTree.set("parameters/MOVESTATE/transition_request", "WALLRUN")
		AnimTree.set("parameters/Wallrunning/blend_position", wall)


func _set_ladder(ladder: bool, vel: float):
	if ladder:
		AnimTree.set("parameters/MOVESTATE/transition_request", "LADDER")
		AnimTree.set("parameters/Ladder/blend_position", vel)

func _set_grapple(grapple: bool, vel: float):
	if grapple:
		AnimTree.set("parameters/MOVESTATE/transition_request", "GRAPPLING")
		AnimTree.set("parameters/Grappling/blend_position", vel)

func _process(delta):
	# handle model rotation
	self.rotation.y = lerp_angle(self.rotation.y, target_model_rotation, min(MODEL_TURN_SPEED * delta, 1.0))
	
	
	current_velocity = lerp(current_velocity, target_velocity, MODEL_ACCEL * delta)
	#print(current_velocity)
	AnimTree.set("parameters/Running/blend_position", current_velocity)
	

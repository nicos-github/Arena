extends Node3D

const MODEL_TURN_SPEED = 30 	# how fast the model turns to the position
const MODEL_MAX_SWAY = PI/12		# how much degrees the model can sway ( this is here to prevent clipping )

@onready var Head = $MDL_Character/rig/Skeleton3D/Head
@onready var Body = $MDL_Character/rig/Skeleton3D/Body
@onready var Arms = $MDL_Character/rig/Skeleton3D/Arms
@onready var Legs = $MDL_Character/rig/Skeleton3D/Legs
@onready var AnimPlayer = $MDL_Character/AnimationPlayer
@onready var AnimTree = $AnimationTree

var first_person = true

var target_model_rotation := 0.0
var target_aim_rotation := Vector3()

func _init_first_person():
	first_person = true
	
	# Materials
	#Arms.set_surface_override_material(0, load("res://actors/character/viewmodel/ViewmodelShader.tres"))
	
	
	# FPS body parts shadow and visibility
	Head.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	Body.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	Arms.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	Legs.set_cast_shadows_setting(GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY) # SHADOW_CASTING_SETTING_ON for visible legs

func _set_aim_rotation(aim_rot: Vector2):
	var rot = (aim_rot.y / (PI/2))
	AnimTree.set("parameters/BlendSpace1D/blend_position", rot)

func _set_crouching(crouch: bool):
	if crouch:
		AnimTree.set("parameters/Transition/transition_request", "CROUCHING")
	else:
		AnimTree.set("parameters/Transition/transition_request", "NORMAL")

func _process(delta):
	# handle model rotation
	self.rotation.y = lerp_angle(self.rotation.y, target_model_rotation, min(MODEL_TURN_SPEED * delta, 1.0))
	

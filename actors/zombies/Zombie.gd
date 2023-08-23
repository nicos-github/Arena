extends CharacterBody3D

class_name Zombie

const SPEED = 4.0
const ATTACK_RANGE = 2.0
const TURN_SPEED = 10.0

@export var health := 100.0
var dead := false

@export var IS_SHOOTER = false
@export var SHOOTING_RANGE = 10

var target = null
var original_target = null
@export var target_path : NodePath

@onready var nav_agent = $NavigationAgent3D
@onready var AnimTree = $AnimationTree

@onready var SfxHit = $Audio/Hit
@onready var SfxAttack = $Audio/Attack
@onready var SfxDie = $Audio/Die

@onready var ProjectileScn = preload("res://actors/projectiles/Projectile.tscn")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var GRAVITY = 20

func _ready():
	original_target = get_node(target_path)
	target = original_target

func _physics_process(delta):
	
	if target is Zombie:
		if target.dead:
			target = original_target
	
	if target == null:
		return
	
	var state_machine = AnimTree.get("parameters/playback")
	

	
	# Navigation ( only if walking anim )
	match state_machine.get_current_node():
		"Walk":
			nav_agent.set_target_position(target.global_position)
			var next_nav_point = nav_agent.get_next_path_position()
			var vel = (next_nav_point - global_position).normalized() * SPEED
			velocity.x = vel.x
			velocity.z = vel.z
			rotation.y = lerp_angle(rotation.y, atan2(velocity.x, velocity.z), TURN_SPEED * delta)
		"Attack":
			velocity.x = 0.0
			velocity.z = 0.0
			look_at(Vector3(target.global_position.x, self.global_position.y, target.global_position.z), Vector3.UP, true)
		"Hit":
			velocity.x = 0.0
			velocity.z = 0.0
			AnimTree.set("parameters/conditions/hit", false) # reset hit
		"Die":
			velocity.x = 0.0
			velocity.z = 0.0
			$CollisionShape3D.disabled = true
	
	
	# Add gravity
	if not is_on_floor() and !dead:
		velocity.y -= GRAVITY * delta
	
	move_and_slide()
	
	AnimTree.set("parameters/conditions/attack", is_target_in_range(ATTACK_RANGE * 0.7 + (float(IS_SHOOTER) * SHOOTING_RANGE)))
	

func damage(value, knockback, owner = null) -> void:
	
	$HitBlood.restart()
	
	# change target to owner 
	if is_instance_valid(owner):
		target = owner

	
	SfxHit.play()
	AnimTree.set("parameters/conditions/hit", true)
	
	health -= value
	
	if health <= 0:
		SfxHit.stop()
		if !SfxDie.is_playing() and AnimTree.get("parameters/conditions/dead") == false:
			SfxDie.play()
		AnimTree.set("parameters/conditions/dead", true)
		dead = true
		get_tree().create_timer(0.75).timeout.connect(show_blood_decal)

func show_blood_decal() -> void:
	$BloodDecal.show()

func is_target_in_range(range) -> bool:
	if is_instance_valid(target):
		return self.global_position.distance_to(target.global_position) <= range
	else:
		return false

func hit_target():
	if is_target_in_range(ATTACK_RANGE):
		target.damage(20.0,  self.global_position.direction_to(target.global_position) * 5)
	elif is_target_in_range(ATTACK_RANGE * SHOOTING_RANGE):
		shoot_projectile()

func shoot_projectile() -> void:
	var projectile = ProjectileScn.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	get_tree().root.add_child(projectile)
	projectile.initialize(false, 15.0, 0.2, 25.0, 5.0, 0.0, true, 1.0)
	projectile.ignore(self.get_rid())
	var origin = $GunOrigin.global_position
	var end = origin + $GunOrigin.global_transform.basis.z + Vector3(0.0, 0.5, 0.0)
	
	projectile.add_owner(self)
	projectile.shoot(origin, end)

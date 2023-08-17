extends Node3D

class_name Projectile

# vars

const GRAVITY = 19.62

var IS_HITSCAN := false
var PROJECTILE_SPEED := 5.0
var TRAIL_SPEED := 0.2
var DAMAGE := 1.0
var DAMAGE_DROPOFF := 0.0 	# per meter of flight path
var WALL_STRENGTH = 0.0		# wall banging power
var HAS_GRAVITY := false
var MAXIMUM_LIFETIME := 1.0	# projectile shot in air lifetime

# explosives
var IS_EXPLOSIVE := false
var EXPLOSIVE_FORCE := 1.0
var EXPLOSIVE_SIZE := 1.0
var EXPLOSIVE_DAMAGE := 1.0

@onready var ProjectileNode = $ProjectileNode
@onready var ProjectileRay = $ProjectileRay
@onready var TrailNode = $Trail
@onready var TrailParticle = $Trail/TrailParticle
@onready var HitParticle = $Trail/HitParticle

# active projectile ( is flying )
var is_active := false
var destination := Vector3()
var current_gravity := 0.0
var direction := Vector3()
var lifetime := 0.0

func ignore(rid: RID) -> void:
	ProjectileRay.add_exception_rid(rid)

func initialize(is_hitscan := false, projectile_speed := 5.0, trail_speed := 0.2, damage := 1.0, damage_dropoff := 0.0, wall_strength := 0.0, gravity := false, max_lifetime := 1.0) -> void:
	IS_HITSCAN = is_hitscan
	PROJECTILE_SPEED = projectile_speed
	TRAIL_SPEED = trail_speed
	DAMAGE = damage
	DAMAGE_DROPOFF = damage_dropoff
	WALL_STRENGTH = wall_strength
	HAS_GRAVITY = gravity
	MAXIMUM_LIFETIME = max_lifetime

func initialize_explosive(is_explosive := true, explosive_force := 1.0, explosive_size := 1.0, explosive_damage := 1.0) -> void:
	IS_EXPLOSIVE = is_explosive
	EXPLOSIVE_FORCE = explosive_force
	EXPLOSIVE_SIZE = explosive_size
	EXPLOSIVE_DAMAGE = explosive_damage

func shoot(_origin := Vector3(), _destination := Vector3()) -> void:
	
	if _origin == _destination:
		print("Projectile Origin cant be the same as destination")
		queue_free()
		return
	
	ProjectileNode.global_transform.origin = _origin
	TrailNode.global_transform.origin = _origin
	ProjectileNode.look_at_from_position(_origin, _destination)
	destination = _destination
	direction = _origin.direction_to(_destination)
	is_active = true
	
	# Trail
	TrailParticle.lifetime = MAXIMUM_LIFETIME
	TrailParticle.process_material.gravity = Vector3(0, -GRAVITY, 0) if HAS_GRAVITY else Vector3()
	TrailParticle.process_material.direction = direction
	TrailParticle.process_material.initial_velocity_min = PROJECTILE_SPEED
	TrailParticle.process_material.initial_velocity_max = PROJECTILE_SPEED
	TrailParticle.trail_lifetime = TRAIL_SPEED
	TrailParticle.one_shot = true
	TrailParticle.amount = 16
	TrailParticle.explosiveness = 1.0
	TrailParticle.restart()
	
	
func _physics_process(delta):
	
	# Destroy projectile after maximum lifetime
	lifetime += delta
	if lifetime > MAXIMUM_LIFETIME:
		queue_free()
	
	if !is_active:
		return
	
	if is_active:
		var position = ProjectileNode.global_transform.origin
		
		# Calculate Gravity
		if HAS_GRAVITY:
			current_gravity += GRAVITY * delta
		else:
			current_gravity = 0.0
		
		# Perform Projectile Raycast in flying direction
		var speed = PROJECTILE_SPEED * delta
		var ray_step = (direction * speed)
		var ray_step_gravity = ray_step - Vector3(0, current_gravity * delta, 0)
		
		ProjectileRay.global_transform.origin = position			# align the raycast with the projectile
		ProjectileRay.target_position = ray_step_gravity			# look where the projectile will land next frame
		
		ProjectileRay.force_raycast_update()						# update the raycast
		print(ProjectileRay.is_colliding())
		
		# Update Projectile Position by Speed
		var step = position + ray_step								# calculate the position of the projectile next frame
		var step_gravity = step - Vector3(0, current_gravity * delta, 0)	# calcualte the gravity position of the projectile
		ProjectileNode.global_transform.origin = step_gravity
		
		# Update Trail Position
		
		# HIT
		if ProjectileRay.is_colliding():
			hit()
		

func hit() -> void:
	is_active = false
	
	var collision_point = ProjectileRay.get_collision_point()
	
	# hit particles
	TrailParticle.visible = false
	HitParticle.global_transform.origin = collision_point
	HitParticle.restart()
	
	# Play Hit Sound
	# Calculate Damage Falloff
	# Create Bullet Hole
	# If hit an entity, apply damage if damage is over zero
	
	# If explosive, create an explosion
	if IS_EXPLOSIVE:
		var explosionScn = preload("res://effects/explosions/explosion1.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		get_tree().root.add_child(explosionScn)
		explosionScn.global_transform.origin = collision_point
		explosionScn.explode(EXPLOSIVE_SIZE, EXPLOSIVE_FORCE, EXPLOSIVE_DAMAGE)

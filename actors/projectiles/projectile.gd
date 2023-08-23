extends Node3D

class_name Projectile

# vars

const GRAVITY = 19.62

@export var IS_HITSCAN := false
@export var IS_MELEE := false
@export var PROJECTILE_SPEED := 5.0
@export var TRAIL_SPEED := 0.2
@export var DAMAGE := 1.0
@export var DAMAGE_DROPOFF := 0.0 	# percentage per 10 meters of flight path
@export var WALL_STRENGTH = 0.0		# wall banging power
@export var HAS_GRAVITY := false
@export var MAXIMUM_LIFETIME := 1.0	# projectile shot in air lifetime
@export var MELEE_RANGE := 3.0 # how many meters the melee projectiles ranges

# explosives
@export_category("Explosive")
@export var IS_EXPLOSIVE := false
@export var EXPLOSIVE_FORCE := 1.0
@export var EXPLOSIVE_SIZE := 1.0
@export var EXPLOSIVE_DAMAGE := 1.0

# bounce
@export_category("Bounce")
@export var IS_BOUNCY := false
@export var max_bounces : int = 20
@export var bounces : int = 0

@export_category("Nodes")
@export var ProjectileNode : Node3D
@export var ProjectileRay : RayCast3D
@export var TrailNode : Node3D
@export var TrailParticle : GPUParticles3D
@export var HitParticle : GPUParticles3D
@export var HitSound : AudioStreamPlayer3D

# active projectile ( is flying )
var is_active := false
var destination := Vector3()
var current_gravity := 0.0
var direction := Vector3()
var lifetime := 0.0
var creation_origin := Vector3()

# bullethole
@onready var BulletHole = preload("res://effects/bulletholes/BulletHole.tscn")

var projectile_owner;

func ignore(rid: RID) -> void:
	ProjectileRay.add_exception_rid(rid)

func add_owner(_projectile_owner) -> void:
	projectile_owner = _projectile_owner

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
	
	creation_origin = _origin
	
	if _origin == _destination:
		print("Projectile Origin cant be the same as destination")
		queue_free()
		return
	
	ProjectileNode.global_transform.origin = _origin
	TrailNode.global_transform.origin = _origin
	ProjectileNode.look_at_from_position(_origin, _destination)
	destination = _destination
	direction = _origin.direction_to(_destination)
	
	
	
	if IS_HITSCAN:
		PROJECTILE_SPEED = 5000
	
	is_active = true
	'''
	# Trail
	TrailParticle.lifetime = MAXIMUM_LIFETIME
	TrailParticle.process_material.gravity = Vector3(0, -GRAVITY, 0) if HAS_GRAVITY else Vector3()
	TrailParticle.process_material.direction = direction
	TrailParticle.process_material.initial_velocity_min = PROJECTILE_SPEED
	TrailParticle.process_material.initial_velocity_max = PROJECTILE_SPEED
	TrailParticle.trail_lifetime = TRAIL_SPEED
	TrailParticle.one_shot = true
	TrailParticle.amount = 4
	TrailParticle.explosiveness = 1.0
	TrailParticle.restart()
	'''
	TrailParticle.emitting = true
	
	
	
func _physics_process(delta):
	
	# move trail to projectile
	TrailParticle.global_transform = ProjectileNode.global_transform
	
	# Destroy projectile after maximum lifetime
	lifetime += delta
	if lifetime > MAXIMUM_LIFETIME:
		queue_free()
	
	if !is_active:
		return
	
	if is_active:
		var pos = ProjectileNode.global_transform.origin
		
		# Calculate Gravity
		if HAS_GRAVITY:
			current_gravity += GRAVITY * delta
		else:
			current_gravity = 0.0
		
		# Perform Projectile Raycast in flying direction
		var speed = PROJECTILE_SPEED * delta
		var ray_step = (direction * speed)
		var ray_step_gravity = ray_step - Vector3(0, current_gravity * delta, 0)
		
		ProjectileRay.global_transform.origin = pos			# align the raycast with the projectile
		ProjectileRay.target_position = ray_step_gravity			# look where the projectile will land next frame
		
		ProjectileRay.force_raycast_update()						# update the raycast
		
		# Update Projectile Position by Speed
		var step = pos + ray_step								# calculate the position of the projectile next frame
		var step_gravity = step - Vector3(0, current_gravity * delta, 0)	# calcualte the gravity position of the projectile
		ProjectileNode.global_transform.origin = step_gravity
		
		# Update Trail Position
		
		# HIT
		if ProjectileRay.is_colliding():
			hit()
		

func hit() -> void:
	
	
	var collision_point = ProjectileRay.get_collision_point()
	var collision_normal = ProjectileRay.get_collision_normal()
	var collider = ProjectileRay.get_collider()
	
	# set location to the hit point
	ProjectileNode.global_transform.origin = collision_point + ( collision_normal * 0.1 )
	
	# if melee, check distance to origin, if larger than range, discard
	if IS_MELEE:
		var distance = ProjectileNode.global_transform.origin.distance_to(creation_origin)
		if distance > MELEE_RANGE:
			queue_free()
			return
	
	# handle bounce, if bounce is left
	if IS_BOUNCY:
		bounces += 1
		if bounces <= max_bounces:
			# reset gravity if bounces off floor or ramp
			if (abs(collision_normal.dot(Vector3.UP)) > 0.5):
				current_gravity = 0.0 # reset gravity
			direction = direction.bounce(collision_normal)
			print("BOUNCES" + str(bounces))
			return
	
	# deactivate physics processing on this projectile
	is_active = false
	
	# hide projectile itself
	ProjectileNode.visible = false
	
	# hit particles
	TrailParticle.emitting = false
	HitParticle.global_transform.origin = collision_point
	HitParticle.restart()
	
	# Play Hit Sound
	if is_instance_valid(HitSound):
		HitSound.play()
	
	# Create Bullet Hole ( but not on characters )
	if !(collider is CharacterBody3D):
		var bulletScn : Node3D = BulletHole.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		get_tree().root.add_child(bulletScn)
		bulletScn.global_transform.origin = collision_point
		bulletScn.look_at(collision_normal, collision_point.direction_to(creation_origin))
		bulletScn.rotate(collision_normal, randf() * TAU)
		
		# scale bullet hole when explosive
		if IS_EXPLOSIVE:
			bulletScn.scale = Vector3(EXPLOSIVE_SIZE / 2.0, EXPLOSIVE_SIZE / 2.0, EXPLOSIVE_SIZE / 2.0)
		
		# destroy bullet hole after 60 ingame seconds
		get_tree().create_timer(60.0, false, true, false).timeout.connect(bulletScn.queue_free)
		
		
	
	# Calculate Damage Falloff [percentage per 10 meter of flight path]
	var distance = ProjectileNode.global_transform.origin.distance_to(creation_origin)
	var damage_dropoff = DAMAGE - (DAMAGE_DROPOFF * (distance / 10))
	
	# If hit an entity, apply damage if damage is over zero
	if collider is CollisionObject3D:
		if collider.get_collision_layer_value(4) == true: ## 4 is layer for ENTITES
			if damage_dropoff >= 1:
				collider.damage(damage_dropoff, -collision_normal * 1.0, projectile_owner)
	
	
	# If explosive, create an explosion
	if IS_EXPLOSIVE:
		var explosionScn = preload("res://effects/explosions/explosion1.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		get_tree().root.add_child(explosionScn)
		explosionScn.global_transform.origin = collision_point
		explosionScn.explode(EXPLOSIVE_SIZE, EXPLOSIVE_FORCE, EXPLOSIVE_DAMAGE)
		### ADD OWNER FIXME
	
	

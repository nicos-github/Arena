extends Node3D

var timer : SceneTreeTimer;
var explosion_force := 1.0; 
var damage_area_scale := 1.0
var damage_multiplier := 1.0

const TIME = 2.0
const DAMAGE_TIME = 0.2
const DAMAGE_AREA_RADIUS = 0.2


func _ready():
	timer = get_tree().create_timer(TIME, false, true, false)
	timer.timeout.connect(destroy)
	
func explode(_scale := 1.0, _force := 1.0, _damage_multiplier := 1.0) -> void:
	explosion_force = _force
	damage_area_scale = _scale
	damage_multiplier = _damage_multiplier
	$GPUParticles3D.process_material.scale_min = _scale
	$GPUParticles3D.process_material.scale_max = _scale
	$DamageArea.scale = Vector3(_scale, _scale, _scale)
	$GPUParticles3D.emitting = true
	$ExplosionSound.play()
	
func destroy() -> void:
	self.queue_free()
	print("explosion destroyed")


func _on_damage_area_body_entered(body):
	if is_instance_valid(timer):
		if timer.get_time_left() >= (TIME - DAMAGE_TIME):
			var direction = self.global_transform.origin.direction_to(body.global_transform.origin)
			var distance = max((DAMAGE_AREA_RADIUS * damage_area_scale) - self.global_transform.origin.distance_to(body.global_transform.origin), 0.1)
			body.damage(distance * damage_multiplier, direction * distance * explosion_force)

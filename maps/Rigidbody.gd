extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	self.apply_central_force(Vector3.UP * 10000)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

extends Node3D

@export var spawn_delay = 2.0

@onready var zombieScn = preload("res://actors/zombies/Zombie.tscn")

@export var target_path : NodePath


var spawns = []

func _ready():
	
	for spawn in self.get_children():
		if spawn is Marker3D:
			spawns.append(spawn)
	
	spawn()
	
func queue_spawn():	
	get_tree().create_timer(spawn_delay, false, true, false).timeout.connect(spawn)

func spawn():
	
	spawns.shuffle()
	
	var spawn_transform = spawns[0].global_transform
	
	var zombie = zombieScn.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	zombie.target_path = target_path
	get_parent_node_3d().add_child.call_deferred(zombie)
	zombie.global_transform = spawn_transform
	
	
	queue_spawn()

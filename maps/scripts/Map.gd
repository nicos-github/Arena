extends Node3D

'''
	Master Map Script
	
	Handles Basic Networking and Spawn Management in all Maps
	
'''

@export var Spawns : NodePath
@export var PlayerScene : PackedScene
@export var ClientScene : PackedScene
@export var MapCamera : NodePath

var GroupEntityNode : Node
var GroupProjectileNode : Node

# Called when the node enters the scene tree for the first time.
func _ready():
	create_groups()
	handle_spawns()

# groups are to categorize elements in a map, e.g. entities, projectiles
func create_groups():
	GroupEntityNode = Node3D.new()
	add_child(GroupEntityNode)
	
	GroupProjectileNode = Node3D.new()
	add_child(GroupProjectileNode)
	

# should be server sided function but still is client sided
func handle_spawns() -> void:
	
	var spawn_array := Array()
	
	var spawns = get_node_or_null(Spawns)
	
	if spawns == null:
		return
		
	for spawn in spawns.get_children():
		if spawn is Marker3D:
			spawn_array.push_back(spawn)
			
	spawn_array.shuffle()
	
	# THIS MUST BECOME SERVER SIDED ON A REQUEST CALL FROM THE PLAYER TO GET SPAWNED
	
	if (PlayerScene is PackedScene):		
		# Spawning the player only when client
		if !Server.is_server:
			var player_inst = PlayerScene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
			GroupEntityNode.add_child(player_inst)
	
	# Spawn the clients FIXME: no steam
	for client_id in multiplayer.get_peers():
		if (ClientScene is PackedScene):
			var client_inst = ClientScene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
			GroupEntityNode.add_child(client_inst)
			client_inst.set_owner_id(client_id)

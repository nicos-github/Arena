extends Node3D

var owner_id = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# if not connected, return
	if !Client.is_online:
		return
	
	# determine if on server or client side
	if Server.is_server:
		Server.sv_update_client_position.connect(sv_update_client_position)
		Server.sv_delete_client.connect(sv_delete_client)


func set_owner_id(id: int) -> void:
	owner_id = id



func sv_update_client_position(sender_id, position, rotation) -> void:
	print("CLIENT: got update from id " + str(sender_id) + " i am owned by " + str(owner_id))
	if sender_id != owner_id:
		return
	print("CLIENT: applying! update")
	self.global_position = position
	self.global_rotation = rotation

func sv_delete_client(sender_id) -> void:
	if sender_id != owner_id:
		return
	
	queue_free()

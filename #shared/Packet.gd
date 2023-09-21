extends Node

class_name Packet

var sender_id : int

var type

enum TYPE {
	MESSAGE,
	SCENE_CHANGE,
	CLIENT_POSITION,
	ETC
}

var data

func _ready():
	#FIXME no steam
	if multiplayer.has_multiplayer_peer():
		sender_id = multiplayer.get_unique_id()

func encode() -> PackedByteArray:
	var package := Dictionary()
	
	package["sender_id"] = sender_id
	package["type"] = type
	package["data"] = data
	
	return var_to_bytes(package)

static func decode(bytes) -> Dictionary:
	print("Decoding: " + str(bytes))
	return bytes_to_var(bytes)

static func read(package: Dictionary) -> String:
	return str(package["sender_id"]) + " [" + str(package["type"]) + "] " + str(package["data"])

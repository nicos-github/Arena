extends Node

class_name SteamServer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	#Steam.p2p_session_request.connect(_on_P2P_Session_Request)
	#Steam.p2p_session_connect_fail.connect(_on_P2P_Session_Connect_Fail)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Server.USE_STEAM:
		Steam.run_callbacks()

func createSteamServer() -> void:
	Server.log_console("Creating Steam Server...")
	pass

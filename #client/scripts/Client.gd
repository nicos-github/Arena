extends Node

@onready var client_scn = "res://#client/menus/cl_main_menu.tscn"

signal logConsole

func _ready():
	
	Steam.network_messages_session_failed.connect(_on_session_fail)
	
	for arg in OS.get_cmdline_args():
		if arg == "+low_res":
			DisplayServer.window_set_size(Vector2(1200, 450))
		if arg == "+client":
			get_tree().change_scene_to_file(client_scn)

func _process(delta) -> void:
	Steam.run_callbacks()

func initialize() -> void:
	Steam.steamInit()
	var INIT: Dictionary = Steam.steamInit(false)
	log_console(INIT["verbal"])
	
	Steam.initRelayNetworkAccess()
	
	# add own identity
	Steam.addIdentity("server")
	Steam.setIdentityLocalHost("server")
	
	
	log_console(Steam.isIdentityInvalid("server"))

	

func connect_to_server() -> void:
	log_console("Attempting connection to server...")
	
		
	var sendResult = Steam.sendMessageToUser("server", var_to_bytes("Hello World!"), 8, 0)
	log_console("Message sending result code: " + str(sendResult))
	
	
	#Steam.connectP2P()

func _on_session_fail() -> void:
	log_console("Session / Connection failed")



func log_console(text) -> void:
	print(text)
	emit_signal("logConsole", text)

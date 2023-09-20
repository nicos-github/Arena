extends Node

@onready var client_scn = "res://#client/menus/cl_main_menu.tscn"

signal logConsole

var game_code := ""


func _ready():
	if Server.USE_STEAM:
		Steam.network_messages_session_failed.connect(_on_session_fail)
	
	for arg in OS.get_cmdline_args():
		if arg == "+low_res":
			DisplayServer.window_set_size(Vector2(1200, 450))
		if arg == "+client":
			get_tree().change_scene_to_file(client_scn)

func _process(delta) -> void:
	if Server.USE_STEAM:
		Steam.run_callbacks()

func initialize() -> void:
	if Server.USE_STEAM:
		Steam.steamInit()
		var INIT: Dictionary = Steam.steamInit(false)
		log_console(INIT["verbal"])
		
		Steam.initRelayNetworkAccess()
		
		# add own identity
		Steam.addIdentity("server")
		Steam.setIdentityLocalHost("server")
		
		log_console(Steam.isIdentityInvalid("server"))
	
	else:
		log_console("Searching for games...")
		# Create a hole puncher and connect to the script on the server
		var hole_puncher = preload('res://addons/Holepunch/holepunch_node.gd').new()
		# your rendezvous server IP or domain
		hole_puncher.rendevouz_address = "37.120.169.220"
		# the port the HolePuncher python application is running on
		hole_puncher.rendevouz_port = 19043
		add_child(hole_puncher)
		
		var is_host = false
		# Generate a unique ID for this machine
		var player_id = ("CL" + str(Time.get_ticks_msec() % 9999))
		
		hole_puncher.start_traversal(game_code, is_host, player_id)
		# Yield an array of [own_port, host_port, host_ip]
		var result = await hole_puncher.hole_punched
		
		log_console("Holepunch result " + str(result))
		
		# Connect a client to a host
		var host_ip = result[2]
		var host_port = result[1]
		var own_port = result[0]

		var peer = ENetMultiplayerPeer.new()
		var err = peer.create_client(host_ip, host_port, 0, 0, own_port)
		get_tree().set_network_peer(peer)
		
		log_console("Game found and connected with status code " + str(err))

	

func connect_to_server() -> void:
	log_console("Attempting connection to server...")
	
		
	var sendResult = Steam.sendMessageToUser("server", var_to_bytes("Hello World!"), 8, 0)
	log_console("Message sending result code: " + str(sendResult))


func _on_session_fail() -> void:
	log_console("Session / Connection failed")



func log_console(text) -> void:
	print(text)
	emit_signal("logConsole", text)

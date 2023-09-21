extends Node

var server_scn = "res://#server/menus/sv_main_menu.tscn"

signal startServer
signal stopServer
signal logConsole


const USE_STEAM = false

var upnp = UPNP.new()
var is_server := false
var external_ip := ""
var steam_server := SteamServer.new()

func _ready():

	# load server scene if
	for arg in OS.get_cmdline_args():
		if arg == "+server":
			get_tree().change_scene_to_file(server_scn)
			DisplayServer.window_set_size(Vector2(1200, 800))
	
	if USE_STEAM:
		Steam.connect("network_messages_session_request", _on_session_request)
			
func _process(delta):
	Steam.run_callbacks()

func _start_server():
	
	if is_server == true:
		_stop_server()
		return
		
	if USE_STEAM:
		Steam.steamInit()
		var INIT: Dictionary = Steam.steamInit(false)
		log_console(INIT["verbal"])
		# relay access
		Steam.initRelayNetworkAccess()
		var id = Steam.getSteamID()
		log_console("Your steam name: " + str(name))
	
	else:
		log_console("Starting server...")
		# Create a hole puncher and connect to the script on the server
		var hole_puncher = preload('res://addons/Holepunch/holepunch_node.gd').new()
		# your rendezvous server IP or domain
		hole_puncher.rendevouz_address = "37.120.169.220"
		# the port the HolePuncher python application is running on
		hole_puncher.rendevouz_port = 19043
		add_child(hole_puncher)
		
		randomize()
		var game_code = str(randi_range(1000, 9999))
		log_console("Game Code: " + str(game_code))
		var is_host = true
		# Generate a unique ID for this machine
		var player_id = ("SV" + str(Time.get_ticks_msec() % 9999))
		
		hole_puncher.start_traversal(game_code, is_host, player_id)
		# Yield an array of [own_port, host_port, host_ip]
		var result = await hole_puncher.hole_punched
		#var result = hole_puncher.hole_punched
		
		log_console("Holepunch result " + str(result))
		
		var my_port = result[0]

		var peer = ENetMultiplayerPeer.new()
		var err = peer.create_server(my_port, 1)
		#var err = peer.create_server(12356)
		multiplayer.multiplayer_peer = peer
		#get_tree().set_network_peer(peer)
		log_console("Game found and connected with status code " + str(err))
		multiplayer.peer_connected.connect(client_connected)
	
	is_server = true
	emit_signal("startServer")
	log_console("Server started!!")
	
	
func client_connected(data):
	print("CONNECTION?!?!??!")
	log_console("CLIENT FINALLY AFTER 23478234 HOURS AND 3459873405 ATTEMPTS JOINED THE SERVER!!!!!")
	log_console(data)
	
func _stop_server():
	
	if USE_STEAM:
		Steam.steamShutdown()
		
	is_server = false
	log_console("Stopping...")
	emit_signal("stopServer")

func _exit_tree():
	_stop_server()

func log_console(text) -> void:
	print(text)
	emit_signal("logConsole", text)

func _on_session_request() -> void:
	log_console("Client tried to connect!")

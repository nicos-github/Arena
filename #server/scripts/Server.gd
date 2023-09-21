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

const PORT = 19043

signal sv_update_client_position
signal sv_delete_client

func _ready():

	# load server scene if
	for arg in OS.get_cmdline_args():
		if arg == "+server":
			get_tree().change_scene_to_file(server_scn)
			DisplayServer.window_set_size(Vector2(1200, 800))
	
	if USE_STEAM:
		Steam.connect("network_messages_session_request", _on_session_request)
	else:
		# Automatically start the server in headless mode.
		if DisplayServer.get_name() == "headless":
			print("Automatically starting dedicated server.")
			_start_server.call_deferred()

			
func _process(delta):
	if USE_STEAM:
		Steam.run_callbacks()
	else:
		pass
		
			

func _start_server():
	
	if is_server == true:
		_stop_server()
		return
		
	if USE_STEAM:
		Steam.steamInit()
		var INIT: Dictionary = Steam.steamInit()
		log_console(INIT["verbal"])
	else:
		log_console("Starting server...")
		
		# Connect signals
		multiplayer.peer_connected.connect(client_connected)
		multiplayer.peer_disconnected.connect(client_disconnected)
		
		# Start as server.
		var peer = ENetMultiplayerPeer.new()
		peer.create_server(PORT)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			log_console("Failed to start multiplayer server.")
			return
		multiplayer.multiplayer_peer = peer
		
		is_server = true
		emit_signal("startServer")
		log_console("Server started!!")
	
	
func client_connected(id) -> void:
	log_console("Client %s connected" % id)
	
	if multiplayer.is_server():
		Client.print_client_message.rpc(id, "joined the server")
		Client.print_client_message.rpc(multiplayer.get_unique_id(), "Connected peers: " + str(multiplayer.get_peers()))
		
func client_disconnected(id) -> void:
	log_console("Client %s disconnected" % id)
	
	if multiplayer.is_server():
		Client.print_client_message.rpc(id, "left the server")
		Client.print_client_message.rpc(multiplayer.get_unique_id(), "Connected peers: " + str(multiplayer.get_peers()))
		
		# delete client when disconnecting
		emit_signal("sv_delete_client", id)
	
func _stop_server():
	
	if USE_STEAM:
		Steam.steamShutdown()
	else:
		multiplayer.multiplayer_peer = null
		
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

# Packet Transfer Functions

@rpc("any_peer", "call_remote", "reliable")
func server_packet_reliable(data) -> void:
	handle_packet(Packet.decode(data))
	
@rpc("any_peer", "call_remote", "unreliable")
func server_packet_unreliable(data) -> void:
	handle_packet(Packet.decode(data))
	
@rpc("any_peer", "call_remote", "unreliable_ordered")
func server_packet_unreliable_ordered(data) -> void:
	handle_packet(Packet.decode(data))

func send_reliable(package) -> void:
	package.sender_id = multiplayer.get_unique_id()
	Server.server_packet_reliable.rpc(package.encode())
	
func send_unreliable(package) -> void:
	package.sender_id = multiplayer.get_unique_id()
	Server.server_packet_unreliable.rpc(package.encode())
	
func send_unreliable_ordered(package) -> void:
	package.sender_id = multiplayer.get_unique_id()
	Server.server_packet_unreliable_ordered.rpc(package.encode())

# Handle incoming packets

func handle_packet(packet) -> void:
	# discard faulty packages
	if !(packet is Dictionary):
		log_console("Packet is no Dictionary. discarding.. Package data: " + str(packet))
		return
		
	match packet["type"]:
		Packet.TYPE.MESSAGE:
			log_console(Packet.read(packet))
		Packet.TYPE.SCENE_CHANGE:
			get_tree().change_scene_to_file(packet["data"])
		Packet.TYPE.CLIENT_POSITION:
			log_console(str(packet["sender_id"]) + " | position | " + str(packet["data"]))
			
			var pos = packet["data"][0]
			var rot = packet["data"][1]
			
			emit_signal("sv_update_client_position", packet["sender_id"], pos, rot)

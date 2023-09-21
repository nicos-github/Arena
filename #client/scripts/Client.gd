extends Node

@onready var client_scn = "res://#client/menus/cl_main_menu.tscn"

signal logConsole

const PORT = Server.PORT

var is_online = false

func _ready():
	if Server.USE_STEAM:
		pass
		#Steam.network_messages_session_failed.connect(_on_session_fail)
	
	for arg in OS.get_cmdline_args():
		if arg == "+low_res":
			DisplayServer.window_set_size(Vector2(1200, 800))
		if arg == "+client":
			get_tree().change_scene_to_file(client_scn)

func _process(delta) -> void:
	if Server.USE_STEAM:
		Steam.run_callbacks()
	else:
		is_online = multiplayer.has_multiplayer_peer()

func initialize() -> void:
	if Server.USE_STEAM:
		Steam.steamInit()
		var INIT: Dictionary = Steam.steamInit(false)
		log_console(INIT["verbal"])
	
	else:
		log_console("Initialized Local Networking without Steam.")
		multiplayer.connected_to_server.connect(connected_to_server)
		multiplayer.connection_failed.connect(connection_failed)
		multiplayer.server_disconnected.connect(server_disconnected)

	
func client_connected(data):
	log_console("CONNECTION ESTABLISHED!!!")
	log_console(data)

func connect_to_server() -> void:
	if Server.USE_STEAM:
		pass
	else:
		
		log_console("Connecting to localhost...")
		
		var peer = ENetMultiplayerPeer.new()
		peer.create_client("localhost", PORT)
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
			OS.alert("Failed to start multiplayer client.")
			return
		multiplayer.multiplayer_peer = peer

func connected_to_server() -> void:
	log_console("Connection to Server successful!")
	
func connection_failed() -> void:
	log_console("ERROR: Connection to Server failed.")

func server_disconnected() -> void:
	log_console("Server closed.")

func log_console(text) -> void:
	print(text)
	emit_signal("logConsole", text)

@rpc("authority", "call_remote", "reliable")
func print_client_message(player_id, text) -> void:
	log_console("[" + str(player_id) + "] " + text)

# Packet Transfer Functions

@rpc("authority", "call_remote", "reliable")
func client_packet_reliable(data) -> void:
	handle_packet(Packet.decode(data))
	
	
@rpc("authority", "call_remote", "unreliable")
func client_packet_unreliable(data) -> void:
	handle_packet(Packet.decode(data))

@rpc("authority", "call_remote", "unreliable_ordered")
func client_packet_unreliable_ordered(data) -> void:
	handle_packet(Packet.decode(data))

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

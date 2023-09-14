extends Node

var server_scn = "res://#server/menus/sv_main_menu.tscn"

signal startServer
signal stopServer
signal logConsole

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
			
	Steam.connect("network_messages_session_request", _on_session_request)
			
func _process(delta):
	Steam.run_callbacks()

func _start_server():
	
	if is_server == true:
		_stop_server()
		return
	
	Steam.steamInit()
	var INIT: Dictionary = Steam.steamInit(false)
	log_console(INIT["verbal"])
	
	is_server = true

	var id = Steam.getSteamID()
	log_console("Your steam name: " + str(name))
	emit_signal("startServer")
	
	# relay access
	Steam.initRelayNetworkAccess()
	

	
func _stop_server():
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

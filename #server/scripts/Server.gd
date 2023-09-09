extends Node

var server_scn = "res://#server/menus/sv_main_menu.tscn"

var upnp = UPNP.new()
var is_server := false
var external_ip := ""

signal startServer
signal stopServer

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# load server scene if 
	for arg in OS.get_cmdline_args():
		if arg == "+server":
			get_tree().change_scene_to_file(server_scn)
			

func _start_server():
	print("Starting server...")
	is_server = true
	
	# upnp
	var discover_result = upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		print("UPNP Discovery success")
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			var map_result_udp = upnp.add_port_mapping(19043, 0, "nGineArena_UDP", "UDP", 86400) # 1 day
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				map_result_udp = upnp.add_port_mapping(19043, 0, "", "UDP", 86400)
				
				if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
					push_error("ERROR: Couldn't map port. UPNP Error code: " + str(map_result_udp))
					
			else:
				print("Server started successfully!")
		else:
			push_error("Error: Invalid gateway")
			
	else:
		push_error("ERROR: Server failed to start. UPNP Error code: " + str(discover_result))

	external_ip = upnp.query_external_address()
	
	print("Public IP: " + str(upnp.query_external_address()))
	
	emit_signal("startServer")

func _exit_tree():
	_stop_server()

func _stop_server():
	upnp.delete_port_mapping(19043, "UDP")
	
	
	emit_signal("stopServer")

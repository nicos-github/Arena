extends Control

@onready var StatusLabel = $MarginContainer/VBoxContainer/ServerStatus
@onready var ExternalIP = $MarginContainer/VBoxContainer/IP/ExternalIP

func _ready():
	Server.connect("startServer", _on_server_start)
	Server.connect("stopServer", _on_server_stop)
	
	

func _on_server_start():
	#StatusLabel.text = "Status: Online"
	ExternalIP.text = Server.external_ip

func _on_server_stop():
	StatusLabel.text = "Status: Offline"


func _on_server_start_button_pressed():
	if !Server.is_server:
		Server._start_server()

extends Control

@onready var StartButton = $MarginContainer/VBoxContainer/ServerStartButton
@onready var StatusLabel = $MarginContainer/VBoxContainer/ServerStatus
@onready var Console = $MarginContainer/VBoxContainer/Console/TextEdit

func _ready():
	Server.connect("startServer", _on_server_start)
	Server.connect("stopServer", _on_server_stop)
	Server.connect("logConsole", _on_log_console)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func _on_server_start():
	StatusLabel.text = "Status: Online"
	StartButton.text = "Stop Server"

func _on_server_stop():
	StatusLabel.text = "Status: Offline"
	StartButton.text = "Start Server"

func _on_log_console(text):
	Console.text += str(text) + "\n"
	Console.set_v_scroll(99999)

# Buttons

func _on_server_start_button_pressed():
	Server._start_server()

func _on_client_start_button_pressed():
	OS.create_instance(["+low_res", "+client"])

extends Control

@onready var Console = $MarginContainer/VBoxContainer/Console/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Client.connect("logConsole", _on_log_console)
	
	Client.initialize()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_log_console(text):
	var MAX_CHAR_COUNT = 3200
	if Console.text.length() > MAX_CHAR_COUNT:
		Console.text = Console.text.erase(0, Console.text.length() - MAX_CHAR_COUNT)
	
	Console.text += str(text) + "\n"
	Console.set_v_scroll(99999)

func _on_server_connect_pressed():
	Client.connect_to_server()


func _on_start_server_pressed():
	OS.create_instance(["+server", "+low_res"])

extends Control

@onready var Console = $MarginContainer/VBoxContainer/Console/TextEdit

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	Client.connect("logConsole", _on_log_console)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_log_console(text):
	Console.text += str(text) + "\n"
	Console.set_v_scroll(99999)

func _on_server_connect_pressed():
	Client.initialize()

func _on_game_code_text_changed(new_text):
	Client.game_code = new_text


func _on_start_server_pressed():
	OS.create_instance(["+server", "+low_res"])

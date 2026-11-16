extends Control

@onready var btn_Back: Button = $BtnBack

func _ready() -> void:
	btn_Back.pressed.connect(_on_back_pressed)
	
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")
	

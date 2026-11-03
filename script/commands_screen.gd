extends Control

@onready var btn_Back: Button = $BtnBack

func _ready() -> void:
	btn_Back.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void:
	# Volta para a tela de onde o jogador veio (fase ou menu)
	if Global.cena_origem != "":
		get_tree().change_scene_to_file(Global.cena_origem)
	else:
		get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

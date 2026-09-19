extends Control

@onready var btn_start: Button = $BtnStart
@onready var btn_commands: Button = $BtnCommands
@onready var btn_story: Button = $BtnHistory

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_commands.pressed.connect(_on_commands_pressed)
	btn_story.pressed.connect(_on_story_pressed)
   
func _on_start_pressed() -> void:
	# 1. Primeiro, avisa o Global que a fase 1 é o destino
	# IMPORTANTE: Coloque aqui o caminho exato da sua primeira fase!
	Global.proxima_fase = "res://map/mapa01.tscn" 
	
	# 2. Agora sim, chama a tela de carregamento
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn"
	)

func _on_commands_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/commands_screen.tscn")

func _on_story_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HistoryScreen.tscn")

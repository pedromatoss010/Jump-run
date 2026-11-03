extends Control

@onready var btn_start: Button = $BtnStart
@onready var btn_commands: Button = $BtnCommands
@onready var btn_story: Button = $BtnHistory

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_commands.pressed.connect(_on_commands_pressed)
	btn_story.pressed.connect(_on_story_pressed)
   
func _on_start_pressed() -> void:
	# 1. Zera o total de diamantes para a nova partida
	Global.total_diamantes = 0
	Global.resetar_status()
	
	# 2. Avisa o Global que a fase 1 é o destino
	Global.proxima_fase = "res://map/mapa01.tscn" 
	
	# 3. Chama a tela de carregamento
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	
func _on_commands_pressed() -> void:
	Global.cena_origem = "res://scenes/mainMenu.tscn"
	get_tree().change_scene_to_file("res://scenes/commands_screen.tscn")

func _on_story_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/HistoryScreen.tscn")

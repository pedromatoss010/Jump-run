extends Control

@onready var label_diamantes: Label = $VBoxContent/DiamantesScore/TotalDiamantesLabel
@onready var btn_play_again: Button = $BtnPlayAgain
@onready var btn_main_menu: Button = $BtnMainMenu

func _ready() -> void:
	# Mostra o total real de diamantes que o jogador acumulou
	label_diamantes.text = "x " + str(Global.total_diamantes) + " Diamantes Coletados"
	
	# Conecta os botões
	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)
	
	# Efeito de surgimento suave (Fade In)
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_play_again_pressed() -> void:
	# Reinicia o jogo do começo
	Global.total_diamantes = 0
	Global.resetar_status()
	Global.proxima_fase = "res://map/mapa01.tscn"
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")

func _on_main_menu_pressed() -> void:
	Global.resetar_status()
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

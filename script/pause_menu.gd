extends Control

@onready var btn_continuar: Button = $Continuar
@onready var btn_config: Button = $Config
@onready var btn_sair_menu: Button = $SairPMenu
@onready var btn_sair_jogo: Button = $SairJogo

func _ready() -> void:
	# Garante que ele responde mesmo quando o jogo estiver pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Começa escondido durante o jogo normal
	visible = false
	
	# Conecta os cliques dos botões
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_config.pressed.connect(_on_config_pressed)
	btn_sair_menu.pressed.connect(_on_sair_menu_pressed)
	btn_sair_jogo.pressed.connect(_on_sair_jogo_pressed)

func _input(event: InputEvent) -> void:
	# Detecta a tecla ESC diretamente (sem precisar configurar Input Map)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			alternar_pause()

func alternar_pause() -> void:
	var pausado = not get_tree().paused
	get_tree().paused = pausado
	visible = pausado

func _on_continuar_pressed() -> void:
	alternar_pause()

func _on_config_pressed() -> void:
	get_tree().paused = false
	Global.cena_origem = get_tree().current_scene.scene_file_path
	get_tree().change_scene_to_file("res://scenes/commands_screen.tscn")

func _on_sair_menu_pressed() -> void:
	get_tree().paused = false
	Global.resetar_status()
	get_tree().change_scene_to_file("res://scenes/mainMenu.tscn")

func _on_sair_jogo_pressed() -> void:
	get_tree().quit()

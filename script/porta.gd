extends Area2D

# Isso vai criar um campo no Inspetor para você arrastar a fase destino!
@export var mapa_destino: PackedScene

@onready var animacao_da_porta = $AnimationPlayer # Puxa o tocador da porta
var jogador_na_porta = null # Guarda quem encostou na porta
var porta_em_uso = false # Impede de apertar o botão duas vezes

func _process(delta: float) -> void:
	# Se o jogador está na porta, a porta não está sendo usada, e ele apertou "Cima" (ui_up)
	if jogador_na_porta != null and porta_em_uso == false:
		if Input.is_action_just_pressed("ui_up"):
			iniciar_cena_da_porta()

func iniciar_cena_da_porta():
	porta_em_uso = true 
	
	# 1. Toca a porta abrindo
	animacao_da_porta.play("opening")
	await animacao_da_porta.animation_finished 
	
	# 2. Manda o jogador travar e sumir (O Tween de 0.5 segundos começa aqui)
	jogador_na_porta.entrar_na_porta()
	
	# CORREÇÃO: Pede para a porta esperar exatamente 0.5 segundos
	await get_tree().create_timer(0.5).timeout 
	
	# 3. Toca a porta fechando
	animacao_da_porta.play("closing")
	await animacao_da_porta.animation_finished 
	
# 4. Avisa o Global qual é a fase que a tela de loading deve carregar
	Global.proxima_fase = mapa_destino.resource_path
	
	# 5. Manda para a tela de loading
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")
	
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player": # Certifique-se de que o nome do seu jogador na cena é "Player"
		jogador_na_porta = body

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		jogador_na_porta = null

func _on_area_exited(area: Area2D) -> void:
	pass # Replace with function body.

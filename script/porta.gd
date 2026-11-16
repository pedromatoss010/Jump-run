extends Area2D

# Marque como TRUE no Inspetor se esta porta for o ponto inicial onde o jogador nasce!
@export var porta_de_inicio: bool = false

# Arraste para cá a cena do mapa para onde esta porta deve levar (caso seja porta de saída)
@export var mapa_destino: PackedScene

@onready var animacao_da_porta: AnimationPlayer = $AnimationPlayer
@onready var aviso_label: Label = $AvisoLabel

var jogador_na_porta: Node2D = null
var porta_em_uso: bool = false

func _ready() -> void:
	# Garante que o aviso comece invisível
	if aviso_label != null:
		aviso_label.modulate.a = 0.0

	if porta_de_inicio:
		# Se for a porta onde o jogador começa a fase:
		animacao_da_porta.play("idle")
		call_deferred("executar_saida_do_player")

func _process(_delta: float) -> void:
	# Porta de saída: aperta para cima para entrar
	if not porta_de_inicio and jogador_na_porta != null and not porta_em_uso:
		if Input.is_action_just_pressed("inDoor"):
			iniciar_cena_da_porta()

# --- CONTROLE VISUAL DO BALÃOZINHO DE AVISO ---
func exibir_aviso(mostrar: bool) -> void:
	if aviso_label == null or porta_de_inicio:
		return
	var tween = create_tween()
	if mostrar and not porta_em_uso:
		tween.tween_property(aviso_label, "modulate:a", 1.0, 0.2)
	else:
		tween.tween_property(aviso_label, "modulate:a", 0.0, 0.2)

# --- SEQUÊNCIA DE SAÍDA (INÍCIO DA FASE) ---
func executar_saida_do_player() -> void:
	porta_em_uso = true
	var player = get_tree().get_first_node_in_group("player")
	
	if player != null:
		player.global_position = $Sprite2D.global_position
		player.controle_travado = true
		player.modulate.a = 0.0
		
		# 1. Abre a porta
		animacao_da_porta.play("opening")
		await animacao_da_porta.animation_finished
		
		# 2. Faz o jogador sair da porta
		player.sair_da_porta()
		await get_tree().create_timer(0.4).timeout
		
		# 3. Fecha a porta
		animacao_da_porta.play("closing")
		await animacao_da_porta.animation_finished
		animacao_da_porta.play("idle")
		
	porta_em_uso = false

# --- SEQUÊNCIA DE ENTRADA (FIM DA FASE) ---
func iniciar_cena_da_porta() -> void:
	if mapa_destino == null:
		print("Aviso: Nenhum mapa_destino configurado nesta porta!")
		return

	porta_em_uso = true
	exibir_aviso(false) # Some com o aviso ao usar a porta
	
	# 1. Porta abre
	animacao_da_porta.play("opening")
	await animacao_da_porta.animation_finished
	
	# 2. Centraliza o jogador na porta e toca animação de entrar
	if jogador_na_porta != null and jogador_na_porta.has_method("entrar_na_porta"):
		jogador_na_porta.global_position = $Sprite2D.global_position
		jogador_na_porta.entrar_na_porta()
	
	await get_tree().create_timer(0.6).timeout
	
	# 3. Porta fecha
	animacao_da_porta.play("closing")
	await animacao_da_porta.animation_finished
	animacao_da_porta.play("idle")
	
	# 4. Transição para a próxima fase
	Global.proxima_fase = mapa_destino.resource_path
	get_tree().change_scene_to_file("res://scenes/LoadingScreen.tscn")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		jogador_na_porta = body
		exibir_aviso(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		jogador_na_porta = null
		exibir_aviso(false)

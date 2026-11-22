extends StaticBody2D

# Configuração de Vida e Destruição
@export var vida: int = 2 # Quantidade de espadadas para quebrar

# Se verdadeiro: o canhão vira sozinho para onde o jogador estiver!
@export var seguir_jogador: bool = true
@export var direcao: int = -1

@export var intervalo_tiro: float = 2.5
@export var distancia_visao: float = 320.0
@export var sempre_atirar: bool = false
@export var cena_bala: PackedScene = preload("res://scenes/cannon_ball.tscn")

var player: Node2D = null
var destruido: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("inimigos") # Permite que a espada o reconheça
	atualizar_orientacao()
	if anim.has_animation("idle"):
		anim.play("idle")
	iniciar_ciclo_de_tiros()

func _process(_delta: float) -> void:
	if destruido:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	if seguir_jogador and is_instance_valid(player):
		var dist_x = player.global_position.x - global_position.x
		if abs(dist_x) > 10.0:
			direcao = 1 if dist_x > 0 else -1
			atualizar_orientacao()

func atualizar_orientacao() -> void:
	sprite.flip_h = (direcao > 0)

func iniciar_ciclo_de_tiros() -> void:
	while not destruido:
		await get_tree().create_timer(intervalo_tiro).timeout
		if destruido:
			break
		if deve_atirar():
			disparar()

func deve_atirar() -> bool:
	if destruido:
		return false
	if sempre_atirar:
		return true
	if not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= distancia_visao

func disparar() -> void:
	if destruido:
		return

	if anim.has_animation("shoot"):
		anim.play("shoot")
	
	await get_tree().create_timer(0.15).timeout
	if destruido:
		return

	if cena_bala:
		var bala = cena_bala.instantiate()
		var offset_boca = Vector2(direcao * 18, -2)
		bala.global_position = global_position + offset_boca
		bala.direcao = direcao
		get_tree().current_scene.add_child(bala)

	if anim.has_animation("shoot"):
		await anim.animation_finished
	
	if not destruido and anim.has_animation("idle"):
		anim.play("idle")

# É esta função que a sua espada chama ao acertar!
func tomar_dano(dano_recebido: int = 1) -> void:
	if destruido:
		return
	
	vida -= dano_recebido

	# Efeito de piscar em vermelho ao levar o golpe
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	if vida <= 0:
		destruir_canhao()

func destruir_canhao() -> void:
	destruido = true
	colisao.set_deferred("disabled", true) # Desativa a colisão sólida
	
	# Animação de colapso: o canhão tomba para trás e desaparece
	var tween = create_tween().set_parallel(true)
	# Leve recuo para cima e para o lado oposto ao golpe
	tween.tween_property(sprite, "position:y", sprite.position.y - 8, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation", -direcao * 0.8, 0.35)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.35).set_delay(0.1)

	await tween.finished
	queue_free()

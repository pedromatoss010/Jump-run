extends CharacterBody2D

enum Estado { VIGIANDO, PREPARANDO_PULO, NO_AR, DESPEDAÇANDO }

@export var distancia_ativacao: float = 140.0
@export var forca_pulo_y: float = -380.0
@export var velocidade_salto_x: float = 200.0 # Velocidade horizontal forte em direção ao player
@export var cena_porco_comum: PackedScene = preload("res://scenes/pig.tscn")

const PIECES = [
	preload("res://Assets/Sprites/08-Box/Box Pieces 1.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 2.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 3.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 4.png")
]

var estado: Estado = Estado.VIGIANDO
var direcao: int = -1
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: Node2D = null

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("inimigos")
	manter_olhando_para_fora()

func _physics_process(delta: float) -> void:
	if estado == Estado.DESPEDAÇANDO:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	match estado:
		Estado.VIGIANDO:
			# Sempre olha na direção do jogador enquanto vigia
			if is_instance_valid(player):
				var dist_x = player.global_position.x - global_position.x
				atualizar_orientacao(sign(dist_x))
				
				# Se o jogador entrar na distância de ativação, dispara o ataque!
				if global_position.distance_to(player.global_position) <= distancia_ativacao:
					preparar_salto()
			
			# Garante gravidade caso tenha sido colocado flutuando no mapa
			if not is_on_floor():
				velocity.y += gravidade * delta
				move_and_slide()

		Estado.PREPARANDO_PULO:
			# Fica parado no chão pegando impulso
			velocity.x = 0
			if not is_on_floor():
				velocity.y += gravidade * delta
			move_and_slide()

		Estado.NO_AR:
			# Aplica gravidade no pulo
			velocity.y += gravidade * delta
			
			if velocity.y > 0 and anim.has_animation("fall"):
				anim.play("fall")
				
			move_and_slide()
			
			# Se encostar no jogador em pleno voo, dá dano nele e quebra
			for i in range(get_slide_collision_count()):
				var col = get_slide_collision(i)
				var collider = col.get_collider()
				if collider == player and collider.has_method("tomar_dano"):
					collider.tomar_dano(1)
					despedacar_e_libertar_porco()
					return

			# MOMENTO MÁGICO: Ao aterrissar no chão, quebra sozinho!
			if is_on_floor():
				despedacar_e_libertar_porco()

func manter_olhando_para_fora() -> void:
	if anim.has_animation("Looking"):
		anim.play("Looking")

func atualizar_orientacao(nova_dir: int) -> void:
	if nova_dir == 0:
		return
	direcao = nova_dir
	# Se a imagem original olhar para a esquerda: flip_h inverte para a direita
	sprite.flip_h = (direcao > 0)

func preparar_salto() -> void:
	estado = Estado.PREPARANDO_PULO
	velocity = Vector2.ZERO

	# Garante a direção para onde o jogador está
	if is_instance_valid(player):
		var dist_x = player.global_position.x - global_position.x
		atualizar_orientacao(sign(dist_x))

	# Toca animação de se abaixar para saltar
	if anim.has_animation("jumpAnticipation"):
		anim.play("jumpAnticipation")
		await anim.animation_finished
	else:
		await get_tree().create_timer(0.2).timeout

	if estado == Estado.DESPEDAÇANDO:
		return

	# SALTO FORTE NA DIREÇÃO DO JOGADOR
	estado = Estado.NO_AR
	velocity.y = forca_pulo_y
	velocity.x = direcao * velocidade_salto_x

	if anim.has_animation("jump"):
		anim.play("jump")

# Se o jogador acertar um golpe com a espada na caixa
func tomar_dano(_dano: int = 1) -> void:
	if estado == Estado.DESPEDAÇANDO:
		return
	despedacar_e_libertar_porco()

func despedacar_e_libertar_porco() -> void:
	estado = Estado.DESPEDAÇANDO
	velocity = Vector2.ZERO
	colisao.set_deferred("disabled", true)
	sprite.visible = false

	# 1. Animação dos 4 pedaços de madeira voando
	explodir_pedacos_madeira()

	# 2. O Porco nasce no mesmo lugar já partindo pra cima!
	if cena_porco_comum:
		var porco = cena_porco_comum.instantiate()
		porco.global_position = global_position
		porco.direcao = direcao
		get_tree().current_scene.add_child(porco)

		if is_instance_valid(player):
			porco.player = player
			porco.estado = porco.Estado.ATACANDO

	await get_tree().create_timer(0.5).timeout
	queue_free()

func explodir_pedacos_madeira() -> void:
	var impulsos = [Vector2(-24, -28), Vector2(24, -28), Vector2(-14, -18), Vector2(14, -18)]
	for i in range(PIECES.size()):
		var pedaco = Sprite2D.new()
		pedaco.texture = PIECES[i]
		get_tree().current_scene.add_child(pedaco)
		pedaco.global_position = global_position

		var destino = global_position + impulsos[i] + Vector2(impulsos[i].x * 0.4, 28)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(pedaco, "position", destino, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pedaco, "rotation", randf_range(-3.0, 3.0), 0.4)
		tween.tween_property(pedaco, "modulate:a", 0.0, 0.35).set_delay(0.15)
		
		get_tree().create_timer(0.6).timeout.connect(pedaco.queue_free)

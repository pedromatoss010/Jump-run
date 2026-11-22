extends CharacterBody2D

enum Estado { PATRULHANDO, ARREMESSANDO, MORTO }

@export var vel_patrulha: float = 35.0
@export var alcance_visao: float = 240.0 # Alcance maior para avistar o player
@export var vida: int = 2
@export var cena_caixa_projetil: PackedScene = preload("res://scenes/box_projectile.tscn")
@export var cena_porco_comum: PackedScene = preload("res://scenes/pig.tscn")

var estado: Estado = Estado.PATRULHANDO
var direcao: int = -1
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var player: Node2D = null

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var colisao: CollisionShape2D = $CollisionShape2D

var sensor_chao: RayCast2D

func _ready() -> void:
	add_to_group("inimigos")
	atualizar_orientacao(direcao)
	anim.play("run")
	
	if has_node("SensorChao"):
		sensor_chao = $SensorChao

func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravidade * delta

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	match estado:
		Estado.PATRULHANDO:
			patrulhar()
			verificar_jogador()
		Estado.ARREMESSANDO:
			velocity.x = move_toward(velocity.x, 0, 10.0)

	move_and_slide()

func atualizar_orientacao(nova_dir: int) -> void:
	if nova_dir == 0:
		return
	direcao = nova_dir
	sprite.flip_h = (direcao > 0)

func patrulhar() -> void:
	if is_on_wall():
		atualizar_orientacao(-direcao)
	elif sensor_chao and not sensor_chao.is_colliding():
		atualizar_orientacao(-direcao)

	velocity.x = direcao * vel_patrulha
	if anim.current_animation != "run":
		anim.play("run")

func verificar_jogador() -> void:
	if not is_instance_valid(player):
		return

	var dist_x = player.global_position.x - global_position.x
	var dist_y = abs(player.global_position.y - global_position.y)

	# Se o jogador estiver no alcance horizontal e numa altura próxima
	if abs(dist_x) <= alcance_visao and dist_y < 100.0:
		atualizar_orientacao(sign(dist_x))
		arremessar_e_virar_porco_comum()

func arremessar_e_virar_porco_comum() -> void:
	estado = Estado.ARREMESSANDO
	velocity.x = 0
	anim.play("thowingBox")
	
	# Espera o frame exato em que ele projeta as mãos para frente
	await get_tree().create_timer(0.25).timeout
	if estado == Estado.MORTO:
		return
		
	# 1. CRIA E LANÇA A CAIXA NO AR
	if cena_caixa_projetil:
		var caixa = cena_caixa_projetil.instantiate()
		# Posição na altura do peito do porco para não encostar no chão ao nascer
		caixa.global_position = global_position + Vector2(direcao * 16, -18)
		get_tree().current_scene.add_child(caixa)
		caixa.lancar(Vector2(direcao, 0), 240.0, -200.0)

	# Espera a animação de arremesso terminar
	await anim.animation_finished
	if estado == Estado.MORTO:
		return

	# 2. TRANSFORMAÇÃO: CRIA O PORCO COMUM
	if cena_porco_comum:
		var porco = cena_porco_comum.instantiate()
		porco.global_position = global_position
		porco.direcao = direcao
		get_tree().current_scene.add_child(porco)
		
		# O porco comum já nasce perseguindo e atacando o jogador!
		if is_instance_valid(player):
			porco.player = player
			porco.estado = porco.Estado.ATACANDO

	# Remove o porco com caixa da cena
	queue_free()

func tomar_dano(dano_recebido: int) -> void:
	if estado == Estado.MORTO:
		return
	vida -= dano_recebido
	if vida <= 0:
		morrer()
		return
		
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	colisao.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()

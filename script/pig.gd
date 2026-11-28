extends CharacterBody2D

@export var vel_patrulha: float = 40.0
@export var vel_ataque: float = 90.0
@export var vida: int = 3
@export var cooldown_ataque: float = 0.5
@export var distancia_ataque: float = 20.0
@export var alcance_vertical_ataque: float = 40.0
@export var limite_altura_visao: float = 60.0

var direcao: int = -1
var gravidade: float = ProjectSettings.get_setting("physics/2d/default_gravity")

enum Estado { PATRULHANDO, ATACANDO, MORTO }
var estado: Estado = Estado.PATRULHANDO

var player: Node2D = null
var is_attacking: bool = false
var is_hit: bool = false
var pode_atacar: bool = true
var ataque_id: int = 0

@onready var visual: Node2D = $Visual
@onready var sensor_chao: RayCast2D = $Visual/SensorChao
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var hitbox: Area2D = $Visual/Hitbox_Inimigo
@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var area_visao: Area2D = $Visual/AreaDeVisao

func _ready() -> void:
	add_to_group("inimigos")
	atualizar_orientacao(direcao)
	hitbox.collision_mask = 3
	area_visao.collision_mask = 3

func _physics_process(delta: float) -> void:
	if estado == Estado.MORTO:
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += gravidade * delta

	# Se a referência do player não for mais válida (ex: morreu), volta a patrulhar
	if player != null and not is_instance_valid(player):
		resetar_para_patrulha()

	if is_hit:
		velocity.x = move_toward(velocity.x, 0, 10.0)
		move_and_slide()
		return

	match estado:
		Estado.PATRULHANDO:
			patrulhar()
		Estado.ATACANDO:
			if player != null and is_instance_valid(player):
				atacar()
			else:
				resetar_para_patrulha()

	move_and_slide()

func atualizar_orientacao(nova_direcao: int) -> void:
	if nova_direcao == 0:
		return
	direcao = nova_direcao
	visual.scale.x = abs(visual.scale.x) * -direcao

func patrulhar() -> void:
	if is_on_wall() or not sensor_chao.is_colliding():
		atualizar_orientacao(direcao * -1)

	velocity.x = direcao * vel_patrulha
	anim.play("run")

func atacar() -> void:
	var dist_x = player.global_position.x - global_position.x
	var dist_y = abs(player.global_position.y - global_position.y)
	var direcao_para_player = sign(dist_x)

	# Se o jogador foi para outra plataforma (muito acima ou abaixo), perde o foco e volta a patrulhar
	if dist_y > limite_altura_visao:
		resetar_para_patrulha()
		return

	if not is_attacking and direcao_para_player != 0 and direcao_para_player != direcao:
		atualizar_orientacao(direcao_para_player)

	# Só ataca se estiver a curta distância horizontal E na mesma altura (mesmo piso)
	if abs(dist_x) <= distancia_ataque and dist_y <= alcance_vertical_ataque:
		velocity.x = 0
		if pode_atacar and not is_attacking:
			iniciar_ataque()
		elif not is_attacking:
			anim.play("idle")
	elif not is_attacking:
		velocity.x = direcao * vel_ataque
		anim.play("run")

func iniciar_ataque() -> void:
	is_attacking = true
	pode_atacar = false
	ataque_id += 1
	var meu_ataque = ataque_id
	anim.play("attack")

	# Espera o frame de impacto do golpe
	await get_tree().create_timer(0.2).timeout
	if meu_ataque != ataque_id or estado == Estado.MORTO:
		return

	# Causa dano APENAS se o player estiver no alcance horizontal E na mesma altura
	if is_instance_valid(player):
		var dist_x = abs(player.global_position.x - global_position.x)
		var dist_y = abs(player.global_position.y - global_position.y)
		if dist_x <= distancia_ataque + 4 and dist_y <= alcance_vertical_ataque:
			if player.has_method("tomar_dano"):
				player.tomar_dano(1)

	# Espera terminar o resto da animação de ataque
	await anim.animation_finished
	if meu_ataque != ataque_id or estado == Estado.MORTO:
		return

	is_attacking = false

	# Intervalo antes de desferir o próximo golpe
	if cooldown_ataque > 0:
		await get_tree().create_timer(cooldown_ataque).timeout

	if meu_ataque == ataque_id and estado != Estado.MORTO:
		pode_atacar = true

func resetar_para_patrulha() -> void:
	player = null
	estado = Estado.PATRULHANDO
	is_attacking = false
	pode_atacar = true
	ataque_id += 1

func _eh_o_player(body: Node) -> bool:
	if body == self:
		return false
	return body.is_in_group("player") or body.name == "Player"

func _on_hit_box_inimigo_body_entered(body: Node2D) -> void:
	if _eh_o_player(body) and pode_atacar and not is_attacking and estado != Estado.MORTO:
		iniciar_ataque()

func tomar_dano(dano_recebido: int) -> void:
	if estado == Estado.MORTO:
		return

	vida -= dano_recebido
	ataque_id += 1
	is_attacking = false
	pode_atacar = true

	if vida <= 0:
		morrer()
		return

	# Reação a dano: piscar vermelho e leve knockback
	is_hit = true
	velocity.x = -direcao * 140
	velocity.y = -100

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	await tween.finished
	is_hit = false

func morrer() -> void:
	estado = Estado.MORTO
	velocity = Vector2.ZERO
	colisao.set_deferred("disabled", true)
	hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)

	var tween = create_tween()
	tween.tween_property(visual, "modulate", Color(1, 0, 0, 0), 0.35)
	await tween.finished
	queue_free()

func _on_area_de_visao_body_entered(body: Node2D) -> void:
	if _eh_o_player(body) and estado != Estado.MORTO:
		# Só foca no player se ele estiver em uma altura alcançável (mesmo andar/plataforma)
		if abs(body.global_position.y - global_position.y) <= limite_altura_visao:
			player = body
			estado = Estado.ATACANDO

func _on_area_de_visao_body_exited(body: Node2D) -> void:
	if _eh_o_player(body) and estado != Estado.MORTO:
		resetar_para_patrulha()

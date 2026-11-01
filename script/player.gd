extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var max_pulos: int = 2 
var pulos_dados: int = 0
var vida: int = 5
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual
@onready var sprite: Node2D = $Visual/Sprite2D 
@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var area_ataque: Area2D = $Visual/Hitbox_Ataque
@onready var hitbox_ataque: CollisionShape2D = $Visual/Hitbox_Ataque/CollisionShape2D

var is_dead: bool = false
var is_attacking: bool = false
var is_hit: bool = false
var controle_travado: bool = false
var invulneravel: bool = false

func _ready() -> void:
	add_to_group("player")
	hitbox_ataque.disabled = true
	area_ataque.collision_mask = 3
	vida = Global.vida_atual

func _physics_process(delta: float) -> void:
	# Aplica gravidade se não estiver no chão
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		pulos_dados = 0

	# Personagem morto
	if is_dead:
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	# Controle travado (ex: entrando em portas)
	if controle_travado:
		velocity.x = 0
		move_and_slide()
		return

	# Sofrendo dano (mantém gravidade)
	if is_hit:
		move_and_slide()
		return

	# Executando ataque
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	# Pulo (suporta pulo duplo)
	if Input.is_action_just_pressed("ui_accept"):
		if pulos_dados < max_pulos:
			velocity.y = jump_velocity
			pulos_dados += 1

	# Movimentação horizontal
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * speed
		visual.scale.x = abs(visual.scale.x) if direction > 0 else -abs(visual.scale.x)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# Ataque
	if Input.is_action_just_pressed("attack") and is_on_floor():
		attack()

	move_and_slide()
	update_animations(direction)

func update_animations(direction: float) -> void:
	if is_dead or is_hit or is_attacking:
		return

	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("ground")
	else:
		if direction != 0:
			play_animation("run")
		else:
			play_animation("idle")

func play_animation(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func attack() -> void:
	if is_attacking or not is_on_floor() or is_hit or is_dead:
		return

	is_attacking = true
	play_animation("attack")
	hitbox_ataque.disabled = false

	# Aplica dano imediatamente em quem já estiver na área
	causar_dano_nos_alvos()

	await animation_player.animation_finished

	hitbox_ataque.disabled = true
	is_attacking = false

func causar_dano_nos_alvos() -> void:
	for body in area_ataque.get_overlapping_bodies():
		if body != self and body.has_method("tomar_dano"):
			body.tomar_dano(1)

func tomar_dano(dano_recebido: int) -> void:
	if is_dead or invulneravel or controle_travado:
		return
	vida -= dano_recebido
	Global.alterar_vida(vida)

	if vida <= 0:
		morrer()
		return

	is_hit = true
	invulneravel = true
	is_attacking = false
	hitbox_ataque.disabled = true
	play_animation("hit")

	# Leve recuo (knockback)
	velocity.y = -220
	velocity.x = -visual.scale.x * 120

	# Efeito de piscar na invulnerabilidade
	var tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.3, 0.1)
	tween.tween_property(visual, "modulate:a", 1.0, 0.1)
	tween.set_loops(3)

	await animation_player.animation_finished
	is_hit = false

	await get_tree().create_timer(0.4).timeout
	invulneravel = false
	visual.modulate.a = 1.0

func morrer() -> void:
	is_dead = true
	is_attacking = false
	hitbox_ataque.disabled = true
	play_animation("dead")

	await animation_player.animation_finished
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func entrar_na_porta() -> void:
	controle_travado = true 
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)

func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	if body != self and is_attacking and body.has_method("tomar_dano"):
		body.tomar_dano(1)

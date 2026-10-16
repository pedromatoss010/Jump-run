extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var max_pulos = 2 
var pulos_dados = 0
var vida = 5
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var visual: Node2D = $Visual # NOVO NÓ AQUI
@onready var sprite: Node2D = $Visual/Sprite2D 
@onready var colisao = $CollisionShape2D

var is_dead: bool = false
var is_attacking: bool = false
var is_hit: bool = false
var controle_travado = false

func _ready() -> void:
	$Visual/Hitbox_Ataque/CollisionShape2D.disabled = true # Caminho atualizado

func _physics_process(delta: float) -> void:
	if controle_travado == true:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_dead:
		play_animation("dead")
		return

	if is_hit:
		play_animation("hit")
		return

	if is_attacking:
		play_animation("attack")
		move_and_slide()
		return

	if is_on_floor():
		pulos_dados = 0
	else:
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept"):
		if pulos_dados < max_pulos:
			velocity.y = jump_velocity
			pulos_dados += 1

	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		
		# A MÁGICA ACONTECE AQUI: Vira o nó Visual inteiro (Sprite + Hitbox juntas)
		visual.scale.x = abs(visual.scale.x) if direction > 0 else -abs(visual.scale.x)
			
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
	update_animations(direction)

func update_animations(direction: float) -> void:
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
	
	if Input.is_action_just_pressed("attack"):
		attack()

func play_animation(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func take_damage() -> void:
	is_hit = true
	play_animation("hit")
	await animation_player.animation_finished
	is_hit = false

func die() -> void:
	is_dead = true
	play_animation("dead")

func fail_level() -> void:
	play_animation("fail")

func attack() -> void:
	if not is_attacking and is_on_floor():
		is_attacking = true
		play_animation("attack")
		$Visual/Hitbox_Ataque/CollisionShape2D.disabled = false
		await animation_player.animation_finished
		$Visual/Hitbox_Ataque/CollisionShape2D.disabled = true
		is_attacking = false
		
func entrar_na_porta():
	controle_travado = true 
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)

func tomar_dano(dano_recebido: int):
	vida -= dano_recebido
	play_animation('hit')
	if vida <= 0:
		queue_free()

func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("tomar_dano"):
		body.tomar_dano(1)

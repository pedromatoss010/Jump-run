extends CharacterBody2D

var vel_patrulha = 40.0
var vel_ataque = 90.0
var vida = 3
var direcao = -1
var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

var estado = "PATRULHANDO"
var player = null
var is_attacking = false
var player_no_alcance = false
var ataque_id = 0

@onready var visual = $Visual
@onready var sensor_chao = $Visual/SensorChao
@onready var anim = $AnimationPlayer
@onready var sprite = $Visual/Sprite2D
@onready var hitbox = $Visual/Hitbox_Inimigo

func _ready() -> void:
	atualizar_orientacao(direcao)
	if not hitbox.body_entered.is_connected(_on_hit_box_inimigo_body_entered):
		hitbox.body_entered.connect(_on_hit_box_inimigo_body_entered)
	if not hitbox.body_exited.is_connected(_on_hit_box_inimigo_body_exited):
		hitbox.body_exited.connect(_on_hit_box_inimigo_body_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta

	if player != null and not is_instance_valid(player):
		resetar_para_patrulha()

	if estado == "PATRULHANDO":
		patrulhar()
	elif estado == "ATACANDO" and player != null:
		atacar()
	else:
		velocity.x = 0
		anim.play("idle")

	move_and_slide()

func atualizar_orientacao(nova_direcao: int):
	if nova_direcao == 0:
		return
	direcao = nova_direcao
	visual.scale.x = abs(visual.scale.x) * -direcao

func patrulhar():
	if is_on_wall() or not sensor_chao.is_colliding():
		atualizar_orientacao(direcao * -1)

	velocity.x = direcao * vel_patrulha
	anim.play("run")

func atacar():
	if is_attacking:
		velocity.x = 0
		return

	var direcao_para_player = sign(player.global_position.x - global_position.x)
	if direcao_para_player != 0 and direcao_para_player != direcao:
		atualizar_orientacao(direcao_para_player)

	if player_no_alcance:
		velocity.x = 0
		iniciar_ataque()
	else:
		velocity.x = direcao * vel_ataque
		anim.play("run")

func iniciar_ataque():
	is_attacking = true
	ataque_id += 1
	var meu_ataque = ataque_id
	anim.play("attack")

	await get_tree().create_timer(0.2).timeout
	if meu_ataque != ataque_id:
		return

	if is_instance_valid(player) and player in hitbox.get_overlapping_bodies():
		if player.has_method("tomar_dano"):
			player.tomar_dano(1)

	await anim.animation_finished
	if meu_ataque != ataque_id:
		return
	is_attacking = false

func resetar_para_patrulha():
	player = null
	player_no_alcance = false
	estado = "PATRULHANDO"
	is_attacking = false
	ataque_id += 1

# --- HITBOX (alcance do golpe) ---
func _eh_o_player(body: Node) -> bool:
	if body == self:
		return false
	return body.name == "Player" or body.is_in_group("player")

func _on_hit_box_inimigo_body_entered(body: Node2D) -> void:
	if _eh_o_player(body):
		player_no_alcance = true

func _on_hit_box_inimigo_body_exited(body: Node2D) -> void:
	if _eh_o_player(body):
		player_no_alcance = false

func tomar_dano(dano_recebido: int):
	vida -= dano_recebido
	if vida <= 0:
		queue_free()

# --- ÁREA DE VISÃO ---
func _on_area_de_visao_body_entered(body: Node2D) -> void:
	if _eh_o_player(body):
		player = body
		estado = "ATACANDO"

func _on_area_de_visao_body_exited(body: Node2D) -> void:
	if _eh_o_player(body):
		resetar_para_patrulha()

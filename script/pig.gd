extends CharacterBody2D

var vel_patrulha = 40.0
var vel_ataque = 90.0
var vida = 3
var direcao = -1
var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

var estado = "PATRULHANDO"
var player = null
var is_attacking = false

@onready var visual = $Visual # NOVO NÓ AQUI
@onready var sensor_chao = $Visual/SensorChao
@onready var anim = $AnimationPlayer
@onready var sprite = $Visual/Sprite2D

func _ready() -> void:
	atualizar_orientacao(direcao)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta

	if estado == "PATRULHANDO":
		patrulhar()
	elif estado == "ATACANDO" and player != null:
		atacar()
	else:
		velocity.x = 0
		anim.play("idle")

	move_and_slide()

# --- CONTROLE DE DIREÇÃO SIMPLIFICADO ---
func atualizar_orientacao(nova_direcao: int):
	if nova_direcao == 0:
		return
	direcao = nova_direcao
	# Inverte a Escala X do nó Visual. Tudo dentro dele gira junto.
	visual.scale.x = abs(visual.scale.x) * -direcao

# --- COMPORTAMENTOS ---
func patrulhar():
	if is_on_wall() or not sensor_chao.is_colliding():
		atualizar_orientacao(direcao * -1)

	velocity.x = direcao * vel_patrulha
	anim.play("run")

func atacar():
	if is_attacking:
		velocity.x = 0
		return

	var distancia = global_position.distance_to(player.global_position)
	var direcao_para_player = sign(player.global_position.x - global_position.x)

	if direcao_para_player != 0 and direcao_para_player != direcao:
		atualizar_orientacao(direcao_para_player)

	if distancia > 35.0: 
		velocity.x = direcao * vel_ataque
		anim.play("run")
	else:
		velocity.x = 0
		is_attacking = true
		anim.play("attack")
		
		# Espera um tempinho rápido (0.2s) para a mordida/espadada chegar no Player
		# (Você pode aumentar ou diminuir esse 0.2 se quiser sincronizar melhor com o visual)
		await get_tree().create_timer(0.2).timeout
		
		# Procura quem está dentro da caixa exatamente no frame do golpe
		var corpos_atingidos = $Visual/Hitbox_Inimigo.get_overlapping_bodies()
		for body in corpos_atingidos:
			if body.name == "Player" and body.has_method("tomar_dano"):
				body.tomar_dano(1)
		
		# Espera a animação inteira terminar para destravar o inimigo
		await anim.animation_finished
		is_attacking = false

func _on_hit_box_inimigo_body_entered(body: Node2D) -> void:
	pass

func tomar_dano(dano_recebido: int):
	vida -= dano_recebido
	if vida <= 0:
		queue_free()

func _on_area_de_visao_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		estado = "ATACANDO"

func _on_area_de_visao_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		estado = "PATRULHANDO"
		is_attacking = false

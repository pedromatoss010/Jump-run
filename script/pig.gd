extends CharacterBody2D

var vel_patrulha = 40.0
var vel_ataque = 90.0
var vida = 3 # Quantidade de golpes que ele aguenta
var direcao = -1 
var gravidade = ProjectSettings.get_setting("physics/2d/default_gravity")

var estado = "PATRULHANDO" 
var player = null

@onready var sensor_chao = $SensorChao
# Pegamos o nó de animação direto (mude o nome se o seu for diferente)
@onready var anim = $AnimationPlayer 
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravidade * delta

	# Controle de Estados
	if estado == "PATRULHANDO":
		patrulhar()
	elif estado == "ATACANDO" and player != null:
		atacar()
	else:
		# Se ele por algum motivo ficar sem alvo e sem patrulhar, fica parado
		velocity.x = 0
		anim.play("idle")

	move_and_slide()

# --- COMPORTAMENTOS ---

func patrulhar():
	if is_on_wall() or not sensor_chao.is_colliding():
		direcao = direcao * -1
		sprite.flip_h = not sprite.flip_h
		sensor_chao.position.x = sensor_chao.position.x * -1
		# Inverte a caixa de dano do inimigo também
		$Hitbox_Inimigo.position.x = $Hitbox_Inimigo.position.x * -1

	velocity.x = direcao * vel_patrulha
	
	# Tocando a animação de andar!
	anim.play("run") 


func atacar():
	# Descobre a distância entre o inimigo e o player
	var distancia = global_position.distance_to(player.global_position)
	var direcao_para_player = sign(player.global_position.x - global_position.x)
	
	# Vira o desenho, o sensor de chão e a caixa de ataque para olhar para o player
	if direcao_para_player > 0:
		sprite.flip_h = true 
		sensor_chao.position.x = abs(sensor_chao.position.x)
		$Hitbox_Inimigo.position.x = abs($Hitbox_Inimigo.position.x)
	elif direcao_para_player < 0:
		sprite.flip_h = false 
		sensor_chao.position.x = -abs(sensor_chao.position.x)
		$Hitbox_Inimigo.position.x = -abs($Hitbox_Inimigo.position.x)
		
	# A MÁGICA DA ANIMAÇÃO DE ATAQUE AQUI:
	if distancia > 35.0: # Se estiver a mais de 35 pixels, continua correndo
		velocity.x = direcao_para_player * vel_ataque
		anim.play("run")
	else:
		# Se chegou muito perto, ele freia e ataca!
		velocity.x = 0 
		anim.play("attack")


# --- COMBATE DO INIMIGO ---

func _on_hit_box_inimigo_body_entered(body: Node2D) -> void:
	# Quando a caixa de ataque do inimigo encosta no Player, tira a vida dele
	if body.name == "Player":
		if body.has_method("tomar_dano"):
			body.tomar_dano(1)

func tomar_dano(dano_recebido: int):
	vida -= dano_recebido
	
	# Se a vida zerar, ele morre e some do mapa
	if vida <= 0:
		queue_free()


# --- SENSORES DE VISÃO ---

func _on_area_de_visao_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		estado = "ATACANDO" 

func _on_area_de_visao_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		estado = "PATRULHANDO" 
		
		# Faz ele voltar a andar na direção que está olhando
		direcao = 1 if sprite.flip_h else -1

extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var max_pulos = 2 # O limite (2 = pulo duplo, 3 = pulo triplo...)
var pulos_dados = 0 # O contador que o jogo vai usar
var vida = 10
# Pega a gravidade das configurações do projeto (Project Settings)
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite2D 
@onready var colisao = $CollisionShape2D

# Variáveis de controle de estado
var is_dead: bool = false
var is_attacking: bool = false
var is_hit: bool = false

var controle_travado = false

func _physics_process(delta: float) -> void:
	# Se o player morreu ou está sofrendo animação bloqueante, trava o movimento comum
	if controle_travado == true:
		velocity = Vector2.ZERO # Faz ele parar no lugar
		move_and_slide()
		return # O return faz o código ignorar o resto (ele não anda nem pula)

	# ... (aqui continua o resto do seu código de movimento que já existe)
	
	if is_dead:
		play_animation("dead")
		return

	if is_hit:
		play_animation("hit")
		return

	if is_attacking:
		play_animation("attack")
		# Trava a movimentação básica durante o ataque (opcional)
		move_and_slide()
		return

	# 1. Adicionar a gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Tratar o Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		if is_on_floor():
			pulos_dados = 0 
			
		if pulos_dados < max_pulos:
			velocity.y = -470.0 # Aplica a força do pulo para cima (mude se precisar)
			pulos_dados += 1 # Adiciona +1 na conta de pulos dados

	# 3. Tratar a Direção e Movimentação (Esquerda / Direita)
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * speed
		
		# Inverte o sprite dependendo da direção que ele corre
		sprite.scale.x = abs(sprite.scale.x) if direction > 0 else -abs(sprite.scale.x)
		
		# O NOVO AJUSTE DA COLISÃO VEM AQUI:
		if direction > 0:
			# Indo para a direita (posição normal)
			colisao.position.x = 0 
			$Hitbox_Ataque.position.x = 10 # Adicione SÓ esta linha!
		else:
			# Indo para a esquerda (posição ajustada)
			colisao.position.x = +19 # Lembre de mudar esse número para o do seu jogo!
			$Hitbox_Ataque.position.x = -60 # Adicione SÓ esta linha!
			
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	# 4. Executar Movimento e Colisão
	move_and_slide()

	# 5. Atualizar Animações de Movimento baseadas no estado físico
	update_animations(direction)

func update_animations(direction: float) -> void:
	# Verifica se acabou de aterrissar (Ground) ou está pulando
	if not is_on_floor():
		if velocity.y < 0:
			play_animation("jump")
		else:
			play_animation("ground") # Ou queda/falling
	else:
		if direction != 0:
			play_animation("run")
		else:
			play_animation("idle")
	
	if Input.is_action_just_pressed("attack"):
		attack()

# Função auxiliar para evitar reiniciar a mesma animação repetidamente
func play_animation(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

# Exemplos de funções externas que você pode chamar por outros scripts (vida, inimigos, etc)
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
		await animation_player.animation_finished
		is_attacking = false
		
func entrar_na_porta():
	controle_travado = true 
	
	var tween = get_tree().create_tween()
	
	# Transforma a cor do jogador para Preto (sombra) e vai sumindo (Alpha 0)
	tween.tween_property(self, "modulate", Color(0, 0, 0, 0), 0.5)

func tomar_dano(dano_recebido: int):
	vida -= dano_recebido
	print("tomando dano")
	# Se a vida zerar, ele morre e some do mapa
	if vida <= 0:
		queue_free()

func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	# O Godot verifica: "A coisa em que eu bati tem a função tomar_dano?"
	if body.has_method("tomar_dano"):
		body.tomar_dano(1) # Manda 1 de dano para o inimigo!

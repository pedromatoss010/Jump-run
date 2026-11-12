extends StaticBody2D

# Carrega os 4 pedaços de madeira
const PIECES = [
	preload("res://Assets/Sprites/08-Box/Box Pieces 1.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 2.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 3.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 4.png")
]

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var anim = $AnimationPlayer

var quebrada: bool = false

func _ready() -> void:
	anim.play("idle")

# É esta função que o seu Eldrin chama sozinho ao bater!
func tomar_dano(dano_recebido: int = 1) -> void:
	if quebrada:
		return
	quebrada = true
	
	# Desativa a colisão sólida para o Eldrin poder passar
	collision.set_deferred("disabled", true)
	
	# Toca a animação de hit
	if anim.has_animation("hit"):
		anim.play("hit")
		await anim.animation_finished
	
	# Esconde a caixa inteira
	sprite.visible = false
	
	# Faz os 4 pedaços voarem
	explodir_pedacos()

func explodir_pedacos() -> void:
	# Vetores de lançamento (X espalha pros lados, Y faz o impulso pra cima)
	var impulsos = [
		Vector2(-22, -26), # Superior esquerdo (mais alto e longe)
		Vector2(22, -26),  # Superior direito
		Vector2(-14, -16), # Inferior esquerdo
		Vector2(14, -16)   # Inferior direito
	]
	
	for i in range(PIECES.size()):
		var pedaco = Sprite2D.new()
		pedaco.texture = PIECES[i]
		add_child(pedaco)
		
		# Define rotação aleatória suave
		var rot_final = randf_range(-2.5, 2.5)
		
		# Posição de pico (subida) e posição final no chão (queda)
		var pos_pico = impulsos[i]
		var pos_chao = pos_pico + Vector2(impulsos[i].x * 0.4, 38)
		
		var tween = create_tween()
		
		# Rotação suave durante toda a trajetória
		var rot_tween = create_tween()
		rot_tween.tween_property(pedaco, "rotation", rot_final, 0.6).set_trans(Tween.TRANS_SINE)
		
		# FASE 1: Subida suave (desacelerando no pico como a física real)
		tween.tween_property(pedaco, "position", pos_pico, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# FASE 2: Queda suave simulando gravidade
		tween.tween_property(pedaco, "position", pos_chao, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
		# Fade out suave apenas no finalzinho da queda
		var fade_tween = create_tween()
		fade_tween.tween_interval(0.35) # Espera voar um pouco antes de sumir
		fade_tween.tween_property(pedaco, "modulate:a", 0.0, 0.22)
	
	# Tempo total do efeito antes de limpar a caixa da memória
	await get_tree().create_timer(0.6).timeout
	queue_free()
	
	for i in range(PIECES.size()):
		var pedaco = Sprite2D.new()
		pedaco.texture = PIECES[i]
		add_child(pedaco)
		
		var tween = create_tween().set_parallel(true)
		var destino = impulsos[i] + Vector2(0, 24) # arco de queda
		
		# Move em arco
		tween.tween_property(pedaco, "position", destino, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Gira o pedaço
		tween.tween_property(pedaco, "rotation", randf_range(-3.0, 3.0), 0.4)
		# Some aos poucos (fade out)
		tween.tween_property(pedaco, "modulate:a", 0.0, 0.4)
	
	await get_tree().create_timer(0.45).timeout
	queue_free()

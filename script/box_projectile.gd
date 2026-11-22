extends Area2D

const PIECES = [
	preload("res://Assets/Sprites/08-Box/Box Pieces 1.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 2.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 3.png"),
	preload("res://Assets/Sprites/08-Box/Box Pieces 4.png")
]

@export var gravidade: float = 650.0
@export var velocidade_rotacao: float = 10.0

var velocidade: Vector2 = Vector2.ZERO
var explodiu: bool = false
var pode_colidir: bool = false

@onready var sprite = $Sprite2D
@onready var colisao = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Espera 0.05 segundos para se afastar do porco antes de permitir colisão com o cenário
	await get_tree().create_timer(0.05).timeout
	pode_colidir = true

func lancar(dir: Vector2, forca_x: float = 240.0, forca_y: float = -200.0) -> void:
	velocidade = Vector2(dir.x * forca_x, forca_y)

func _physics_process(delta: float) -> void:
	if explodiu:
		return
	
	velocidade.y += gravidade * delta
	global_position += velocidade * delta
	
	# Gira a caixa enquanto viaja pelo ar
	sprite.rotation += velocidade_rotacao * delta * sign(velocidade.x)

func _on_body_entered(body: Node2D) -> void:
	if explodiu or not pode_colidir:
		return
	
	# Ignora outros inimigos
	if body.is_in_group("inimigos"):
		return
		
	# Se acertou o jogador, causa dano
	if body.is_in_group("player") and body.has_method("tomar_dano"):
		body.tomar_dano(1)
		
	explodir()

func explodir() -> void:
	explodiu = true
	colisao.set_deferred("disabled", true)
	sprite.visible = false
	
	# Som de impacto (se o AudioManager estiver ativo)
	# AudioManager.tocar_sfx(som_quebrar)
	
	var impulsos = [Vector2(-20, -25), Vector2(20, -25), Vector2(-12, -15), Vector2(12, -15)]
	for i in range(PIECES.size()):
		var pedaco = Sprite2D.new()
		pedaco.texture = PIECES[i]
		add_child(pedaco)
		
		var destino = impulsos[i] + Vector2(impulsos[i].x * 0.4, 30)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(pedaco, "position", destino, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pedaco, "rotation", randf_range(-3.0, 3.0), 0.4)
		tween.tween_property(pedaco, "modulate:a", 0.0, 0.35).set_delay(0.15)
	
	await get_tree().create_timer(0.45).timeout
	queue_free()

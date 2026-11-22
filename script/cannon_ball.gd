extends Area2D

@export var velocidade: float = 240.0
var direcao: int = -1
var explodiu: bool = false

@onready var sprite = $Sprite2D
@onready var colisao = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Destrói a bala após 4 segundos para não voar para o infinito e pesar a memória
	get_tree().create_timer(4.0).timeout.connect(destruir_bala)

func _physics_process(delta: float) -> void:
	if explodiu:
		return
	
	# Move em linha reta na direção do canhão
	global_position.x += direcao * velocidade * delta

func _on_body_entered(body: Node2D) -> void:
	if explodiu:
		return

	# Não colide com canhões nem inimigos
	if body.is_in_group("inimigos") or body.name.to_lower().contains("cannon") or body.name.to_lower().contains("canhao"):
		return

	# Se acertou o jogador, causa dano
	if body.is_in_group("player") and body.has_method("tomar_dano"):
		body.tomar_dano(1)

	explodir()

func explodir() -> void:
	explodiu = true
	colisao.set_deferred("disabled", true)
	
	# Efeito suave de sumiço (ou animação de explosão se tiver)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	await tween.finished
	queue_free()

func destruir_bala() -> void:
	if not explodiu:
		queue_free()

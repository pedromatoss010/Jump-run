extends AnimatableBody2D

@onready var tilemap: TileMap = $TileMap
@onready var colisao: CollisionShape2D = $CollisionShape2D
@onready var sensor: Area2D = $Sensor

@export var tempo_aberto: float = 2.5
var acionado: bool = false
var pos_inicial_tilemap: Vector2

func _ready() -> void:
	pos_inicial_tilemap = tilemap.position
	sensor.body_entered.connect(_on_sensor_body_entered)

func _on_sensor_body_entered(body: Node2D) -> void:
	if not acionado and (body.is_in_group("player") or body.name == "Player"):
		# Trava o player para ter no máximo 1 pulo (remove o pulo duplo!)
		body.max_pulos = 1
		
		acionar_armadilha(body)

func acionar_armadilha(jogador: Node2D) -> void:
	acionado = true
	
	# 1. Tremidinha rápida de suspense (0.2s)
	var shake = create_tween()
	shake.tween_property(tilemap, "position:x", pos_inicial_tilemap.x + 2, 0.05)
	shake.tween_property(tilemap, "position:x", pos_inicial_tilemap.x - 2, 0.05)
	shake.tween_property(tilemap, "position:x", pos_inicial_tilemap.x, 0.05)
	await shake.finished
	
	# Garante novamente que enquanto estiver caindo não pode pular no ar
	if is_instance_valid(jogador):
		jogador.pulos_dados = jogador.max_pulos

	# 2. Desaba e desliga a colisão
	colisao.set_deferred("disabled", true)
	
	var desabar = create_tween().set_parallel(true)
	desabar.tween_property(tilemap, "position:y", pos_inicial_tilemap.y + 16, 0.2)
	desabar.tween_property(tilemap, "modulate:a", 0.0, 0.2)
	await desabar.finished

	# 3. Espera o tempo configurado com o chão aberto
	await get_tree().create_timer(tempo_aberto).timeout

	# 4. Reconstrói o chão no lugar
	tilemap.position = pos_inicial_tilemap
	var reconstruir = create_tween()
	reconstruir.tween_property(tilemap, "modulate:a", 1.0, 0.3)
	await reconstruir.finished
	
	colisao.set_deferred("disabled", false)
	
	# Devolve o pulo duplo normal
	if is_instance_valid(jogador):
		jogador.max_pulos = 2
		
	acionado = false

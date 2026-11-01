extends Camera2D

@export var suavizacao: float = 6.0
@export var distancia_olhar_a_frente: float = 40.0 # Quanto a câmera avança para onde o player olha

var player: CharacterBody2D = null

func _ready() -> void:
	# Ativa a suavização nativa com uma velocidade mais dinâmica
	position_smoothing_enabled = true
	position_smoothing_speed = suavizacao
	
	# Pega o nó pai (Player)
	player = get_parent() as CharacterBody2D
	
	# Ativa margens de arraste verticais (evita a câmera sacudir em pulos pequenos)
	drag_vertical_enabled = true
	drag_top_margin = 0.2
	drag_bottom_margin = 0.2

func _process(_delta: float) -> void:
	if player == null:
		return
		
	# Antecipação de visão horizontal (Lookahead):
	# Se o player estiver andando para a direita, a câmera olha um pouco para a direita
	# Se estiver andando para a esquerda, a câmera olha um pouco para a esquerda
	var direcao = Input.get_axis("move_left", "move_right")
	if direcao != 0:
		offset.x = move_toward(offset.x, direcao * distancia_olhar_a_frente, 1.5)
	else:
		# Se parado, volta suavemente para o centro
		offset.x = move_toward(offset.x, 0.0, 1.0)

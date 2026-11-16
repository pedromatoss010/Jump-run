extends CanvasLayer

@onready var coracoes_container: HBoxContainer = $ControlUI/CoracoesContainer
@onready var diamantes_label: Label = $ControlUI/DiamantesContainer/DiamantesLabel

# Textura do coração para instanciar ou ocultar
@export var textura_coracao: Texture2D = preload("res://Assets/Sprites/12-Live and Coins/Big Heart Idle (18x14).png")

func _ready() -> void:
	# Conecta aos sinais do Global
	Global.vida_alterada.connect(_on_vida_alterada)
	Global.diamantes_alterados.connect(_on_diamantes_alterados)
	
	# Atualiza o estado inicial
	_on_vida_alterada(Global.vida_atual)
	_on_diamantes_alterados(Global.total_diamantes)

func _on_vida_alterada(nova_vida: int) -> void:
	# Se você tiver 5 TextureRects dentro do CoracoesContainer:
	var coracoes = coracoes_container.get_children()
	for i in range(coracoes.size()):
		# Deixa visível apenas os corações até a vida atual
		coracoes[i].visible = (i < nova_vida)

func _on_diamantes_alterados(total: int) -> void:
	diamantes_label.text = "x " + str(total)

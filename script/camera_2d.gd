extends Camera2D

func _ready() -> void:
	# 1. Destrava a câmera para ela poder subir e descer (eixo Y livre)

	
	# 2. Ativa o movimento suave (para ela não ficar robótica)
	position_smoothing_enabled = true
	
	# Velocidade com que a câmera corre atrás do jogador (ajuste como preferir!)
	position_smoothing_speed = 2.0

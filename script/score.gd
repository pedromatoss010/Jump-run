extends Label

func _process(delta: float) -> void:
	# Atualiza o texto na tela a cada frame
	text = "Diamantes: " + str(Global.total_diamantes)

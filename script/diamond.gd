extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Adiciona +1 na conta lá do Global
		Global.total_diamantes += 1
		
		# Destrói o diamante
		queue_free()

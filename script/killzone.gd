extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("morrer"):
			Global.alterar_vida(0)
			body.morrer()

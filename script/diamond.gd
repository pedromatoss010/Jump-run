extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		Global.adicionar_diamante()
		queue_free()

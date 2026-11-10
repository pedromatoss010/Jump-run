extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

var coletado: bool = false

func _ready() -> void:
	if anim.has_animation("idle"):
		anim.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return
	if body.is_in_group("player") or body.name == "Player":
		coletado = true
		collision.set_deferred("disabled", true)
		Global.adicionar_diamante()
		
		# Toca a animação de coleta (brilho/hit)
		if anim.has_animation("hit"):
			anim.play("hit")
		
		# Efeito visual de subida suave com escala e fade out
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 12.0, 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(self, "scale", Vector2(1.25, 1.25), 0.1)
		tween.chain().tween_property(self, "scale", Vector2(0.5, 0.5), 0.12)
		tween.tween_property(self, "modulate:a", 0.0, 0.22)
		
		await tween.finished
		queue_free()

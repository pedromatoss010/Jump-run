extends Area2D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var collision: CollisionShape2D = $CollisionShape2D

@export_group("Efeitos Sonoros")
@export var som_cura: AudioStream

var coletado: bool = false

func _ready() -> void:
	if anim.has_animation("idle"):
		anim.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if coletado:
		return

	# Só coleta se for o player e se ele não estiver com a vida cheia
	if (body.is_in_group("player") or body.name == "Player") and Global.vida_atual < Global.max_vida:
		coletado = true
		print("Dentro")
		collision.set_deferred("disabled", true)
		
		# Recupera 1 de vida
		Global.alterar_vida(Global.vida_atual + 1)
		
		if som_cura:
			AudioManager.tocar_sfx(som_cura, -6.0)

		# Toca o efeito visual de estourar
		if anim.has_animation("hit"):
			anim.play("hit")

		# Sobe suavemente e desaparece
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 12.0, 0.22).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
		tween.chain().tween_property(self, "scale", Vector2(0.4, 0.4), 0.12)
		tween.tween_property(self, "modulate:a", 0.0, 0.22)

		await tween.finished
		queue_free()

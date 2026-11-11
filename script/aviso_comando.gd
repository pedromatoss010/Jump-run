extends Area2D

# Texto que você poderá alterar no Inspetor para cada aviso do mapa
@export_multiline var texto_aviso: String = "Comando aqui"

@onready var label: Label = $ComandoInicial

func _ready() -> void:
	if label != null:
		label.text = texto_aviso
		label.modulate.a = 0.0 # Começa invisível

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.2)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.2)

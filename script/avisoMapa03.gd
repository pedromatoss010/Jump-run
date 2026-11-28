extends Area2D

var fase_finalizada: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_ao_encostar_na_bandeira)

func _ao_encostar_na_bandeira(body: Node2D):
	if fase_finalizada:
		return
		
	if body.is_in_group("Player") or body.name == "Player":
		fase_finalizada = true
		exibir_tela_finalizacao(body)

func exibir_tela_finalizacao(body: Node2D) -> void:
	var camada_ui := CanvasLayer.new()
	camada_ui.layer = 100
	get_tree().current_scene.add_child(camada_ui)
	
	var fundo_preto := ColorRect.new()
	fundo_preto.color = Color(0.0, 0.0, 0.0, 0.0)	
	fundo_preto.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada_ui.add_child(fundo_preto)
	
	var texto := Label.new()
	texto.text = "Quem busca todo o diamante,
				 acaba enterrado com ele."
	texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	texto.set_anchors_preset(Control.PRESET_FULL_RECT)
	texto.modulate.a = 0.0
	
	texto.add_theme_font_size_override("font_size", 56)
	texto.add_theme_color_override("font_color", Color.WHITE)
	texto.add_theme_color_override("font_outline_color", Color.BLACK)
	texto.add_theme_constant_override("outline_size", 8)
	camada_ui.add_child(texto)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(fundo_preto, "color:a", 0.500, 0.10)
	tween.tween_property(texto, "modulate:a", 1.0, 1.6)
	
	await get_tree().create_timer(3.0).timeout
	Global.alterar_vida(0)
	body.morrer()
	

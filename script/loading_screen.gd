extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $LoadingLabel

var caminho_fase: String = ""
var progresso: Array = []
var tempo_minimo_passado: float = 0.0
const TEMPO_MINIMO: float = 0.8 # Pequena fração de segundo para a tela não apenas "piscar" se carregar instantâneo

func _ready() -> void:
	# Validação de segurança: se não tiver fase definida, vai para a fase 1
	caminho_fase = Global.proxima_fase
	if caminho_fase == "" or not ResourceLoader.exists(caminho_fase):
		caminho_fase = "res://map/mapa01.tscn"
		Global.proxima_fase = caminho_fase

	progress_bar.value = 0.0
	
	# Inicia o carregamento assíncrono em segundo plano na engine
	ResourceLoader.load_threaded_request(caminho_fase)
	
	# Efeito de Fade-In suave ao entrar na tela de loading
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _process(delta: float) -> void:
	tempo_minimo_passado += delta
	
	# Consulta o progresso real do carregamento na memória
	var status = ResourceLoader.load_threaded_get_status(caminho_fase, progresso)
	
	# Animação visual de reticências no texto ("Carregando.", "Carregando..", "Carregando...")
	var pontos = int(tempo_minimo_passado * 3) % 4
	label.text = "Carregando" + ".".repeat(pontos)
	
	if progresso.size() > 0:
		# Suaviza a barra até o valor real carregado
		var valor_real = progresso[0] * 100.0
		progress_bar.value = move_toward(progress_bar.value, valor_real, 150.0 * delta)

	# Quando o carregamento terminar E o tempo mínimo passar
	if status == ResourceLoader.THREAD_LOAD_LOADED and tempo_minimo_passado >= TEMPO_MINIMO:
		progress_bar.value = 100.0
		set_process(false)
		concluir_carregamento()
		
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		set_process(false)
		label.text = "Erro ao carregar fase!"
		print("Erro ao carregar: ", caminho_fase)

func concluir_carregamento() -> void:
	# Pega o recurso já compilado da memória (instantâneo)
	var nova_cena = ResourceLoader.load_threaded_get(caminho_fase) as PackedScene
	
	# Fade-Out suave antes de entrar na fase
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	get_tree().change_scene_to_packed(nova_cena)

extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $LoadingLabel

var elapsed_time: float = 0.0
const DURATION: float = 5.0 # 5 segundos da barra enchendo

func _process(delta: float) -> void:
	elapsed_time += delta
	var progress = clamp((elapsed_time / DURATION) * 100.0, 0.0, 100.0)
	progress_bar.value = progress
   
	if elapsed_time >= DURATION:
		set_process(false)
		# Quando a barra chegar em 100%, ele lê o Global e vai para a fase certa!
		get_tree().change_scene_to_file(Global.proxima_fase)

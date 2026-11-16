extends Node

# Player de áudio dedicado à música de fundo
var music_player: AudioStreamPlayer
var tween_musica: Tween

func _ready() -> void:
	# Mantém a música tocando mesmo se a árvore da cena for pausada
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cria o nó do AudioStreamPlayer via código
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master" # Caso crie um Bus "Music", mude o nome aqui
	add_child(music_player)

## Toca uma música de fundo com transição suave (fade-in)
func tocar_musica(stream: AudioStream, fade_tempo: float = 1.0) -> void:
	if stream == null:
		return
		
	# Se a mesma música já estiver tocando, não reinicia
	if music_player.stream == stream and music_player.playing:
		return

	# Cancela animações de volume anteriores
	if tween_musica and tween_musica.is_running():
		tween_musica.kill()

	if music_player.playing and fade_tempo > 0.0:
		# Faz fade-out da música anterior antes de iniciar a nova
		tween_musica = create_tween()
		tween_musica.tween_property(music_player, "volume_db", -80.0, fade_tempo / 2.0)
		await tween_musica.finished

	# Define a nova música e reseta o volume
	music_player.stream = stream
	music_player.volume_db = -80.0 if fade_tempo > 0.0 else 0.0
	music_player.play()

	# Faz o fade-in suave até o volume normal (0 dB)
	if fade_tempo > 0.0:
		tween_musica = create_tween()
		tween_musica.tween_property(music_player, "volume_db", -8.0, fade_tempo / 2.0)

## Para a música suavemente
func parar_musica(fade_tempo: float = 1.0) -> void:
	if not music_player.playing:
		return

	if tween_musica and tween_musica.is_running():
		tween_musica.kill()

	if fade_tempo > 0.0:
		tween_musica = create_tween()
		tween_musica.tween_property(music_player, "volume_db", -80.0, fade_tempo)
		await tween_musica.finished
		music_player.stop()
	else:
		music_player.stop()

## Toca um efeito sonoro temporário (SFX) sem interromper a música
func tocar_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_aleatorio: float = 0.0) -> void:
	if stream == null:
		return
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	if pitch_aleatorio > 0.0:
		sfx_player.pitch_scale = randf_range(1.0 - pitch_aleatorio, 1.0 + pitch_aleatorio)
	
	add_child(sfx_player)
	sfx_player.play()
	# Remove o nó da memória automaticamente ao terminar o som
	sfx_player.finished.connect(sfx_player.queue_free)

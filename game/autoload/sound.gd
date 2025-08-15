extends Node

func _ready() -> void:
	set_fx_ratio(0)
	set_noise(false)

func set_fx_ratio(ratio:float):
	$BGMFX.volume_linear = ratio
	$BGMNoFX.volume_linear = 1.0 - ratio

func set_noise(enabled:bool):
	$BGMFX.stream_paused = enabled
	$BGMNoFX.stream_paused = enabled
	$Noise.stream_paused = not enabled

func play_sfx(file_name:String):
	var path := str("res://game/sound/sfx/", file_name, ".ogg")
	if not FileAccess.file_exists(path):
		push_warning(str(file_name, ".ogg doesn't exist"))
	
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = load(path)
	player.play()
	player.pitch_scale = randf_range(0.57, (1.0 / 0.75))
	player.finished.connect(player.queue_free)

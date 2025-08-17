extends Node

func _ready() -> void:
	# order matters
	set_noise(0)
	set_fx_ratio(0)
	set_muted(false)

func set_fx_ratio(ratio:float):
	$BGMFX.set_volume_linear(ratio)
	$BGMNoFX.set_volume_linear(clamp($BGMNoFX.volume_linear - ratio, 0, 1))
	$Noise.set_volume_linear($Noise.volume_linear)

func set_noise(ratio:float):
	$BGMNoFX.set_volume_linear($BGMNoFX.volume_linear)
	$BGMFX.set_volume_linear(clamp($BGMFX.volume_linear - ratio, 0, 1))
	$Noise.set_volume_linear(ratio)

func set_muted(muted:bool):
	$BGMNoFX.stream_paused = muted
	$BGMFX.stream_paused = muted
	$Noise.stream_paused = muted
	#var music_bus_index := AudioServer.get_bus_index("Music")
	#AudioServer.set_bus_volume_linear(music_bus_index, 0 if muted else 1)

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
	player.bus = "SFX"

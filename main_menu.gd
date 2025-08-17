extends Control

func _ready() -> void:
	# order matters
	if GameMode.highest_unlocked_level == 0:
		call_deferred("start_story_mode")
	
	
	var number : int = randi_range(0, GameMode.highest_unlocked_level)
	var level_name : String = GameMode.LEVELS[number]
	$Background.texture = load("res://game/levels/%s/background.png" % level_name)
	Sound.set_noise(0)
	Sound.set_fx_ratio(0)
	Sound.set_muted(false)

func start_story_mode():
	GameMode.initialize_mode(GameMode.Mode.Story)
	get_tree().change_scene_to_packed(preload("res://main.tscn"))

func start_time_attack():
	GameMode.initialize_mode(GameMode.Mode.TimeAttack)
	get_tree().change_scene_to_packed(preload("res://main.tscn"))

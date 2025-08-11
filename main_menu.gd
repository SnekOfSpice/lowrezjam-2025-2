extends Control

func _ready() -> void:
	if GameMode.highest_unlocked_level == 0:
		call_deferred("start_story_mode")

func start_story_mode():
	GameMode.initialize_mode(GameMode.Mode.Story)
	get_tree().change_scene_to_packed(preload("res://main.tscn"))

func start_time_attack():
	GameMode.initialize_mode(GameMode.Mode.TimeAttack)
	get_tree().change_scene_to_packed(preload("res://main.tscn"))

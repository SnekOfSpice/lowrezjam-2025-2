extends Node2D

const LEVELS := [
	"utah"
]

var level : String
var level_counter := 0

var show_time_per_character := 0.04
var hide_time_per_character := 0.01

func _ready() -> void:
	%Notification.visible_characters = 0
	
	notify(["welcome", "lets play a game"], 2, place_level.bind(0))

func place_level(number:int):
	if number >= LEVELS.size():
		push_warning("Tried starting level %s but we only have %s levels" % [number, LEVELS.size()])
		return
	
	for child in %LevelContainer.get_children():
		child.queue_free()
	
	var level_path := "res://game/src/stencil/stencils/%s.tscn" % LEVELS[number]
	var instance : Stencil = load(level_path).instantiate()
	%LevelContainer.add_child(instance)
	instance.start_level.connect(start_level)
	
	notify(["MOUSE 2 CROSS"], 1)

func start_level():
	print("start")

var notification_tween
func notify(messages:Array, initial_delay:=0.0, callable_at_end:=Callable()):
	if notification_tween:
		notification_tween.kill()
	notification_tween = create_tween()
	for i in messages.size():
		var message : String = messages[i]
		if i == 0:
			notification_tween.tween_property(%Notification, "text", message, 0).set_delay(initial_delay)
		else:
			notification_tween.tween_property(%Notification, "text", message, 0).set_delay(1)
		notification_tween.tween_property(%Notification, "visible_characters", message.length(), message.length() * show_time_per_character)
		notification_tween.tween_property(%Notification, "visible_characters", 0, message.length() * hide_time_per_character).set_delay(4)
	
	if callable_at_end:
		notification_tween.finished.connect(callable_at_end)

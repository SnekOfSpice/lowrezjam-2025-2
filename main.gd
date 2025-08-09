extends Node2D

const LEVELS := [
	"utah"
]

## used for dev purposes
@export var skip_notifications := false

var level : String
var level_counter := 0
var level_started := false

var show_time_per_character := 0.04
var hide_time_per_character := 0.01

var goal_pixels := []
var hit_pixels := []

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
	var stencil : Stencil = load(level_path).instantiate()
	%LevelContainer.add_child(stencil)
	stencil.start_level.connect(on_stencil_start_level)
	stencil.start_level.connect(on_stencil_pixel_entered)
	
	goal_pixels.clear()
	hit_pixels.clear()
	for x in 64:
		for y in 64:
			var coord = Vector2(x, y)
			if stencil.is_pixel_opaque(coord):
				goal_pixels.append(Vector2i(coord))
	
	notify(["MOUSE 2 CROSS"], 1)
	level_started = false
	print(goal_pixels)

func on_stencil_pixel_entered(coord:Vector2i):
	if hit_pixels.has(coord):
		return
	hit_pixels.append(coord)
	goal_pixels.erase(coord)
	print(goal_pixels)
	if goal_pixels.is_empty():
		finish_level()

func finish_level():
	print("you win")

func get_current_stencil() -> Stencil:
	if %LevelContainer.get_child(0) is Stencil:
		return %LevelContainer.get_child(0)
	return null

func on_stencil_start_level():
	if level_started:
		return
	level_started = true
	print("start")

var notification_tween
func notify(messages:Array, initial_delay:=0.0, callable_at_end:=Callable()):
	if skip_notifications:
		if callable_at_end:
			callable_at_end.call()
		push_warning("toggle skip_notifications before exporting")
		return
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

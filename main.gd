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
var pixel_tracker := []
var hit_pixels := []

var accuracies := []
var time_taken := []

func _ready() -> void:
	%Notification.visible_characters = 0
	%NotifBacking.modulate.a = 0 
	notify(["welcome", "trace the line to win"], 2, place_level.bind(0))

func place_level(number:int):
	if number >= LEVELS.size():
		push_warning("Tried starting level %s but we only have %s levels" % [number, LEVELS.size()])
		return
	
	for child in %LevelContainer.get_children():
		child.queue_free()
	
	var level_name : String = LEVELS[number]
	var level_path := "res://game/src/stencil/stencils/%s.tscn" % level_name
	var stencil : Stencil = load(level_path).instantiate()
	%LevelContainer.add_child(stencil)
	stencil.position -= Vector2(32, 32)
	stencil.start_level.connect(on_stencil_start_level)
	stencil.entered_pixel.connect(on_stencil_pixel_entered)
	
	$Background.texture = load("res://game/images/backgrounds/%s.png" % level_name)
	
	goal_pixels.clear()
	pixel_tracker.clear()
	hit_pixels.clear()
	for x in 64:
		for y in 64:
			var coord = Vector2(x, y)
			if stencil.is_pixel_opaque(coord):
				goal_pixels.append(Vector2i(coord))
	pixel_tracker = goal_pixels.duplicate(true)
	
	notify([level_name], 1)
	level_started = false
	#print(goal_pixels)

var level_time := 0.0
func _process(delta: float) -> void:
	if level_started:
		level_time += delta
		
		
	
func on_stencil_pixel_entered(coord:Vector2i):
	if is_notifying:
		return
	if not level_started:
		return
	if hit_pixels.has(coord):
		prints("return from", coord)
		return
	place_pixel_at(coord)
func place_pixel_at(coord:Vector2i):
	hit_pixels.append(coord)
	pixel_tracker.erase(coord)
	
	var pixel = ColorRect.new()
	pixel.custom_minimum_size = Vector2.ONE
	var mat = ShaderMaterial.new()
	mat.shader = load("res://game/src/stencil/stencils/track.gdshader")
	pixel.material = mat
	%Paint.add_child(pixel)
	pixel.position = coord# + Vector2i(31,31)
	
	Sound.play_sfx("click")
	
	if pixel_tracker.is_empty():
		finish_level()

func finish_level():
	level_started = false
	get_current_stencil().set_physics_process(false)
	Sound.play_sfx("horn")
	
	# calculate results
	var missed_pixels := []
	var overdrawn_pixels := []
	var correct_pixels := []
	for hit in hit_pixels:
		if hit in goal_pixels:
			correct_pixels.append(hit)
		else:
			overdrawn_pixels.append(hit)
		
	for goal in goal_pixels:
		if not goal in hit_pixels:
			missed_pixels.append(goal)
	
	var base : float = float(correct_pixels.size()) / float(goal_pixels.size())
	var missed : float = float(missed_pixels.size()) / float(goal_pixels.size())
	var overdraw : float = float(overdrawn_pixels.size()) / float(goal_pixels.size())
	
	var accuracy := clampf(base - (missed * 0.5) - (overdraw * 0.5), 0, 1)
	accuracies.append(accuracies)
	time_taken.append(level_time)
	
	for marker : Node2D in %MarkerOverlay.get_children():
		marker.queue_free()
	
	notify([
		"Accuracy",
		str(int(accuracy * 100)),
		"Time",
		"%0.2f s" % level_time
	], 1, start_next_level)

func start_next_level():
	level_counter += 1
	if level_counter >= LEVELS.size():
		notify(["you finihsed the game", "avg acc.","total time taken"], 0, get_tree().quit)
		return
	place_level(level_counter)

func get_current_stencil() -> Stencil:
	if %LevelContainer.get_child(0) is Stencil:
		return %LevelContainer.get_child(0)
	return null

func on_stencil_start_level():
	if is_notifying:
		return
	if level_started:
		if hit_pixels.size() > 2:
			finish_level()
		return
	level_started = true
	Sound.play_sfx("start")
	get_current_stencil().visited_pixels.clear()
	place_pixel_at(get_current_stencil().get_start_coord())
	
	var dup = get_current_stencil().get_node("StartMarker").duplicate()
	%MarkerOverlay.add_child(dup)

var notification_tween
var is_notifying := false
func notify(messages:Array, initial_delay:=0.0, callable_at_end:=Callable()):
	await get_tree().process_frame
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
			notification_tween.set_parallel(true)
			notification_tween.tween_property(%NotifBacking, "modulate:a", 1, 0.5).set_delay(initial_delay)
			notification_tween.set_parallel(false)
		else:
			notification_tween.tween_property(%Notification, "text", message, 0).set_delay(1)
		notification_tween.tween_property(%Notification, "visible_characters", message.length(), message.length() * show_time_per_character)
		notification_tween.tween_property(%Notification, "visible_characters", 0, message.length() * hide_time_per_character).set_delay(4)
	
	notification_tween.set_parallel(true)
	notification_tween.tween_property(%NotifBacking, "modulate:a", 0, 0.5).set_delay(2)
	
	if callable_at_end:
		notification_tween.finished.connect(callable_at_end)
	notification_tween.finished.connect(set_is_notifying.bind(false))
	set_is_notifying(true)
	
func set_is_notifying(value:bool):
	is_notifying = value
	%MarkerOverlay.visible = not value

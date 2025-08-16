extends Node2D
 
const LEVELS := [
	"utah",
	"caledon",
	"redonda",
	"cathedral city fire station",
	"moraine lake",
	"oregon",
	"islamabad chand tara monument",
	"irkutsk",
	"santorini",
	"kiyomizu-dera",
	"pitt meadows",
	"albanian alps",
]

# optional array of lines to show at the start of the level
const LORE := {
	"islamabad" : ["im surprised the lights work"],
	"santorini" : ["the paint hasnt faded"],
	"pitt meadows" : ["why is it all is empty"],
	"albanian alps" : ["its all empty"],
}

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

const TIME_PER_LEVEL := 15.0
var time_left := TIME_PER_LEVEL

func _ready() -> void:
	%Notification.visible_characters = 0
	%NotifBacking.modulate.a = 0 
	%TimeAttackLabel.visible = GameMode.mode == GameMode.Mode.TimeAttack
	var welcome_messages : Array
	match GameMode.mode:
		GameMode.Mode.Story:
			welcome_messages = ["welcome", "trace the line to win", "pixels missed or off lower accuracy"]
		GameMode.Mode.TimeAttack:
			welcome_messages = ["time attack"]
			level_counter = randi_range(0, GameMode.highest_unlocked_level)
	notify(welcome_messages, 2, place_level.bind(level_counter))

func place_level(number:int):
	if number >= LEVELS.size():
		push_warning("Tried starting level %s but we only have %s levels" % [number, LEVELS.size()])
		return
	
	for child in %LevelContainer.get_children():
		child.queue_free()
	for child in %Paint.get_children():
		child.queue_free()
	
	var level_name : String = LEVELS[number]
	var level_path := "res://game/levels/%s/%s.tscn" % [level_name, level_name]
	var stencil : Stencil = load(level_path).instantiate()
	%LevelContainer.add_child(stencil)
	stencil.position -= Vector2(32, 32)
	stencil.start_level.connect(on_stencil_start_level)
	stencil.entered_pixel.connect(on_stencil_pixel_entered)
	
	$Background.texture = load("res://game/levels/%s/background.png" % level_name)
	
	goal_pixels.clear()
	pixel_tracker.clear()
	hit_pixels.clear()
	for x in 64:
		for y in 64:
			var coord = Vector2(x, y)
			if stencil.is_pixel_opaque(coord):
				goal_pixels.append(Vector2i(coord))
	pixel_tracker = goal_pixels.duplicate(true)
	
	var intro_messages := [level_name]
	intro_messages.append_array(LORE.get(level_name, []))
	notify(intro_messages, 1)
	level_started = false

var level_time := 0.0
func _process(delta: float) -> void:
	if level_started:
		level_time += delta
	
		if GameMode.mode == GameMode.Mode.TimeAttack:
			time_left -= delta
			if time_left <= 0:
				time_attack_death()
			%TimeAttackLabel.text = "%0.2f" % time_left
	

func get_total_time() -> float:
	if time_taken.is_empty():
		return 0.0
	var sum := 0.0
	for time in time_taken:
		sum += time
	sum += level_time
	return sum
func get_average_time() -> float:
	if time_taken.is_empty():
		return 0.0
	var sum := 0.0
	for acc in time_taken:
		sum += acc
	return sum / float(time_taken.size())
func get_average_accuracy() -> float:
	if accuracies.is_empty():
		return 0.0
	var sum := 0.0
	for acc in accuracies:
		sum += acc
	return sum / float(accuracies.size())

func time_attack_death():
	level_started = false
	get_current_stencil().set_physics_process(false)
	Sound.play_sfx("trumpet")
	
	notify(
		[
		"you never should've returned",
		str(accuracies.size()),
		"Avg Accuracy",
		get_average_accuracy(),
		"avg time",
		get_average_time(),
		], 3, go_to_main_menu
	)

func go_to_main_menu():
	get_tree().call_deferred("change_scene_to_packed", load("res://main_menu.tscn"))

func on_stencil_pixel_entered(coord:Vector2i):
	if is_notifying:
		return
	if not level_started:
		return
	if hit_pixels.has(coord):
		return
	place_pixel_at(coord)
func place_pixel_at(coord:Vector2i, closing_pixel := false):
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
	
	if pixel_tracker.is_empty() and not closing_pixel:
		finish_level()

func finish_level():
	place_pixel_at(Vector2i(get_current_stencil().get_local_mouse_position()), true)
	level_started = false
	get_current_stencil().set_physics_process(false)
	Sound.play_sfx("horn")
	
	if GameMode.mode == GameMode.Mode.Story:
		GameMode.highest_unlocked_level = max(level_counter, GameMode.highest_unlocked_level)
	
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
	
	var accuracy := clampf(base - max(missed, overdraw) / 2, 0, 1)
	accuracies.append(accuracies)
	time_taken.append(level_time)
	
	# only relevant for time attack
	var time_gained = accuracy * 1.33 * TIME_PER_LEVEL
	time_left += time_gained
	
	for marker : Node2D in %MarkerOverlay.get_children():
		marker.queue_free()
	
	var level_end_messages := [
		"Accuracy",
		str(int(accuracy * 100), " %"),
		"Time",
		"%0.2f s" % level_time
	]
	#if GameMode.mode == GameMode.Mode.Story:
		#level_end_messages
	if GameMode.mode == GameMode.Mode.TimeAttack:
		level_end_messages.append_array([
			"Time gained",
			"%0.2f s" % time_gained
		])
	
	notify(level_end_messages, 1, start_next_level)

func start_next_level():
	if GameMode.mode == GameMode.Mode.Story:
		level_counter += 1
		if level_counter >= LEVELS.size():
			notify(
				["perhaps I should leave this place too"
				]
				, 0,
			go_to_main_menu)
			return
	elif GameMode.mode == GameMode.Mode.TimeAttack:
		%TimeAttackLabel.text = "%0.2f" % time_left
		var prev_level_counter = level_counter
		var safety := 0
		while safety < 9999:
			level_counter = randi_range(0, GameMode.highest_unlocked_level)
			if level_counter != prev_level_counter:
				break
			safety += 1
	place_level(level_counter)

func get_current_stencil() -> Stencil:
	if %LevelContainer.get_child(0) is Stencil:
		return %LevelContainer.get_child(0)
	return null

func on_stencil_start_level():
	if is_notifying:
		return
	if level_started:
		if hit_pixels.size() > 5:
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


func _on_button_pressed() -> void:
	go_to_main_menu()

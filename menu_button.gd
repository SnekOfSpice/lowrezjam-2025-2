extends Label



@export var callable_on_selection : StringName
@export var callable_target_on_selection : Node

var progress_speed := 30.0

var is_mouse_in : bool
var called := false

func _process(delta: float) -> void:
	if is_mouse_in:
		%ProgressBar.value += delta * progress_speed
		if %ProgressBar.value == %ProgressBar.max_value and not called:
			called = true
			callable_target_on_selection.call(callable_on_selection)

func _on_mouse_entered() -> void:
	is_mouse_in = true


func _on_mouse_exited() -> void:
	called = false
	is_mouse_in = false
	%ProgressBar.value = 0

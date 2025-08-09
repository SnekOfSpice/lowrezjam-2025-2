extends Sprite2D
class_name Stencil

signal start_level

func _process(delta: float) -> void:
	if get_local_mouse_position() == $StartMarker.position:
		emit_signal("start_level")

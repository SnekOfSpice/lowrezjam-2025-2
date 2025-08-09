extends Sprite2D
class_name Stencil

signal start_level
signal entered_pixel(coord:Vector2i)

var visited_pixels := []

var last_pos := Vector2i(-100, -100)

func _process(delta: float) -> void:
	var mouse_pos := Vector2i(get_local_mouse_position())
	mouse_pos.x = clampi(mouse_pos.x, -31, 31)
	mouse_pos.y = clampi(mouse_pos.y, -31, 31)
	var marker_pos := Vector2i($StartMarker.position) + Vector2i.ONE # idk why but the ONE is necessary
	
	if mouse_pos == marker_pos:
		emit_signal("start_level")
	
	if last_pos != mouse_pos and not visited_pixels.has(mouse_pos):
		emit_signal("entered_pixel", mouse_pos)
		visited_pixels.append(mouse_pos)
		print("added" , mouse_pos)
	
	last_pos = mouse_pos
	printt(mouse_pos, marker_pos, visited_pixels.size())

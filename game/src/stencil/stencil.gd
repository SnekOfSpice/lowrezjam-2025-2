extends Sprite2D
class_name Stencil

signal start_level
signal entered_pixel(coord:Vector2i)

var visited_pixels := []

var last_pos := Vector2i(-100, -100)



func get_start_coord() -> Vector2i:
	return Vector2i($StartMarker.position)

func _physics_process(delta: float) -> void:#(delta: float) -> void:
	var mouse_pos := Vector2i(get_local_mouse_position())
	if mouse_pos.x < 0 or mouse_pos.x > 64:
		return
	if mouse_pos.y < 0 or mouse_pos.y > 64:
		return
	#mouse_pos.x = clampi(mouse_pos.x, -31, 31)
	#mouse_pos.y = clampi(mouse_pos.y, -31, 31)
	var marker_pos := Vector2i($StartMarker.position)# + Vector2i.ONE # idk why but the ONE is necessary
	
	if mouse_pos == marker_pos:
		emit_signal("start_level")
	
	if last_pos != mouse_pos and not visited_pixels.has(mouse_pos):
		emit_signal("entered_pixel", mouse_pos)
		visited_pixels.append(mouse_pos)
		#print("added" , mouse_pos)
	
	var dist = mouse_pos.distance_to(marker_pos)
	if dist <= 1:
		$StartMarker.modulate.a = 0.3
	elif dist <= 2:
		$StartMarker.modulate.a = 0.5
	elif dist <= 4:
		$StartMarker.modulate.a = 0.6
	elif dist <= 8:
		$StartMarker.modulate.a = 0.8
	else:
		$StartMarker.modulate.a = 1
	
	last_pos = mouse_pos
	#printt(mouse_pos, marker_pos, visited_pixels.size())

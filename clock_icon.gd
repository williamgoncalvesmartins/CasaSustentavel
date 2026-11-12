extends Control
func _draw() -> void:
	var ink := Color("#eaf5ef")
	draw_arc(Vector2(30.5,34), 18, 0, TAU, 64, ink, 3, true)
	draw_line(Vector2(30.5,34), Vector2(30.5,21), ink, 3, true)
	draw_line(Vector2(30.5,34), Vector2(40,39), ink, 3, true)
	draw_line(Vector2(25,8), Vector2(36,8), ink, 4, true)
	draw_line(Vector2(30.5,8), Vector2(30.5,15), ink, 3, true)
	draw_line(Vector2(44,16), Vector2(48,21), ink, 3, true)

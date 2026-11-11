extends Control

func _draw() -> void:
	var center := size / 2
	var points := PackedVector2Array()
	for i in range(48):
		var angle := i * TAU / 48.0
		var radius := 21.0 if i % 6 in [1, 2, 3, 4] else 16.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color("#eaf7f1"))
	draw_circle(center, 8, Color("#10242b"))

extends Control

var earned := false

func _draw() -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := -PI / 2.0 + i * PI / 5.0
		var radius := 12.0 if i % 2 == 0 else 5.5
		points.append(Vector2(15, 17) + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color("#f3d878") if earned else Color("#344b55"))
	points.append(points[0])
	draw_polyline(points, Color("#ffe99e") if earned else Color("#71848b"), 1.2, true)

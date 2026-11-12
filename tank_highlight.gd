extends Control

func _draw() -> void:
	var shapes := [PackedVector2Array([Vector2(343,303),Vector2(391,282),Vector2(480,277),Vector2(567,289),Vector2(613,307),Vector2(594,453),Vector2(366,453),Vector2(343,303)]), PackedVector2Array([Vector2(680,278),Vector2(750,251),Vector2(862,241),Vector2(965,254),Vector2(1040,282),Vector2(1014,453),Vector2(707,453),Vector2(680,278)])]
	for shape in shapes:
		draw_polyline(shape, Color(0.4,0.85,1,0.18), 12, true)
		draw_polyline(shape, Color(0.65,0.93,1,0.8), 2, true)

extends Control

var segments: Array = []
var error_segment: Array = []

func _draw() -> void:
	var paths := segments.duplicate()
	if not error_segment.is_empty():
		paths.append(error_segment)
	for pair in paths:
		var a := Vector2(209.4 + pair[0].x * 34.2, 126.65 + pair[0].y * 34.3)
		var b := Vector2(209.4 + pair[1].x * 34.2, 126.65 + pair[1].y * 34.3)
		var wrong: bool = pair == error_segment
		for layer in [[39.0, Color(1,0.2,0.2,0.18) if wrong else Color(0.25,1,0.55,0.12)], [33.0, Color("#ff8585") if wrong else Color("#66d892")], [29.0, Color("#9f303b") if wrong else Color("#286343")]]:
			draw_line(a, b, layer[1], layer[0], true)
			draw_circle(a, layer[0]/2, layer[1])
			draw_circle(b, layer[0]/2, layer[1])


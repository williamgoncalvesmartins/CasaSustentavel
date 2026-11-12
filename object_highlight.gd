extends Control
var challenge := 1
func _draw() -> void:
	var shapes: Array[PackedVector2Array] = []
	if challenge == 1:
		shapes = [PackedVector2Array([Vector2(220,378),Vector2(525,378),Vector2(525,407),Vector2(220,407),Vector2(220,378)]),PackedVector2Array([Vector2(690,378),Vector2(1080,378),Vector2(1080,407),Vector2(690,407),Vector2(690,378)])]
	else:
		shapes = [PackedVector2Array([Vector2(453,349),Vector2(585,349),Vector2(590,387),Vector2(600,523),Vector2(593,538),Vector2(443,538),Vector2(435,507),Vector2(447,376),Vector2(453,349)]),PackedVector2Array([Vector2(709,268),Vector2(897,268),Vector2(897,296),Vector2(905,324),Vector2(923,522),Vector2(914,539),Vector2(695,539),Vector2(687,519),Vector2(699,324),Vector2(708,295),Vector2(709,268)])]
	for shape in shapes:
		draw_polyline(shape,Color(0.4,0.85,1,0.18),12,true)
		draw_polyline(shape,Color(0.65,0.93,1,0.8),2,true)

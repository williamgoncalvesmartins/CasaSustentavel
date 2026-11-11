extends Control

var room := 0

func ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	draw_set_transform(center, 0, radius)
	draw_circle(Vector2.ZERO, 1, color)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var walls := [Color("#dcecf0"), Color("#f3ead8"), Color("#dcecd7")]
	draw_rect(Rect2(0, 0, 1364, 768), walls[room])
	draw_rect(Rect2(0, 560, 1364, 208), Color("#bcad91"))
	for x in range(0, 1364, 120):
		draw_line(Vector2(x,560), Vector2(x-140,768), Color("#a89980"), 2)
	draw_rect(Rect2(1040,190,260,270), Color("#65877d"))
	draw_rect(Rect2(1052,202,236,246), Color("#9cdbdf"))
	ellipse(Vector2(1180,420), Vector2(110,65), Color("#75b77d"))
	draw_line(Vector2(1170,202),Vector2(1170,448),Color("#f5f6e6"),8)
	draw_line(Vector2(1052,320),Vector2(1288,320),Color("#f5f6e6"),8)
	draw_rect(Rect2(60,510,92,90), Color("#b87550"))
	for i in range(5):
		var p := Vector2(105 + (i-2)*19, 420 + abs(i-2)*20)
		draw_line(Vector2(106,520),p,Color("#38734f"),6)
		ellipse(p, Vector2(24,48), Color("#56965c"))
	if room == 0:
		draw_rect(Rect2(205,540,835,24), Color("#b48a5b"))
		for i in range(2):
			var x := 270.0 + i*430
			var w := 250.0 + i*65
			var h := 220.0 + i*65
			ellipse(Vector2(x+w/2,553),Vector2(w/2+10,15),Color(0,0,0,0.15))
			draw_rect(Rect2(x,540-h,w,h),Color("#235b89"))
			for n in range(3):
				draw_line(Vector2(x,540-h+55+n*60),Vector2(x+w,540-h+55+n*60),Color("#18466e"),8)
			ellipse(Vector2(x+w/2,540-h),Vector2(w/2+8,27),Color("#347eab"))
			ellipse(Vector2(x+w/2,531),Vector2(w/2,12),Color("#18466e"))
	elif room == 1:
		draw_rect(Rect2(200,548,840,70),Color("#749b8d"))
		draw_rect(Rect2(190,534,860,18),Color("#ead4ab"))
		for i in range(2):
			var x := 260.0+i*425
			var w := 210.0+i*130
			draw_rect(Rect2(x,370,w,28),Color("#be8955"))
			draw_rect(Rect2(x+24,398,18,65),Color("#5d776e"))
			draw_rect(Rect2(x+w-42,398,18,65),Color("#5d776e"))
			for n in range(3):
				draw_rect(Rect2(x+30+n*53,315,34,55),Color("#c8dfc4"))
				draw_rect(Rect2(x+27+n*53,309,40,10),Color("#5c8b73"))
	else:
		for i in range(2):
			var x := 285.0+i*430
			var w := 200.0+i*70
			var h := 190.0+i*70
			var points := PackedVector2Array([Vector2(x,540),Vector2(x-12,500),Vector2(x+25,540-h+40),Vector2(x+40,540-h),Vector2(x+w-40,540-h),Vector2(x+w-25,540-h+40),Vector2(x+w+12,500),Vector2(x+w,540)])
			draw_colored_polygon(points,Color("#c7a16c"))
			draw_line(Vector2(x+40,540-h+20),Vector2(x+w-40,540-h+20),Color("#79603e"),8)
			ellipse(Vector2(x+w/2,445),Vector2(45,55),Color("#528552"))

extends Control

func _draw() -> void:
	var amber := Color("efbd70")
	var dim := Color("809b90")
	for row in 5:
		var width := 2.0 + row * 2.0
		draw_rect(Rect2(16 - width / 2.0, 4 + row * 2, width, 2), amber)
	for row in 4:
		var width := 8.0 - row * 2.0
		draw_rect(Rect2(16 - width / 2.0, 16 + row * 2, width, 2), dim)

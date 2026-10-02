extends Control
## Original nautical mark and repair milestones, drawn on a two-pixel grid.

var repair_stage := 0
var rescued := false

func set_progress(stage: int, won: bool) -> void:
	if stage != repair_stage or won != rescued:
		repair_stage = stage
		rescued = won
		queue_redraw()

func _draw() -> void:
	var amber := Color("efbd70")
	var pale := Color("edf0dc")
	var dim := Color("48615c")
	# Lantern, roof, tapered masonry and the beam: the game's own landmark.
	draw_rect(Rect2(12, 2, 8, 2), pale)
	draw_rect(Rect2(10, 4, 12, 2), pale)
	draw_rect(Rect2(12, 6, 8, 6), amber if repair_stage == 3 else dim)
	draw_rect(Rect2(10, 12, 12, 2), pale)
	draw_rect(Rect2(12, 14, 8, 6), pale)
	draw_rect(Rect2(10, 20, 12, 4), pale)
	draw_rect(Rect2(8, 24, 16, 2), pale)
	draw_rect(Rect2(14, 20, 4, 6), Color("142c32"))
	if rescued:
		draw_rect(Rect2(24, 8, 8, 2), amber)
		draw_rect(Rect2(2, 8, 6, 2), amber)
	for index in 3:
		var x := 48.0 + index * 36.0
		draw_rect(Rect2(x, 10, 24, 10), dim)
		draw_rect(Rect2(x + 2, 12, 20, 6), amber if index < repair_stage else Color("142c32"))
		if index < 2:
			draw_rect(Rect2(x + 26, 14, 8, 2), dim)

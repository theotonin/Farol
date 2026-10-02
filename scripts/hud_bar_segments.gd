extends Control
## Pixel dividers preserve the exact underlying life/stamina bar values.

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	for index in range(1, 10):
		var x := floorf(size.x * index / 10.0)
		draw_rect(Rect2(x, 0, 2, size.y), Color("142c32"))

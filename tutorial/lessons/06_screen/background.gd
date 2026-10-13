extends Control


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101c30"))
	for x in range(0, int(size.x), 40):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("36526c"), 2)
	for y in range(0, int(size.y), 40):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("36526c"), 2)
	draw_rect(Rect2(size * Vector2(0.24, 0.35), size * Vector2(0.11, 0.5)), Color("d19744"))
	draw_circle(size * Vector2(0.65, 0.63), 90, Color("348c9c"))
	draw_line(size * Vector2(0.2, 0.88), size * Vector2(0.85, 0.38), Color("e6dfb1"), 8)

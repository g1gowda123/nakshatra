class_name StarPip
extends Control
## A tiny five-point star drawn in code — no font or SVG dependency.

var filled := true
var pip_color: Color = Color("d9b36c")
var pip_size := 12.0


func _ready() -> void:
	custom_minimum_size = Vector2(pip_size, pip_size)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(is_filled: bool, color: Color, px: float) -> void:
	filled = is_filled
	pip_color = color
	pip_size = px
	custom_minimum_size = Vector2(px, px)
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size * 0.5
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + i * PI / 5.0
		var r := s * 0.5 if i % 2 == 0 else s * 0.21
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	if filled:
		draw_colored_polygon(pts, pip_color)
	else:
		var outline := pts.duplicate()
		outline.append(pts[0])
		draw_polyline(outline, Color(pip_color, 0.45), maxf(1.0, s * 0.09), true)

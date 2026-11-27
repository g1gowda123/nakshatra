class_name ProgressPip
extends Control
## A lantern pip: a small diamond, filled when lit, ringed when next.

var filled := false
var current := false
var pip_color: Color = Color("d9b36c")
var pip_size := 9.0


func _ready() -> void:
	custom_minimum_size = Vector2(pip_size + 2.0, pip_size + 2.0)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(is_filled: bool, is_current: bool, color: Color, px: float) -> void:
	filled = is_filled
	current = is_current
	pip_color = color
	pip_size = px
	custom_minimum_size = Vector2(px + 2.0, px + 2.0)
	queue_redraw()


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 1.0:
		return
	var c := size * 0.5
	var r := s * 0.36
	var pts := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0),
	])
	if filled:
		draw_colored_polygon(pts, pip_color)
	else:
		var outline := pts.duplicate()
		outline.append(pts[0])
		var col := Color(pip_color, 0.9) if current else Color(pip_color, 0.32)
		draw_polyline(outline, col, maxf(1.0, s * 0.11), true)

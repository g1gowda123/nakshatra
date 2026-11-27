class_name FinaleHorizon
extends Control
## A paper-cut festival horizon for the finale: two ink hills, a thread of warm
## light, and the small lanterns of the town below. Purely 2D, drawn once.

var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return
	var base := h * 0.84

	# Warm haze: a stack of translucent bands, brightest at the ridge.
	for i in 16:
		var t := float(i) / 16.0
		var y := base - h * 0.26 * (1.0 - t)
		var a := 0.010 + t * 0.022
		draw_rect(Rect2(0, y, w, h * 0.020), Color(1.0, 0.62, 0.30, a))

	# Far ridge: a slow, breathing line of ink.
	var far := PackedVector2Array()
	far.append(Vector2(0, base))
	for i in 25:
		var x := w * float(i) / 24.0
		var y := base - h * 0.095 - sin(float(i) * 0.62) * h * 0.026 - sin(float(i) * 1.7) * h * 0.010
		far.append(Vector2(x, y))
	far.append(Vector2(w, base))
	draw_colored_polygon(far, Color(0.035, 0.055, 0.067, 0.97))
	# A thin gilt edge catches the festival light.
	for i in far.size() - 2:
		draw_line(far[i], far[i + 1], Color(0.95, 0.72, 0.42, 0.28), 1.0)

	# Near ridge, darker and lower, with a handful of town lanterns.
	var near := PackedVector2Array()
	near.append(Vector2(0, h))
	for i in 19:
		var x := w * float(i) / 18.0
		var y := base + h * 0.018 - sin(float(i) * 0.9 + 1.2) * h * 0.040 - cos(float(i) * 0.43) * h * 0.016
		near.append(Vector2(x, y))
	near.append(Vector2(w, h))
	draw_colored_polygon(near, Color(0.020, 0.032, 0.040, 1.0))

	for i in 19:
		var x := w * (0.03 + 0.94 * float(i) / 18.0) + sin(float(i) * 2.1) * 8.0
		var y := base - h * 0.060 - sin(float(i) * 0.9 + 1.2) * h * 0.032
		var pulse := 0.55 + 0.12 * sin(_t * 1.4 + float(i) * 1.7)
		draw_circle(Vector2(x, y), 9.0, Color(1.0, 0.66, 0.34, 0.06 * pulse))
		draw_circle(Vector2(x, y), 2.6, Color(1.0, 0.80, 0.50, 0.66 * pulse))

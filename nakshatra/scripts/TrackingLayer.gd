extends Control
## A camera-tracking overlay: corner brackets, confidence labels and a pointer
## readout. It is decorative, but it makes every movement and selection feel
## observed. Coordinates are normalized so the boxes survive a resize.

var targets: Array = []
var accent := Color("c6ff00")
var _mouse := Vector2(-100, -100)
var _inside := false
var _active := false
var _last_motion := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_targets(list: Array) -> void:
	targets = list
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_active = true
		_last_motion = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var m := get_local_mouse_position()
	if m != _mouse:
		_mouse = m
		_inside = Rect2(Vector2.ZERO, size).has_point(m)
		queue_redraw()
	if _active and Time.get_ticks_msec() - _last_motion > 1600:
		_active = false
		queue_redraw()


func _draw() -> void:
	if size.x < 60.0 or size.y < 60.0 or UI.is_compact():
		return
	var font := UI.mono_font()
	for t in targets:
		var r: Rect2 = t.get("rect", Rect2(0, 0, 0, 0))
		var box := Rect2(Vector2(r.position.x * size.x, r.position.y * size.y), Vector2(r.size.x * size.x, r.size.y * size.y))
		var col: Color = t.get("color", accent)
		_corner_box(box, col, 1.5)
		var label := str(t.get("label", "01 / OBJECT"))
		var lx := box.position.x
		var ly := maxf(10.0, box.position.y - 8.0)
		_draw_label(font, Vector2(lx, ly), label, col)
	if _active and _inside and not UI.is_compact():
		var c := _mouse
		draw_line(c + Vector2(-10, 0), c + Vector2(10, 0), Color(accent, 0.55), 1.0)
		draw_line(c + Vector2(0, -10), c + Vector2(0, 10), Color(accent, 0.55), 1.0)
		_draw_label(font, c + Vector2(14, -8), "X %03d  Y %03d" % [int(c.x), int(c.y)], Color(accent, 0.65))


func _corner_box(box: Rect2, col: Color, w: float) -> void:
	var l := minf(16.0, minf(box.size.x, box.size.y) * 0.28)
	var c := Color(col, 0.9)
	for pair in [
		[box.position, Vector2(1, 0), Vector2(0, 1)],
		[box.position + Vector2(box.size.x, 0), Vector2(-1, 0), Vector2(0, 1)],
		[box.position + Vector2(0, box.size.y), Vector2(1, 0), Vector2(0, -1)],
		[box.position + box.size, Vector2(-1, 0), Vector2(0, -1)],
	]:
		var p: Vector2 = pair[0]
		var dx: Vector2 = pair[1]
		var dy: Vector2 = pair[2]
		draw_line(p, p + dx * l, c, w)
		draw_line(p, p + dy * l, c, w)


func _draw_label(font: Font, p: Vector2, text: String, col: Color) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_rect(Rect2(p + Vector2(-3, -10), Vector2(w + 6, 13)), Color(0.02, 0.02, 0.02, 0.8), true)
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, col)

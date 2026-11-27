extends CanvasLayer
## The reaction layer: every press gets a spark, every result gets a stamp.
## Nothing here blocks input; it is pure feedback on top of the current scene.

const SPARK_LIFE := 0.38

var _root: Control
var _toast_box: VBoxContainer
var _last_mouse := Vector2.ZERO
var _trail_cd := 0.0


class Spark extends Control:
	var color := Color.WHITE
	var life := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(64, 64)
		size = Vector2(64, 64)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _draw() -> void:
		var c := Vector2(32, 32)
		var t := clampf(life / 0.38, 0.0, 1.0)
		for i in 8:
			var a := TAU * float(i) / 8.0 + 0.35
			var r0 := 5.0 + 22.0 * t
			var r1 := r0 + 9.0 * (1.0 - t)
			draw_line(c + Vector2(cos(a), sin(a)) * r0, c + Vector2(cos(a), sin(a)) * r1, Color(color, 1.0 - t), 2.0, true)
		draw_circle(c, 3.5 * (1.0 - t), Color(color, 1.0 - t))

	func _process(delta: float) -> void:
		life += delta
		queue_redraw()
		if life >= 0.38:
			queue_free()


func _ready() -> void:
	layer = 200
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UI.theme()
	add_child(_root)
	_toast_box = VBoxContainer.new()
	_toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_box.offset_top = 88
	_toast_box.offset_left = -320
	_toast_box.offset_right = 320
	_toast_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_box.add_theme_constant_override("separation", 6)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toast_box)


func _process(delta: float) -> void:
	if G.reduced_motion or UI.is_compact() or _root == null:
		return
	var m := get_viewport().get_mouse_position()
	_trail_cd -= delta
	if m.distance_to(_last_mouse) > 26.0 and _trail_cd <= 0.0:
		_last_mouse = m
		_trail_cd = 0.09
		var s := Spark.new()
		s.color = G.GOLD
		s.position = m - Vector2(32, 32)
		s.scale = Vector2(0.34, 0.34)
		s.modulate.a = 0.32
		_root.add_child(s)


func burst(pos: Vector2, color: Color = G.GOLD) -> void:
	if G.reduced_motion:
		return
	var s := Spark.new()
	s.color = color
	s.position = pos - Vector2(32, 32)
	_root.add_child(s)


func stamp(text: String, color: Color = G.GOLD, fg: Color = G.INK, hold: float = 0.9) -> void:
	## A short, loud result card. It replaces the old quiet feedback line for
	## actions that deserve a beat: a completed phase, a right answer, a lantern.
	if text.strip_edges() == "":
		return
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = G.INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(5, 5)
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", UI.display_font())
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", fg)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.rotation = deg_to_rad(-1.2)
	p.pivot_offset = Vector2(160, 24)
	p.modulate.a = 0.0
	p.scale = Vector2(0.8, 0.8) if not G.reduced_motion else Vector2.ONE
	_toast_box.add_child(p)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "modulate:a", 1.0, 0.12)
	if not G.reduced_motion:
		tw.tween_property(p, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(hold)
	tw.chain().tween_property(p, "modulate:a", 0.0, 0.22)
	tw.chain().tween_callback(p.queue_free)

extends Control
## A bonus sky note: why the Moon does not eclipse every month.
## One tilted orbit, one shadow, one slider. No new lantern — this is revision
## for the Moon exhibit and a Field Guide destination.

const SUN_COLOR := Color("ffd23f")

var mode := "solar"          # solar | lunar
var tilt := 4.0
var _was_hit := false
var _solved := false
var _diagram: Control
var _panel: PanelContainer
var _solar_btn: Button
var _lunar_btn: Button
var _tilt_label: Label
var _status: Label
var _detail: Label
var _prompt: Label
var _panel_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.theme()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	if OS.get_cmdline_user_args().has("--eclipse-align"):
		tilt = 0.0
		_update_state.call_deferred()
	if OS.get_cmdline_user_args().has("--eclipse-lunar"):
		mode = "lunar"
		tilt = 0.0
		_update_state.call_deferred()


func _copy(key: String, fallback: String) -> String:
	var e: Dictionary = G.content.get("eclipse", {})
	return str(e.get(key, fallback))


func _build_ui() -> void:
	for c in get_children():
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = G.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var stars := SkyBackdrop.new()
	stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stars)
	add_child(UI.print_frame(16))

	var outer := UI.margin(UI.pad() + 4, 18, UI.pad() + 4, 14)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(outer)
	var col := UI.vbox(0)
	outer.add_child(col)
	var acts: Array = [{"text": "PHASES", "fn": func(): Router.go("res://scenes/MoonLab.tscn")}]
	col.add_child(UI.app_bar("Eclipses", "SHADOW GEOMETRY  ·  WHY THEY ARE RARE", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB"))

	var body: BoxContainer = UI.vbox(12) if UI.is_compact() else UI.hbox(18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	_diagram = Control.new()
	_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_diagram.custom_minimum_size = Vector2(0, 260 if UI.is_portrait() else 300)
	_diagram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diagram.draw.connect(_draw_diagram)
	body.add_child(_diagram)

	_panel = UI.panel(18, 0.94)
	_panel.custom_minimum_size = Vector2(360 if not UI.is_compact() else 0, 0)
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_panel)
	_panel_box = UI.vbox(9)
	_panel.add_child(_panel_box)
	_fill_panel()


func _fill_panel() -> void:
	for c in _panel_box.get_children():
		c.queue_free()
	_panel_box.add_child(UI.micro("BONUS SKY NOTE  ·  ECLIPSES", Color(G.GOLD, 0.95), 9))
	var head := UI.heading(_copy("title", "Why isn't there an eclipse every month?"), 25)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_box.add_child(head)
	var idea := UI.label(_copy("big_idea", "The Moon's orbit is tilted by about 5°. Most new and full moons pass above or below the Sun–Earth line."), 14, Color(G.MUTED, 0.98))
	_panel_box.add_child(idea)

	var modes := UI.hbox(6)
	_panel_box.add_child(modes)
	var group := ButtonGroup.new()
	_solar_btn = UI.button("Solar eclipse", false, 14)
	_solar_btn.toggle_mode = true
	_solar_btn.button_group = group
	_solar_btn.button_pressed = mode == "solar"
	_solar_btn.toggled.connect(func(on: bool):
		if on:
			_set_mode("solar"))
	modes.add_child(_solar_btn)
	_lunar_btn = UI.button("Lunar eclipse", false, 14)
	_lunar_btn.toggle_mode = true
	_lunar_btn.button_group = group
	_lunar_btn.button_pressed = mode == "lunar"
	_lunar_btn.toggled.connect(func(on: bool):
		if on:
			_set_mode("lunar"))
	modes.add_child(_lunar_btn)

	_tilt_label = UI.micro("ORBIT TILT  %.1f°" % tilt, G.GOLD, 9)
	_panel_box.add_child(_tilt_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 5.0
	slider.step = 0.1
	slider.value = tilt
	slider.custom_minimum_size = Vector2(0, 34)
	slider.value_changed.connect(func(v: float):
		tilt = v
		_update_state()
		if _diagram:
			_diagram.queue_redraw())
	slider.drag_started.connect(func(): Sfx.play("whoosh", -30.0, 1.15))
	slider.drag_ended.connect(func(_v): Sfx.play("tick", -24.0, 0.9))
	_panel_box.add_child(slider)

	_status = UI.label("", 20, G.VERMILION, "display")
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_box.add_child(_status)
	_detail = UI.label("", 14, G.CREAM)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_box.add_child(_detail)
	_prompt = UI.micro("", G.GOLD, 9)
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_box.add_child(_prompt)

	_panel_box.add_child(UI.rule(Color(G.GOLD, 0.18), 1))
	var fact := UI.label("Solar eclipse: the Moon's shadow falls on Earth. Lunar eclipse: Earth's shadow falls on the Moon.", 13, Color(G.MUTED, 0.95))
	fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_box.add_child(fact)
	var model := UI.micro("SIMPLIFIED MODEL  ·  NASA/GSFC GEOMETRY", Color(G.MUTED, 0.65), 8)
	_panel_box.add_child(model)
	var back := UI.ghost_button("Back to the Moon lab  ›", 12)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func(): Router.go("res://scenes/MoonLab.tscn"))
	_panel_box.add_child(back)
	_update_state()


func _set_mode(next: String) -> void:
	if mode == next:
		return
	mode = next
	tilt = 4.0
	_was_hit = false
	_solved = false
	Sfx.play("click")
	_fill_panel()
	if _diagram:
		_diagram.queue_redraw()


func _hit() -> bool:
	return tilt <= 1.2


func _update_state() -> void:
	var hit := _hit()
	var solar := mode == "solar"
	_tilt_label.text = "ORBIT TILT  %.1f°" % tilt
	if hit:
		_status.text = "UMBRA HITS EARTH" if solar else "MOON IN EARTH'S SHADOW"
		_status.add_theme_color_override("font_color", G.TEAL)
		_detail.text = _copy("solar" if solar else "lunar", "The shadow reaches its target. This is an eclipse.")
		_prompt.text = "ECLIPSE  ·  THE SHADOW LANDS"
		if not _was_hit:
			_was_hit = true
			_solved = true
			Sfx.play("success")
			Juice.stamp("ECLIPSE!", G.TEAL)
	else:
		_status.text = "SHADOW MISSES"
		_status.add_theme_color_override("font_color", G.VERMILION)
		_detail.text = _copy("miss", "The Moon is above or below the line. No eclipse this month.")
		_prompt.text = "IN THIS MODEL: TILT BELOW 1.2° TO LAND THE SHADOW"
		_was_hit = false


func _on_resize() -> void:
	_build_ui()


func _draw_diagram() -> void:
	if _diagram == null:
		return
	var w := _diagram.size.x
	var h := _diagram.size.y
	if w < 80.0 or h < 80.0:
		return
	var sun := Vector2(w * 0.13, h * 0.5)
	var earth := Vector2(w * 0.56, h * 0.5)
	var r := minf(w * 0.28, h * 0.3)
	var moon_angle := PI if mode == "solar" else 0.0
	var offset := (tilt / 5.0) * r * 0.55
	var moon := earth + Vector2(cos(moon_angle) * r, sin(moon_angle) * r * 0.0 + offset)

	# Sun halo and body.
	for i in 4:
		_diagram.draw_circle(sun, 38.0 + i * 15.0, Color(SUN_COLOR, 0.035))
	_diagram.draw_circle(sun, 38.0, SUN_COLOR)
	_diagram.draw_circle(sun, 34.0, Color("fff2bd"))

	# Ecliptic line and orbit.
	_diagram.draw_dashed_line(Vector2(w * 0.04, earth.y), Vector2(w * 0.94, earth.y), Color(G.CREAM, 0.18), 1.0, 8.0)
	var orbit := PackedVector2Array()
	for i in 65:
		var a := TAU * float(i) / 64.0
		orbit.append(earth + Vector2(cos(a) * r, sin(a) * r * 0.0))
	_diagram.draw_polyline(orbit, Color(G.GOLD, 0.35), 1.0)

	_diagram.draw_circle(earth, 29.0, Color("2d6fbf"))
	_diagram.draw_arc(earth, 29.0, 1.7, 4.5, 28, Color("62b06d"), 8.0, true)
	_diagram.draw_arc(earth, 29.0, 4.5, 7.9, 28, Color("1f4f8a"), 8.0, true)

	# The shadow always runs away from the Sun, parallel to the Sun–Earth line.
	# A tilted Moon carries the cone above or below Earth instead of bending it.
	var cone_start := moon if mode == "solar" else earth
	var anchor := earth if mode == "solar" else moon
	var length := absf(anchor.x - cone_start.x) * 1.12
	var dir := Vector2.RIGHT
	var tip := Vector2(cone_start.x + length, cone_start.y)
	var perp := Vector2(-dir.y, dir.x)
	var near := 11.0 if mode == "solar" else 29.0
	var far := 1.5
	var poly := PackedVector2Array([
		cone_start + perp * near,
		cone_start - perp * near,
		tip - perp * far,
		tip + perp * far,
	])
	_diagram.draw_colored_polygon(poly, Color(0.01, 0.01, 0.025, 0.78))
	_diagram.draw_polyline(PackedVector2Array([poly[0], poly[2], poly[3], poly[1]]), Color(G.GOLD, 0.25), 1.0)

	var font := UI.body_med_font()
	# The tilt itself: a bracket from the ecliptic to the Moon.
	var ecliptic_point := Vector2(moon.x, earth.y)
	_diagram.draw_dashed_line(ecliptic_point, moon, Color(G.VERMILION, 0.8), 1.5, 4.0)
	if w > 500.0:
		_diagram.draw_string(font, Vector2(moon.x + 16, (ecliptic_point.y + moon.y) * 0.5), "%.1f°" % tilt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(G.VERMILION, 0.95))

	# Moon body; a lunar eclipse turns it copper.
	var moon_color := Color("f7eddc")
	if mode == "lunar" and _hit():
		moon_color = Color("c86a42")
	_diagram.draw_circle(moon, 12.0, moon_color)
	_diagram.draw_circle(moon, 12.0, Color(G.CREAM, 0.55), false, 1.0)

	# Labels.
	_diagram.draw_string(font, sun + Vector2(-18, 58), "SUN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(G.MUTED))
	_diagram.draw_string(font, earth + Vector2(-22, 48), "EARTH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(G.MUTED))
	if w > 500.0:
		_diagram.draw_string(font, moon + Vector2(-18, -20), "MOON", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(G.GOLD))
	_diagram.draw_string(font, Vector2(earth.x - 34, h - 8), "SIMPLIFIED MODEL  ·  NOT TO SCALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(G.MUTED, 0.7))


class SkyBackdrop extends Control:
	func _draw() -> void:
		for i in 70:
			var p := Vector2(
				fposmod(float(i * 193 + 17), maxf(size.x, 1.0)),
				fposmod(float(i * 97 + 31), maxf(size.y, 1.0)))
			var a := 0.08 + 0.20 * float((i * 37) % 11) / 10.0
			draw_circle(p, 0.7 + float(i % 3) * 0.55, Color(G.CREAM, a))

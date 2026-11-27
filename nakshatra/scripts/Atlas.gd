extends Node3D
## Sky Atlas: the whole sky, real positions, free to wander.

var sky: SkyDome
var cam: Camera3D
var ui_root: Control
var panel: PanelContainer
var time_slider: HSlider
var time_label: Label
var time_value_label: Label
var info_title: Label
var info_body: RichTextLabel
var mode_label: Label
var marker_layer: Control
var _last_facing := -1

var hour := 21.0
var playing := false
var guided := false
var selected_hip := -1
var _pressed := false
var _looked := false
var _press_pos := Vector2.ZERO
var _portrait := false
var _compact := false


func _ready() -> void:
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)


func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 66.0
	cam.near = 0.1
	cam.far = 3000.0
	cam.current = true
	add_child(cam)
	cam.position = Vector3.ZERO
	cam.rotation_degrees = Vector3(-12, 0, 0)

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.set_hour(hour)
	add_child(sky)
	sky.set_modern_lines(true)
	sky.set_nakshatra_lines(false)
	sky.set_labels(true)
	sky.set_star_scale(1.55)
	sky.set_star_intensity(1.22)
	if sky.modern_lines and sky.modern_lines.material_override:
		(sky.modern_lines.material_override as ShaderMaterial).set_shader_parameter("alpha", 1.0)
	if sky.nak_lines and sky.nak_lines.material_override:
		(sky.nak_lines.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.9)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.45

	var meteors := ShootingStarField.new()
	meteors.name = "Meteors"
	add_child(meteors)


func _build_ui() -> void:
	if marker_layer:
		if marker_layer.draw.is_connected(_draw_sky_markers):
			marker_layer.draw.disconnect(_draw_sky_markers)
		marker_layer.queue_free()
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.theme()
	add_child(ui_root)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui_root.add_child(vignette)
	ui_root.add_child(UI.scrim(true, 156, 0.72))

	marker_layer = Control.new()
	marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_layer.draw.connect(_draw_sky_markers)
	ui_root.add_child(marker_layer)

	ui_root.add_child(UI.print_frame(16))

	var outer := UI.margin(UI.pad() + 4, 22, UI.pad() + 4, 14)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(outer)
	var col := UI.vbox(0)
	outer.add_child(col)
	col.add_child(_top_bar())

	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(body)

	panel = UI.panel(16, 0.92)
	if UI.is_portrait():
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(v)
		v.add_child(UI.spacer(true, true))
		panel.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y * 0.44, 300, 430))
		panel.size_flags_vertical = Control.SIZE_SHRINK_END
		v.add_child(panel)
	else:
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(h)
		h.add_child(UI.spacer(true, false))
		panel.custom_minimum_size = Vector2(360, 0)
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.add_child(panel)
	_fill_panel()
	var vp := UI.viewport_size()
	if UI.is_portrait():
		var ph := clampf(vp.y * 0.44, 300.0, 430.0)
		sky.label_safe = Rect2(24, 80, vp.x - 48, maxf(120.0, vp.y - 80.0 - ph - 12.0))
	else:
		sky.label_safe = Rect2(24, 80, maxf(160.0, vp.x - 24.0 - 360.0 - 20.0), vp.y - 80.0 - 24.0)
	_portrait = UI.is_portrait()
	ui_root.add_child(UI.grain(0.04))
	UI.fade_in(ui_root, 0.05, 0.6)


func _top_bar() -> Control:
	time_label = UI.micro("21:00", Color(G.GOLD, 0.9), 10)
	var acts: Array = [{"text": "LIST" if UI.is_compact() else "CONSTELLATIONS", "fn": func(): _show_constellations()}]
	return UI.app_bar("Sky Atlas", "CHANDRAGIRI  ·  13° N  ·  THE REAL SKY", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB", time_label)


func _fill_panel() -> void:
	for c in panel.get_children():
		c.queue_free()
	var scroll := UI.scroll()
	panel.add_child(scroll)
	var v := UI.vbox(7)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	mode_label = UI.micro("REAL SKY  ·  13° N", Color(G.GOLD, 0.9), 9)
	mode_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(mode_label)
	head.add_child(UI.spacer())
	var play := UI.link_button("PAUSE" if playing else "PLAY", 10)
	play.custom_minimum_size = Vector2(54, 30)
	play.pressed.connect(func():
		playing = not playing
		Sfx.play("click")
		_build_ui())
	head.add_child(play)

	var time_head := UI.hbox(6)
	time_head.add_child(UI.micro("TIME OF NIGHT", Color(G.MUTED, 0.7), 8))
	time_head.add_child(UI.spacer())
	var now_btn := UI.link_button("NOW", 9)
	now_btn.pressed.connect(_set_now)
	time_head.add_child(now_btn)
	v.add_child(time_head)
	time_slider = HSlider.new()
	time_slider.min_value = 18
	time_slider.max_value = 30
	time_slider.step = 0.05
	time_slider.value = hour if hour >= 18 else hour + 24
	time_slider.custom_minimum_size = Vector2(0, 26)
	time_slider.value_changed.connect(func(val):
		hour = fmod(float(val), 24.0)
		guided = false
		sky.set_hour(val)
		sky.clear_highlight()
		_update_time())
	v.add_child(time_slider)
	var scale_row := UI.hbox(6)
	scale_row.add_child(UI.micro("6 PM  ·  MIDNIGHT  ·  6 AM", Color(G.MUTED, 0.55), 8))
	scale_row.add_child(UI.spacer())
	time_value_label = UI.micro("9:00 PM", Color(G.GOLD, 0.95), 9)
	scale_row.add_child(time_value_label)
	v.add_child(scale_row)

	var toggles := UI.hbox(6)
	v.add_child(toggles)
	var lines_btn := UI.ghost_button("Lines: on" if sky.show_modern else "Lines: off", 12)
	lines_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines_btn.pressed.connect(func():
		sky.set_modern_lines(not sky.show_modern)
		_build_ui())
	toggles.add_child(lines_btn)
	var nak_btn := UI.ghost_button("Nakshatras: on" if sky.show_nakshatra else "Nakshatras: off", 12)
	nak_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nak_btn.pressed.connect(func():
		sky.set_nakshatra_lines(not sky.show_nakshatra)
		_build_ui())
	toggles.add_child(nak_btn)
	var labels_btn := UI.ghost_button("Labels: on" if sky.show_labels else "Labels: off", 12)
	labels_btn.pressed.connect(func():
		sky.set_labels(not sky.show_labels)
		_build_ui())
	toggles.add_child(labels_btn)

	var row := UI.hbox(6)
	v.add_child(row)
	var real := UI.ghost_button("Real sky", 12)
	real.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	real.pressed.connect(func():
		guided = false
		sky.set_hour(hour)
		sky.clear_highlight()
		cam.rotation = Vector3.ZERO
		_build_ui())
	row.add_child(real)
	var reset := UI.ghost_button("Face south", 12)
	reset.pressed.connect(func():
		cam.rotation = Vector3.ZERO
		guided = false
		sky.set_hour(hour))
	row.add_child(reset)

	v.add_child(UI.rule(Color(G.GOLD, 0.2), 1))
	info_title = UI.heading("Tap a star", 22)
	info_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(info_title)
	info_body = UI.rich("Drag to look around. Tap any dot to find out what it is. The gold lines are the 88 constellations; the teal lines are the 28 nakshatras.", 12, Color(G.MUTED, 0.95))
	v.add_child(info_body)

	_update_time()


func _update_time() -> void:
	if time_label:
		var d := _facing_text()
		if UI.is_compact():
			time_label.text = "%02d:%02d" % [int(hour), int(round(fmod(hour, 1.0) * 60.0)) % 60]
		else:
			time_label.text = "%02d:%02d  ·  %s" % [int(hour), int(round(fmod(hour, 1.0) * 60.0)) % 60, d]
	if time_slider:
		var want := hour if hour >= 18 else hour + 24
		if absf(time_slider.value - want) > 0.06:
			time_slider.set_value_no_signal(want)
	if time_value_label:
		var hh := int(hour) % 24
		var mm := int(round(fmod(hour, 1.0) * 60.0)) % 60
		var suffix := "PM" if hh >= 12 else "AM"
		var h12 := hh % 12
		if h12 == 0:
			h12 = 12
		time_value_label.text = "%d:%02d %s" % [h12, mm, suffix]
	if mode_label:
		mode_label.text = "GUIDED VIEW" if guided else "REAL SKY  ·  13° N"


func _facing_text() -> String:
	if cam == null:
		return "S"
	var bearing := fposmod(-rad_to_deg(cam.rotation.y), 360.0)
	var dirs := ["S", "SE", "E", "NE", "N", "NW", "W", "SW"]
	return dirs[int(round(bearing / 45.0)) % 8]


func _set_now() -> void:
	var t := Time.get_time_dict_from_system()
	hour = float(t.get("hour", 21)) + float(t.get("minute", 0)) / 60.0
	playing = false
	guided = false
	sky.set_hour(hour)
	sky.clear_highlight()
	selected_hip = -1
	if marker_layer:
		marker_layer.queue_redraw()
	Sfx.play("click")
	_update_time()


func _draw_sky_markers() -> void:
	if selected_hip < 0 or sky == null or cam == null:
		return
	var idx := StarDB.star_index_by_hip(selected_hip)
	if idx < 0:
		return
	var w := sky.star_world(idx)
	if cam.is_position_behind(w):
		return
	var sp := cam.unproject_position(w)
	marker_layer.draw_arc(sp, 15, 0, TAU, 32, Color(G.GOLD, 0.95), 1.6, true)
	marker_layer.draw_arc(sp, 22, 0, TAU, 32, Color(G.GOLD, 0.28), 1.0, true)
	marker_layer.draw_line(sp - Vector2(30, 0), sp - Vector2(19, 0), Color(G.GOLD, 0.55), 1.0)
	marker_layer.draw_line(sp + Vector2(19, 0), sp + Vector2(30, 0), Color(G.GOLD, 0.55), 1.0)


func _pick_at(pos: Vector2) -> void:
	var pick := sky.pick_star(pos, cam, 46.0 if DisplayServer.is_touchscreen_available() else 38.0)
	if pick.is_empty():
		selected_hip = -1
		info_title.text = "Empty sky"
		info_body.text = "No catalogued star within reach. Try a brighter dot — or turn the labels on."
		return
	selected_hip = int(pick["hip"])
	if marker_layer:
		marker_layer.queue_redraw()
	var info := StarDB.hip_star(selected_hip)
	var name := str(info.get("name", ""))
	var con := str(info.get("con", ""))
	var con_name := con
	var c = StarDB.constellation(con)
	if not c.is_empty():
		con_name = str(c.get("name", con))
	var dist := float(info.get("dist", 0.0))
	var mag := float(info.get("mag", 0.0))
	var bv := float(info.get("ci", 0.0))
	var colour := "blue-white"
	if bv > -0.1 and bv <= 0.35:
		colour = "white"
	elif bv > 0.35 and bv <= 0.85:
		colour = "yellow-white"
	elif bv > 0.85 and bv <= 1.4:
		colour = "orange"
	elif bv > 1.4:
		colour = "red"
	info_title.text = name if name != "" else "HIP %d" % selected_hip
	var dist_text := "unknown" if dist <= 0.0 else "%.0f light-years" % dist
	info_body.text = ("A %s star in [b]%s[/b].\nApparent magnitude %.1f  ·  distance %s.\nHIP catalogue number %d." % [
		colour, con_name, mag, dist_text, selected_hip])
	Sfx.play("chime")


func _show_constellations() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.012, 0.008, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			overlay.queue_free())
	overlay.add_child(dim)
	var outer := UI.margin(UI.pad(), 18, UI.pad(), 18)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(outer)
	var sheet := UI.paper(UI.pad())
	outer.add_child(sheet)
	var v := UI.vbox(10)
	sheet.add_child(v)
	var bar := UI.hbox(8)
	v.add_child(bar)
	var t := UI.heading("The 88 constellations", 30, G.INK)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(t)
	var x := UI.link_button("CLOSE  ×", 10, G.INK)
	x.pressed.connect(func(): overlay.queue_free())
	bar.add_child(x)
	v.add_child(UI.label("Tap one to find it in the sky. Lines show its official IAU shape.", 13, G.INK_SOFT))
	v.add_child(UI.rule(Color(G.INK, 0.2), 1))
	var scroll := UI.scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2 if UI.is_portrait() else 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)
	var sorted := StarDB.constellations.duplicate()
	sorted.sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))
	for c in sorted:
		var cid := str(c.get("id", ""))
		var b := UI.ink_button(str(c.get("name", "")), false, 12)
		b.custom_minimum_size = Vector2(0, 36)
		b.pressed.connect(func():
			overlay.queue_free()
			_select_constellation(cid))
		grid.add_child(b)


func _select_constellation(id: String) -> void:
	var c = StarDB.constellation(id)
	if c.is_empty():
		return
	guided = true
	cam.rotation = Vector3.ZERO
	sky.guided_to_constellation(id)
	sky.set_highlight(id, Color(G.GOLD))
	selected_hip = -1
	if marker_layer:
		marker_layer.queue_redraw()
	info_title.text = str(c.get("name", id))
	var n := 0
	for hip in c.get("stars", []):
		if StarDB.star_index_by_hip(int(hip)) >= 0:
			n += 1
	info_body.text = ("[b]%s[/b]  ·  %s\n%d catalogued stars in this pattern. The lines are drawn from the official IAU figure.\n\nTap a star to read its name." % [
		str(c.get("name", id)), str(c.get("english", "")), n])
	if mode_label:
		mode_label.text = "GUIDED VIEW"
	Sfx.play("chime")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_pressed = true
			_looked = false
			_press_pos = mb.position
		else:
			if _pressed and not _looked:
				_pick_at(mb.position)
			_pressed = false
	elif event is InputEventMouseMotion and _pressed:
		var mm := event as InputEventMouseMotion
		if not _looked and mm.position.distance_to(_press_pos) > 8.0:
			_looked = true
		if _looked:
			cam.rotation.y -= mm.relative.x * 0.004
			cam.rotation.x = clampf(cam.rotation.x - mm.relative.y * 0.004, -1.35, 1.35)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_pressed = true
			_looked = false
			_press_pos = st.position
		else:
			if _pressed and not _looked:
				_pick_at(st.position)
			_pressed = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _looked and sd.position.distance_to(_press_pos) > 10.0:
			_looked = true
		if _looked:
			cam.rotation.y -= sd.relative.x * 0.004
			cam.rotation.x = clampf(cam.rotation.x - sd.relative.y * 0.004, -1.35, 1.35)


func _process(delta: float) -> void:
	if playing:
		hour = fmod(hour + delta * 0.18, 24.0)
		sky.set_hour(hour)
		_update_time()
	if marker_layer:
		marker_layer.queue_redraw()
	var bearing := int(round(fposmod(-rad_to_deg(cam.rotation.y), 360.0)))
	if bearing != _last_facing:
		_last_facing = bearing
		_update_time()


func _on_resize() -> void:
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_build_ui()

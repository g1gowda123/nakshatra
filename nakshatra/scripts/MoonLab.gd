extends Node3D
## Moon phases, made physical: drag the Moon, watch the view from Earth.

const ORBIT_RADIUS := 6.6
const ORBIT_TILT := 0.34
# The Moon travels in the -angle direction: full at 0°, new at 180°, waxing on
# the 0-180 half. Drag, buttons and hints all use this one sign so the name, the
# lit fraction and the motion can never disagree.
const ORBIT_SIGN := -1.0
const EARTH_RADIUS := 2.15
const MOON_RADIUS := 1.0

var cam: Camera3D
var earth: MeshInstance3D
var moon: MeshInstance3D
var sun: MeshInstance3D
var sky: SkyDome
var inset_view: SubViewport
var inset_cam: Camera3D
var ui_root: Control
var panel_root: Control
var inset_frame: Control

var angle_deg := 230.0
var challenge_index := 0
var attempts := 0
var completed := false
var _dragging := false
var _drag_last := Vector2.ZERO
var _updating_slider := false

var slider: HSlider
var phase_label: Label
var illum_label: Label
var note_label: Label
var prompt_label: Label
var feedback_label: Label
var progress_row: HBoxContainer
var check_btn: Button
var hint_btn: Button
var phase_kn_label: Label

var challenges: Array = []


func _ready() -> void:
	challenges = G.content.get("moon", {}).get("challenges", [])
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	_set_angle(angle_deg)
	set_process(true)
	G.maybe_briefing(ui_root, "moon")
	if OS.get_cmdline_user_args().has("--moon-check"):
		_set_angle(140.0)
		_check.call_deferred()


func _build_world() -> void:
	sky = SkyDome.new()
	sky.latitude_deg = 0.0
	sky.sidereal_deg = 140.0
	add_child(sky)
	sky.set_modern_lines(false)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.18
	if sky.sky_material:
		sky.sky_material.set_shader_parameter("horizon_color", Color(0.035, 0.030, 0.026))
		sky.sky_material.set_shader_parameter("mid_color", Color(0.012, 0.02, 0.05))
		sky.sky_material.set_shader_parameter("glow_color", Color(0.04, 0.03, 0.04))
		sky.sky_material.set_shader_parameter("milky_strength", 0.35)

	cam = Camera3D.new()
	cam.fov = 48.0
	cam.near = 0.1
	cam.far = 2000.0
	add_child(cam)
	_place_camera()

	sun = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.5
	sm.height = 3.0
	sm.radial_segments = 32
	sm.rings = 16
	sun.mesh = sm
	sun.position = Vector3(-12.5, 0.0, 0.0)
	sun.material_override = _shader_mat("res://shaders/sun.gdshader")
	add_child(sun)
	var sun_glow := Sprite3D.new()
	sun_glow.texture = load("res://assets/fx/glow.png")
	sun_glow.pixel_size = 0.02
	sun_glow.scale = Vector3.ONE * 5.2
	sun_glow.layers = 2
	sun_glow.modulate = Color(1.0, 0.76, 0.4, 0.55)
	sun_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sun_glow.shaded = false
	sun_glow.position = sun.position
	add_child(sun_glow)

	var sun_light := DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.94, 0.82)
	sun_light.light_energy = 1.55
	add_child(sun_light)
	sun_light.look_at_from_position(Vector3(-12.5, 0.0, 0.0), Vector3.ZERO, Vector3.UP)

	earth = MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = EARTH_RADIUS
	em.height = EARTH_RADIUS * 2.0
	em.radial_segments = 48
	em.rings = 24
	earth.mesh = em
	earth.material_override = _shader_mat("res://shaders/earth.gdshader")
	add_child(earth)
	var earth_glow := Sprite3D.new()
	earth_glow.texture = load("res://assets/fx/glow.png")
	earth_glow.pixel_size = 0.014
	earth_glow.scale = Vector3.ONE * 4.4
	earth_glow.modulate = Color(0.35, 0.58, 1.0, 0.35)
	earth_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	earth_glow.shaded = false
	add_child(earth_glow)

	moon = MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = MOON_RADIUS
	mm.height = MOON_RADIUS * 2.0
	mm.radial_segments = 32
	mm.rings = 16
	moon.mesh = mm
	moon.material_override = _shader_mat("res://shaders/moon.gdshader")
	add_child(moon)
	var moon_glow := Sprite3D.new()
	moon_glow.texture = load("res://assets/fx/glow.png")
	moon_glow.pixel_size = 0.015
	moon_glow.scale = Vector3.ONE * 3.2
	moon_glow.modulate = Color(0.95, 0.90, 0.78, 0.55)
	moon_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	moon_glow.shaded = false
	moon.add_child(moon_glow)
	var moon_tag := Label3D.new()
	moon_tag.text = "MOON"
	moon_tag.font = UI.body_med_font()
	moon_tag.font_size = 30
	moon_tag.pixel_size = 0.016
	moon_tag.modulate = Color(G.GOLD, 0.9)
	moon_tag.outline_size = 6
	moon_tag.outline_modulate = Color(0.030, 0.028, 0.024, 0.9)
	moon_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	moon_tag.no_depth_test = true
	moon_tag.position = Vector3(0, 1.45, 0)
	moon.add_child(moon_tag)

	# Orbit ring.
	var ring := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 97:
		var a := TAU * i / 96.0
		im.surface_set_color(Color(G.GOLD, 0.32))
		im.surface_add_vertex(Vector3(cos(a) * ORBIT_RADIUS, sin(a) * ORBIT_RADIUS * ORBIT_TILT, sin(a) * ORBIT_RADIUS))
	im.surface_end()
	var lm := ShaderMaterial.new()
	lm.shader = load("res://shaders/line.gdshader")
	lm.set_shader_parameter("alpha", 0.8)
	ring.mesh = im
	ring.material_override = lm
	ring.layers = 2
	add_child(ring)

	_build_inset()


func _shader_mat(path: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	return m


func _build_inset() -> void:
	inset_view = SubViewport.new()
	inset_view.size = Vector2i(256, 256)
	inset_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	inset_view.transparent_bg = false
	inset_view.own_world_3d = false
	inset_cam = Camera3D.new()
	inset_cam.fov = 26.0
	inset_cam.cull_mask = 0xFFFFF & ~2
	inset_cam.current = true
	inset_view.add_child(inset_cam)
	_update_inset_camera()


func _set_angle(deg: float) -> void:
	angle_deg = fposmod(deg, 360.0)
	var a := deg_to_rad(angle_deg)
	var dir := Vector3(cos(a), sin(a) * ORBIT_TILT, sin(a))
	moon.position = dir * ORBIT_RADIUS
	_update_inset_camera()
	_update_readout()
	if slider and not _updating_slider:
		_updating_slider = true
		slider.value = angle_deg
		_updating_slider = false


func _update_inset_camera() -> void:
	if not inset_cam or not moon:
		return
	var a := deg_to_rad(angle_deg)
	var moon_dir := moon.position.normalized()
	var offset := moon_dir * (EARTH_RADIUS + 0.35) + Vector3(0, 0.05, 0)
	var up := Vector3.UP if absf(moon_dir.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	inset_cam.look_at_from_position(offset, moon.global_position, up)
	if inset_view:
		inset_view.render_target_update_mode = SubViewport.UPDATE_ONCE


func _phase() -> Dictionary:
	var a := deg_to_rad(angle_deg)
	var sun_dir := Vector3(-1, 0, 0)
	var moon_dir := Vector3(cos(a), 0, sin(a))
	var illum := clampf((1.0 - sun_dir.dot(moon_dir)) * 0.5, 0.0, 1.0)
	# The panel and the inset must agree: derive the lit fraction from the
	# actual Sun–Moon–Earth vectors, not from an idealised flat orbit.
	if earth and moon:
		var to_earth := (earth.global_position - moon.global_position).normalized()
		# The key light travels along +X (Sun at -X). The lit hemisphere faces -X.
		illum = clampf((1.0 - to_earth.dot(Vector3.RIGHT)) * 0.5, 0.0, 1.0)
	# New moon is at 180°, full at 0°. The Moon travels in the -angle direction,
	# so 180°›0° is waxing and 0°›180° is waning.
	var waxing := angle_deg < 180.0
	var name := ""
	if illum < 0.03:
		name = "New Moon"
	elif illum > 0.97:
		name = "Full Moon"
	elif absf(illum - 0.5) <= 0.05:
		name = "First Quarter" if waxing else "Last Quarter"
	elif illum < 0.5:
		name = "Waxing Crescent" if waxing else "Waning Crescent"
	else:
		name = "Waxing Gibbous" if waxing else "Waning Gibbous"
	return {"illum": illum, "waxing": waxing, "name": name}


func _phase_kannada(name: String) -> String:
	for p in G.content.get("moon", {}).get("phases", []):
		if str(p.get("name", "")) == name:
			return str(p.get("kannada", ""))
	return ""


func _update_readout() -> void:
	var p := _phase()
	var hide := not completed and challenge_index < challenges.size()
	if phase_label:
		if hide:
			phase_label.text = "PHASE HIDDEN"
			phase_label.add_theme_font_size_override("font_size", 24)
			phase_label.add_theme_color_override("font_color", G.VERMILION)
		else:
			phase_label.text = str(p["name"])
			phase_label.add_theme_font_size_override("font_size", 24)
			phase_label.add_theme_color_override("font_color", G.CREAM)
	if illum_label:
		illum_label.text = "" if hide else "%d%% of the face lit" % int(round(float(p["illum"]) * 100.0))
	if phase_kn_label:
		phase_kn_label.text = "" if hide else _phase_kannada(str(p["name"]))
	if note_label:
		note_label.text = "" if hide else _phase_note(str(p["name"]))


func _phase_note(name: String) -> String:
	for p in G.content.get("moon", {}).get("phases", []):
		if str(p.get("name", "")) == name:
			return str(p.get("note", ""))
	return ""


func _build_ui() -> void:
	if inset_view and is_instance_valid(inset_view) and inset_view.get_parent():
		inset_view.get_parent().remove_child(inset_view)
	if ui_root:
		ui_root.queue_free()
		panel_root = null
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

	var outer := UI.margin(UI.pad(), 12, UI.pad(), 12)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(outer)
	var col := UI.vbox(10)
	outer.add_child(col)
	col.add_child(_top_bar())

	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(body)
	panel_root = _panel()
	if UI.is_portrait():
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(v)
		v.add_child(UI.spacer(true, true))
		panel_root.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y * 0.56, 320, 500))
		panel_root.size_flags_vertical = Control.SIZE_SHRINK_END
		v.add_child(panel_root)
	else:
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(h)
		h.add_child(UI.spacer(true, false))
		panel_root.custom_minimum_size = Vector2(360, 0)
		panel_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.add_child(panel_root)

	_portrait = UI.is_portrait()
	_fill_panel()
	_place_camera()
	UI.fade_in(ui_root, 0.05, 0.6)


func _top_bar() -> Control:
	var acts: Array = [{"text": "LESSON", "fn": func(): _show_learn()}]
	if not UI.is_compact():
		acts.append({"text": "ECLIPSES", "fn": func(): Router.go("res://scenes/EclipseLab.tscn")})
		acts.append({"text": "SKY ATLAS", "fn": func(): Router.go("res://scenes/Atlas.tscn")})
	return UI.app_bar("The Moon's Mask", "MOON PHASES  ·  A LIVE MODEL", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB")


func _panel() -> PanelContainer:
	var p := UI.panel(16, 0.92)
	return p


func _fill_panel() -> void:
	for c in panel_root.get_children():
		c.queue_free()
	var outer := UI.vbox(6)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_root.add_child(outer)
	var scroll := UI.scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var v := UI.vbox(5)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	head.add_child(UI.sticker("FROM EARTH", G.TEAL, G.INK, 0.0))
	head.add_child(UI.spacer())


	var center_frame := CenterContainer.new()
	v.add_child(center_frame)
	var frame := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.030, 0.028, 0.024, 1.0)
	sb.border_color = Color(Design.PHOSPHOR, 0.34)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 2
	sb.shadow_offset = Vector2(5, 5)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	frame.add_theme_stylebox_override("panel", sb)
	var side := 138 if not UI.is_portrait() else 92
	frame.custom_minimum_size = Vector2(side, side)
	frame.clip_contents = true
	center_frame.add_child(frame)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.custom_minimum_size = Vector2(side, side)
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	svc.add_child(inset_view)
	inset_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	frame.add_child(svc)

	phase_label = UI.label("Waxing Crescent", 24, G.CREAM, "display")
	phase_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(phase_label)
	phase_kn_label = UI.label("", 14, Color(G.GOLD, 0.85), "kannada")
	if not UI.is_compact():
		v.add_child(phase_kn_label)
	illum_label = UI.label("", 13, G.MUTED)
	v.add_child(illum_label)
	note_label = UI.label("", 12, Color(G.MUTED, 0.9))
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.max_lines_visible = 2
	note_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if not UI.is_compact():
		v.add_child(note_label)

	v.add_child(UI.divider())

	# The task and its controls stay pinned below the scroll: a student must
	# never be able to press Check without seeing the prompt on a phone.
	outer.add_child(UI.micro("YOUR MOVE", G.GOLD, 8))
	prompt_label = UI.label("", 19, G.CREAM, "display")
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(prompt_label)
	outer.add_child(UI.micro("STEPS", Color(Design.MUTED, 0.82), 8))
	progress_row = UI.hbox(5)
	outer.add_child(progress_row)

	outer.add_child(UI.micro("ORBIT", Color(Design.PHOSPHOR, 0.82), 9))
	slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 360
	slider.step = 0.5
	slider.value = angle_deg
	slider.custom_minimum_size = Vector2(0, 34)
	slider.value_changed.connect(func(val):
		if _updating_slider:
			return
		_set_angle(val))
	slider.drag_started.connect(func(): Sfx.play("whoosh", -26.0, 1.1))
	slider.drag_ended.connect(func(_v): Sfx.play("tick", -26.0, 0.9))
	if not UI.is_compact():
		outer.add_child(slider)


	var row := UI.hbox(6)
	outer.add_child(row)
	var minus := UI.ghost_button("‹ Earlier", 14)
	minus.custom_minimum_size = Vector2(88, 40)
	minus.pressed.connect(func():
		Sfx.play("click")
		_set_angle(angle_deg - 15.0 * ORBIT_SIGN))
	row.add_child(minus)
	var plus := UI.ghost_button("Later ›", 14)
	plus.custom_minimum_size = Vector2(88, 40)
	plus.pressed.connect(func():
		Sfx.play("click")
		_set_angle(angle_deg + 15.0 * ORBIT_SIGN))
	row.add_child(plus)
	hint_btn = UI.ghost_button("Hint", 15)
	hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_btn.pressed.connect(_hint)
	row.add_child(hint_btn)

	check_btn = UI.button("Check my Moon", true, 17)
	check_btn.custom_minimum_size = Vector2(0, 48)
	check_btn.pressed.connect(_check)
	outer.add_child(check_btn)
	if UI.is_compact():
		var ecl := UI.link_button("WHY ECLIPSES?  ›", 10, G.GOLD)
		ecl.pressed.connect(func(): Router.go("res://scenes/EclipseLab.tscn"))
		outer.add_child(ecl)

	feedback_label = UI.label("", 12, G.GOLD)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.max_lines_visible = 4
	feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	feedback_label.custom_minimum_size = Vector2(0, 64)
	outer.add_child(feedback_label)

	_update_challenge_ui()
	_update_readout()


func _update_challenge_ui() -> void:
	if challenges.is_empty():
		return
	if challenge_index >= challenges.size():
		prompt_label.text = "You have read all four phases."
		check_btn.text = "Finish"
		return
	var c: Dictionary = challenges[challenge_index]
	prompt_label.text = str(c.get("prompt", ""))
	for ch in progress_row.get_children():
		ch.queue_free()
	var states := []
	for i in challenges.size():
		states.append(2 if i < challenge_index else (1 if i == challenge_index else 0))
	progress_row.add_child(UI.pip_row(states, 14.0))


func _check() -> void:
	if completed:
		_finish()
		return
	if challenge_index >= challenges.size():
		_finish()
		return
	var target := str(challenges[challenge_index].get("target", ""))
	var p := _phase()
	var ok := false
	match target:
		"waxing_crescent":
			ok = float(p["illum"]) > 0.05 and float(p["illum"]) < 0.42 and bool(p["waxing"])
		"first_quarter":
			ok = absf(float(p["illum"]) - 0.5) <= 0.07 and bool(p["waxing"])
		"full":
			ok = float(p["illum"]) > 0.93
		"waning_crescent":
			ok = float(p["illum"]) > 0.05 and float(p["illum"]) < 0.42 and not bool(p["waxing"])
		"waning_gibbous":
			ok = float(p["illum"]) > 0.58 and not bool(p["waxing"])

	if ok:
		attempts = 0
		feedback_label.add_theme_color_override("font_color", G.TEAL)
		feedback_label.text = "%s. %s" % [str(p["name"]), _why(target)]
		Sfx.play("success")
		Juice.stamp("NAILED IT", G.TEAL)
		challenge_index += 1
		_update_challenge_ui()
		_update_readout()
		if challenge_index >= challenges.size():
			_show_finish_card()
	else:
		attempts += 1
		Sfx.play("soft_error")
		Juice.stamp("NOT YET — LOOK AGAIN", G.VERMILION, G.CREAM)
		feedback_label.add_theme_color_override("font_color", G.ROSE)
		feedback_label.text = _nudge(target, p)


func _why(target: String) -> String:
	match target:
		"waxing_crescent":
			return "Only a thin slice of the sunlit half faces us, and it is growing. In the evening sky the bright edge points toward the Sun, which has just set."
		"first_quarter":
			return "Half of the sunlit half is visible: the Moon is a quarter of the way around its orbit. It rises around noon and sets around midnight."
		"full":
			return "Earth is between the Sun and the Moon, so the entire sunlit half faces us. The Moon rises at sunset and stays up all night."
		"waning_crescent":
			return "The lit slice is shrinking and rises before dawn. In a few days the Moon will pass between Earth and the Sun and vanish from our night sky."
	return "The angle between the Sun, Earth and Moon decides how much of the lit half we see."


func _praise() -> String:
	return "Half the Moon is always lit. You just found the viewing angle that makes it look like that from Earth."


func _nudge(target: String, p: Dictionary) -> String:
	var name := str(p["name"])
	match target:
		"full":
			return "You have %s. Move the Moon further from the Sun until the whole face is lit." % name
		"first_quarter":
			return "You have %s. Move until exactly half is lit, on the growing side." % name
		"waxing_crescent":
			return "You have %s. Make a thin slice on the growing side — closer to the Sun." % name
		"waning_crescent":
			return "You have %s. Keep the thin slice but move it to the other side, shrinking." % name
	return "You have %s. Keep exploring — the view from Earth shows the real shape." % name


func _hint() -> void:
	if challenge_index >= challenges.size():
		return
	var target := str(challenges[challenge_index].get("target", ""))
	var target_angle := 140.0
	match target:
		"waxing_crescent": target_angle = 140.0
		"first_quarter": target_angle = 90.0
		"full": target_angle = 0.0
		"waning_crescent": target_angle = 220.0
	_set_angle(target_angle)
	feedback_label.add_theme_color_override("font_color", G.GOLD)
	feedback_label.text = "Hint: this is the geometry. Now press Check my Moon."
	Sfx.play("chime")


func _show_finish_card() -> void:
	completed = true
	G.complete("moon")
	_update_challenge_ui()
	_update_readout()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.030, 0.028, 0.024, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	overlay.add_child(center)
	var panel := UI.panel(UI.pad(), 0.98)
	panel.custom_minimum_size = Vector2(minf(600, UI.viewport_size().x - 32), 0)
	center.add_child(panel)
	var v := UI.vbox(10)
	panel.add_child(v)
	v.add_child(UI.micro("PHASE WEAVER", Color(G.GOLD, 0.9), 8))
	v.add_child(UI.heading("You have read the Moon.", 30))
	var p := _phase()
	v.add_child(UI.label("You ended on a %s. Notice that you did not change the Moon's shape — only where we see it from." % str(p["name"]).to_lower(), 16))
	var note := _phase_note(str(p["name"]))
	if note != "":
		v.add_child(UI.label(note, 14, Color(G.GOLD, 0.92)))
	v.add_child(UI.divider())
	for f in G.content.get("moon", {}).get("facts", []):
		v.add_child(UI.label("•  " + str(f), 14, G.MUTED))
	v.add_child(UI.spacer(false, false))
	var row := UI.hbox(8)
	v.add_child(row)
	var back := UI.button("Back to the lab", true, 17)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func(): Router.go("res://scenes/Lab.tscn"))
	row.add_child(back)
	var again := UI.ghost_button("Try again", 15)
	again.pressed.connect(func():
		overlay.queue_free()
		completed = false
		challenge_index = 0
		_set_angle(210)
		_update_challenge_ui()
		_update_readout())
	row.add_child(again)


func _show_learn() -> void:
	G.show_briefing("moon")


func _finish() -> void:
	Router.go("res://scenes/Lab.tscn")


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		cam.position = Vector3(-2.5, 18, 24)
		cam.fov = 78.0
		cam.look_at(Vector3(0, -5.0, 0), Vector3.UP)
	else:
		cam.position = Vector3(0, 16, 20)
		cam.fov = 60.0
		cam.look_at(Vector3(0, 0, 0), Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_drag_last = event.position
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		var dx: float = motion.position.x - _drag_last.x
		_drag_last = motion.position
		_set_angle(angle_deg + dx * 0.55 * ORBIT_SIGN)
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		_drag_last = event.position
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_set_angle(angle_deg + drag.relative.x * 0.55 * ORBIT_SIGN)


func _process(delta: float) -> void:
	if G.reduced_motion:
		return
	if earth:
		earth.rotation.y += delta * 0.035
	if sun:
		sun.rotation.y += delta * 0.02


var _portrait := false
var _compact := false


func _on_resize() -> void:
	_place_camera()
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_build_ui()


func _is_desktop_layout() -> bool:
	return not UI.is_portrait()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_on_resize()

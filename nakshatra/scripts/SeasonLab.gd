extends Node3D
## The Turning Year: a tilted Earth, real daylight maths, and a what-if switch.

const ORBIT_R := 8.2
const EARTH_R := 2.0
const LATITUDE := 13.0

var sky: SkyDome
var cam: Camera3D
var earth_pivot: Node3D
var earth_spin: Node3D
var earth_mesh: MeshInstance3D
var axis_group: Node3D
var sun_light: DirectionalLight3D
var orbit_marks: MeshInstance3D
var current_mark: MeshInstance3D

var ui_root: Control
var panel: PanelContainer
var month := 6.0
var tilt := 23.4
var challenge_index := 0
var solved := false
var completed := false
var _solved := false
var _portrait := false
var _compact := false

var month_label: Label
var dist_label: Label
var tilt_label: Label
var day_bar: ProgressBar
var day_label: Label
var alt_bar: ProgressBar
var alt_label: Label
var prompt_label: Label
var feedback: Label
var dots: HBoxContainer
var check_btn: Button
var next_btn: Button

const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]


func _ready() -> void:
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)
	G.maybe_briefing(ui_root, "seasons")


func _build_world() -> void:
	sky = SkyDome.new()
	sky.latitude_deg = 0.0
	add_child(sky)
	sky.set_modern_lines(false)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.22
	if sky.sky_material:
		sky.sky_material.set_shader_parameter("horizon_color", Color(0.02, 0.03, 0.07))
		sky.sky_material.set_shader_parameter("glow_color", Color(0.03, 0.03, 0.04))
		sky.sky_material.set_shader_parameter("milky_strength", 0.28)

	cam = Camera3D.new()
	cam.fov = 52.0
	cam.near = 0.1
	cam.far = 3000.0
	add_child(cam)
	_place_camera()

	sun_light = DirectionalLight3D.new()
	sun_light.light_color = Color(1.0, 0.95, 0.85)
	sun_light.light_energy = 1.5
	sun_light.shadow_enabled = false
	add_child(sun_light)

	# Sun
	var sun := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.8
	sm.height = 3.6
	sm.radial_segments = 32
	sm.rings = 16
	sun.mesh = sm
	var smat := ShaderMaterial.new()
	smat.shader = load("res://shaders/sun.gdshader")
	sun.material_override = smat
	add_child(sun)
	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.02
	glow.scale = Vector3.ONE * 6.0
	glow.modulate = Color(1.0, 0.75, 0.4, 0.68)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	add_child(glow)

	# Orbit
	var orbit := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 129:
		var a := TAU * i / 128.0
		im.surface_set_color(Color(G.GOLD, 0.28))
		im.surface_add_vertex(Vector3(cos(a) * ORBIT_R, 0, sin(a) * ORBIT_R))
	im.surface_end()
	var om := ShaderMaterial.new()
	om.shader = load("res://shaders/line.gdshader")
	om.set_shader_parameter("alpha", 0.9)
	orbit.mesh = im
	orbit.material_override = om
	add_child(orbit)

	# 12 month ticks.
	orbit_marks = MeshInstance3D.new()
	var mm := ImmediateMesh.new()
	mm.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 12:
		var a := TAU * i / 12.0
		var p0 := Vector3(cos(a) * (ORBIT_R - 0.3), 0, sin(a) * (ORBIT_R - 0.3))
		var p1 := Vector3(cos(a) * (ORBIT_R + 0.3), 0, sin(a) * (ORBIT_R + 0.3))
		mm.surface_set_color(Color(G.CREAM, 0.55))
		mm.surface_add_vertex(p0)
		mm.surface_set_color(Color(G.CREAM, 0.55))
		mm.surface_add_vertex(p1)
	mm.surface_end()
	orbit_marks.mesh = mm
	orbit_marks.material_override = om
	add_child(orbit_marks)

	# Season labels at the four cardinal points.
	_add_orbit_label("June solstice", PI, Color("ffd28a"))
	_add_orbit_label("December solstice", 0.0, Color("cfe4ff"))
	_add_orbit_label("March equinox", PI * 0.5, Color("b8e6c9"))
	_add_orbit_label("September equinox", PI * 1.5, Color("d8f5df"))

	# Earth on its tilted pivot.
	earth_pivot = Node3D.new()
	earth_pivot.name = "TiltedEarth"
	add_child(earth_pivot)
	earth_spin = Node3D.new()
	earth_pivot.add_child(earth_spin)
	earth_mesh = MeshInstance3D.new()
	var em := SphereMesh.new()
	em.radius = EARTH_R
	em.height = EARTH_R * 2.0
	em.radial_segments = 48
	em.rings = 24
	earth_mesh.mesh = em
	var emat := ShaderMaterial.new()
	emat.shader = load("res://shaders/earth.gdshader")
	earth_mesh.material_override = emat
	earth_spin.add_child(earth_mesh)

	axis_group = Node3D.new()
	earth_pivot.add_child(axis_group)
	var ax := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.035
	am.bottom_radius = 0.035
	am.height = EARTH_R * 3.2
	ax.mesh = am
	var axm := StandardMaterial3D.new()
	axm.albedo_color = Color(G.GOLD, 0.9)
	axm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ax.material_override = axm
	axis_group.add_child(ax)
	var cap := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.13
	cm.height = 0.26
	cm.radial_segments = 12
	cm.rings = 6
	cap.mesh = cm
	cap.position.y = EARTH_R * 1.6
	cap.material_override = axm
	axis_group.add_child(cap)
	var nlab := Label3D.new()
	nlab.text = "N"
	nlab.font = UI.body_med_font()
	nlab.font_size = 48
	nlab.pixel_size = 0.012
	nlab.modulate = G.GOLD
	nlab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nlab.no_depth_test = true
	nlab.position.y = EARTH_R * 1.8
	axis_group.add_child(nlab)

	# A little glow around Earth so it reads at a distance.
	var eglow := Sprite3D.new()
	eglow.texture = load("res://assets/fx/glow.png")
	eglow.pixel_size = 0.014
	eglow.scale = Vector3.ONE * 5.0
	eglow.modulate = Color(0.35, 0.58, 1.0, 0.3)
	eglow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	eglow.shaded = false
	earth_pivot.add_child(eglow)

	_update_positions()


func _add_orbit_label(text: String, angle: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = UI.serif_font()
	l.font_size = 40
	l.pixel_size = 0.012
	l.modulate = color
	l.outline_size = 6
	l.outline_modulate = Color(0.01, 0.02, 0.05, 0.9)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = Vector3(cos(angle) * (ORBIT_R + 3.2), 0.85, sin(angle) * (ORBIT_R + 3.2))
	if is_equal_approx(angle, 0.0):
		# December sits at the right edge of the canvas; keep its label inside
		# the orbit so the control panel never crops it.
		l.position = Vector3(ORBIT_R - 0.2, 3.4, 0)
	elif is_equal_approx(angle, PI):
		# June is parked on Earth; give the label room outside the planet.
		l.position = Vector3(-(ORBIT_R + 5.0), 1.4, 0)
	add_child(l)


func _update_positions() -> void:
	if not earth_pivot:
		return
	var angle := PI + TAU * (month - 6.0) / 12.0
	earth_pivot.position = Vector3(cos(angle) * ORBIT_R, 0, sin(angle) * ORBIT_R)
	earth_pivot.rotation.z = -deg_to_rad(tilt)
	if sun_light:
		sun_light.look_at_from_position(Vector3.ZERO, earth_pivot.position, Vector3.UP)
	if current_mark:
		current_mark.position = earth_pivot.position


func _build_current_mark() -> void:
	current_mark = MeshInstance3D.new()
	var m := QuadMesh.new()
	m.size = Vector2(0.5, 0.5)
	current_mark.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = load("res://assets/fx/ring.png")
	mat.albedo_color = Color(G.GOLD, 0.9)
	current_mark.material_override = mat
	add_child(current_mark)
	current_mark.position.y = 0.02


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		cam.position = Vector3(0, 38, 36)
		cam.fov = 66.0
		cam.look_at(Vector3(0, -13.0, 0), Vector3.UP)
	else:
		cam.position = Vector3(0, 20, 26)
		cam.fov = 54.0
		cam.look_at(Vector3(1.6, -1.2, 0), Vector3.UP)


func _build_ui() -> void:
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.theme()
	add_child(ui_root)
	if current_mark == null:
		_build_current_mark()

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui_root.add_child(vignette)
	ui_root.add_child(UI.scrim(true, 140, 0.6))

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

	panel = UI.panel(15, 0.92)
	if UI.is_portrait():
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(v)
		v.add_child(UI.spacer(true, true))
		panel.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y * 0.48, 320, 440))
		panel.size_flags_vertical = Control.SIZE_SHRINK_END
		v.add_child(panel)
	else:
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(h)
		h.add_child(UI.spacer(true, false))
		panel.custom_minimum_size = Vector2(372, 0)
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.add_child(panel)
	_fill_panel()
	_portrait = UI.is_portrait()
	_place_camera()
	UI.fade_in(ui_root, 0.05, 0.6)


func _top_bar() -> Control:
	var acts: Array = [{"text": "LESSON", "fn": func(): _show_learn()}]
	if not UI.is_compact():
		acts.append({"text": "SKY ATLAS", "fn": func(): Router.go("res://scenes/Atlas.tscn")})
	return UI.app_bar("The Turning Year", "SEASONS & TILT  ·  A MOVING EARTH", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB")


func _fill_panel() -> void:
	for c in panel.get_children():
		c.queue_free()
	var scroll := UI.scroll()
	panel.add_child(scroll)
	var v := UI.vbox(6)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	var hk := UI.micro("SEASON RIDDLES", Color(G.GOLD, 0.9), 8)
	hk.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(hk)
	head.add_child(UI.spacer())
	dots = UI.hbox(4)
	head.add_child(dots)

	prompt_label = UI.label("", 14, G.CREAM)
	v.add_child(prompt_label)
	feedback = UI.label("", 12, G.GOLD)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(feedback)
	v.add_child(UI.divider())

	month_label = UI.label("June", 22, G.CREAM, "serif")
	v.add_child(month_label)
	dist_label = UI.label("", 12, G.MUTED)
	v.add_child(dist_label)
	var ms := HSlider.new()
	ms.min_value = 1
	ms.max_value = 12
	ms.step = 0.05
	ms.value = month
	ms.custom_minimum_size = Vector2(0, 32)
	ms.value_changed.connect(func(val):
		month = val
		_solved = false
		_update_positions()
		_update_meters()
		if next_btn:
			next_btn.visible = false)
	v.add_child(ms)

	tilt_label = UI.label("Axial tilt: 23.4°", 13, G.GOLD)
	v.add_child(tilt_label)
	var ts := HSlider.new()
	ts.min_value = 0.0
	ts.max_value = 45.0
	ts.step = 0.1
	ts.value = tilt
	ts.custom_minimum_size = Vector2(0, 32)
	ts.value_changed.connect(func(val):
		tilt = val
		_solved = false
		_update_positions()
		_update_meters()
		if next_btn:
			next_btn.visible = false)
	v.add_child(ts)

	v.add_child(UI.divider())
	v.add_child(UI.micro("YOUR VIEW FROM KARNATAKA (13°N)", Color(G.GOLD, 0.9), 8))
	var day_row := UI.hbox(8)
	v.add_child(day_row)
	var dl := UI.label("Daylight", 12, G.MUTED)
	dl.custom_minimum_size = Vector2(58, 0)
	dl.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_row.add_child(dl)
	day_bar = ProgressBar.new()
	day_bar.min_value = 0
	day_bar.max_value = 24
	day_bar.show_percentage = false
	day_bar.custom_minimum_size = Vector2(0, 12)
	day_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	day_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_bar(day_bar, Color(G.TEAL, 0.75))
	day_row.add_child(day_bar)
	day_label = UI.label("12.8 h", 12, G.CREAM)
	day_label.custom_minimum_size = Vector2(48, 0)
	day_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	day_row.add_child(day_label)

	var alt_row := UI.hbox(8)
	v.add_child(alt_row)
	var al := UI.label("Noon Sun", 12, G.MUTED)
	al.custom_minimum_size = Vector2(58, 0)
	al.autowrap_mode = TextServer.AUTOWRAP_OFF
	alt_row.add_child(al)
	alt_bar = ProgressBar.new()
	alt_bar.min_value = 0
	alt_bar.max_value = 90
	alt_bar.show_percentage = false
	alt_bar.custom_minimum_size = Vector2(0, 12)
	alt_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alt_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_bar(alt_bar, Color(G.GOLD, 0.8))
	alt_row.add_child(alt_bar)
	alt_label = UI.label("79°", 12, G.CREAM)
	alt_label.custom_minimum_size = Vector2(48, 0)
	alt_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	alt_row.add_child(alt_label)

	check_btn = UI.button("Check this month", true, 16)
	check_btn.custom_minimum_size = Vector2(0, 46)
	check_btn.pressed.connect(_check)
	v.add_child(check_btn)
	next_btn = UI.button("Next riddle  ›", true, 16)
	next_btn.visible = false
	next_btn.pressed.connect(_advance)
	v.add_child(next_btn)

	var tools := UI.hbox(6)
	v.add_child(tools)
	var reset := UI.ghost_button("Reset tilt to 23.4°", 12)
	reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset.pressed.connect(func():
		tilt = 23.4
		ts.value = tilt
		_update_positions()
		_update_meters())
	tools.add_child(reset)
	var notilt := UI.ghost_button("No tilt at all", 12)
	notilt.pressed.connect(func():
		tilt = 0.0
		ts.value = 0.0
		_update_positions()
		_update_meters())
	tools.add_child(notilt)

	_update_panel()
	_update_meters()


func _style_bar(bar: ProgressBar, color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.07)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func _declination() -> float:
	return deg_to_rad(tilt) * sin(TAU * (month - 3.0) / 12.0)


func _day_hours() -> float:
	var lat := deg_to_rad(LATITUDE)
	var dec := _declination()
	var x := -tan(lat) * tan(dec)
	if x <= -1.0:
		return 24.0
	if x >= 1.0:
		return 0.0
	return 2.0 * rad_to_deg(acos(x)) / 15.0


func _noon_alt() -> float:
	var dec_deg := rad_to_deg(_declination())
	return clampf(90.0 - absf(LATITUDE - dec_deg), 0.0, 90.0)


func _update_meters() -> void:
	if month_label:
		month_label.text = MONTHS[int(clampf(round(month) - 1.0, 0.0, 11.0))]
	if dist_label:
		var d := 149.6 - 2.5 * cos(TAU * (month - 1.0) / 12.0)
		dist_label.text = "%.1f million km from the Sun" % d
	if tilt_label:
		tilt_label.text = "Axial tilt: %.1f°" % tilt
	if day_bar:
		day_bar.value = _day_hours()
		day_label.text = "%.1f h" % _day_hours()
	if alt_bar:
		alt_bar.value = _noon_alt()
		alt_label.text = "%d°" % int(round(_noon_alt()))


func _update_panel() -> void:
	var challenges: Array = G.content.get("seasons", {}).get("challenges", [])
	if challenge_index >= challenges.size():
		prompt_label.text = "All season riddles solved."
	else:
		prompt_label.text = str(challenges[challenge_index].get("prompt", ""))
	for c in dots.get_children():
		c.queue_free()
	var states := []
	for i in challenges.size():
		states.append(2 if i < challenge_index else (1 if i == challenge_index else 0))
	dots.add_child(UI.pip_row(states, 11.0))


func _check() -> void:
	var challenges: Array = G.content.get("seasons", {}).get("challenges", [])
	if challenge_index >= challenges.size():
		_show_finish()
		return
	var c: Dictionary = challenges[challenge_index]
	var ok := false
	match str(c.get("id", "")):
		"june":
			ok = absf(month - 6.0) <= 0.7 and tilt >= 10.0
		"december":
			ok = absf(month - 12.0) <= 0.7 and tilt >= 10.0
		"equinox":
			ok = (absf(month - 3.0) <= 0.7 or absf(month - 9.0) <= 0.7) and tilt >= 10.0
		"notilt":
			ok = tilt < 1.0 and absf(month - 6.0) <= 0.7
	if ok:
		_solved = true
		feedback.add_theme_color_override("font_color", G.TEAL)
		feedback.text = _praise(c)
		Sfx.play("success")
		challenge_index += 1
		_update_panel()
		next_btn.visible = true
		next_btn.text = "Finish the year  ›" if challenge_index >= challenges.size() else "Next riddle  ›"
		if challenge_index >= challenges.size():
			pass
	else:
		feedback.add_theme_color_override("font_color", G.ROSE)
		feedback.text = _nudge(str(c.get("id", "")))


func _praise(c: Dictionary) -> String:
	match str(c.get("id", "")):
		"june": return "June solstice: the north pole leans toward the Sun. India gets its highest noon Sun and its longest days."
		"december": return "December solstice: the north pole leans away. The noon Sun is low and the days are short."
		"equinox": return "Equinox: the terminator passes through both poles, so day and night are almost equal everywhere."
		"notilt": return "With no tilt, every day is about 12 hours at every latitude — and the seasons vanish. Tilt is the whole story."
	return "That is the geometry."


func _nudge(id: String) -> String:
	match id:
		"june": return "Not yet. Look for the month when the north pole leans most toward the Sun — around mid-year."
		"december": return "Not yet. Find the month when the north pole leans away from the Sun."
		"equinox": return "Not yet. Look for a month when Earth's axis is side-on to the Sun."
		"notilt": return "Set the axial tilt close to 0° in June and watch the daylight bar."
	return "Try another position."


func _advance() -> void:
	if challenge_index >= G.content.get("seasons", {}).get("challenges", []).size():
		G.complete("seasons")
		_show_finish()
	else:
		next_btn.visible = false
		feedback.text = ""
		_update_panel()


func _show_finish() -> void:
	completed = true
	G.complete("seasons")
	var facts: Array = G.content.get("seasons", {}).get("facts", [])
	Overlay.info(ui_root, "The Turning Year", "SEASONS  ·  AXIAL TILT",
		["You found the solstices, an equinox, and the experiment that removes the seasons entirely. Earth's 23.4° tilt — not its distance from the Sun — is the reason for summer and winter.",
		 "Notice how little the day length changes at 13°N compared with the noon Sun's height. Near the equator, the Sun's angle does most of the seasonal work."],
		facts, "res://assets/art/card_seasons.webp", "Keep exploring")


func _show_learn() -> void:
	G.show_briefing("seasons")


func _process(delta: float) -> void:
	if earth_spin:
		earth_spin.rotation.y += delta * 0.16
	if current_mark:
		current_mark.rotation.y += delta * 0.4


func _on_resize() -> void:
	_place_camera()
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_build_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_on_resize()

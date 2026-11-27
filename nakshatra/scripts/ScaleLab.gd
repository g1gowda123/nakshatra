extends Node3D
## The Long Road: an orrery, a size chart, and an honest light-minute ruler.

const EARTH_RADIUS_KM := 6371.0

var sky: SkyDome
var cam: Camera3D
var ui_root: Control
var planets: Array = []
var planet_nodes: Array[Node3D] = []
var planet_meshes: Array[MeshInstance3D] = []
var planet_areas: Array[Area3D] = []
var planet_angles: Array[float] = []
var planet_radii: Array[float] = []
var selected := -1
var riddle_index := 0
var completed := false
var t := 0.0
var _orbits: MeshInstance3D
var _highlight_ring: MeshInstance3D

var panel: PanelContainer
var prompt_label: Label
var feedback_label: Label
var fact_title: Label
var fact_body: RichTextLabel
var chips: GridContainer
var riddle_dots: HBoxContainer
var info_box: VBoxContainer
var next_btn: Button


func _ready() -> void:
	planets = G.content.get("planets", [])
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)
	G.maybe_briefing(ui_root, "scale")


func _planet_color(i: int) -> Color:
	return Color(str(planets[i].get("color", "cccccc")))


func _orbit_radius(i: int) -> float:
	var au := float(planets[i].get("au", 1.0))
	return 3.2 + sqrt(au) * 2.15


func _planet_size(i: int) -> float:
	var r := float(planets[i].get("radius_km", 6371.0))
	return clampf(0.28 + log(r / 2400.0) * 0.22, 0.28, 0.9)


func _build_world() -> void:
	sky = SkyDome.new()
	sky.latitude_deg = 0.0
	add_child(sky)
	sky.set_modern_lines(false)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.25
	if sky.sky_material:
		sky.sky_material.set_shader_parameter("horizon_color", Color(0.02, 0.03, 0.07))
		sky.sky_material.set_shader_parameter("glow_color", Color(0.03, 0.03, 0.04))
		sky.sky_material.set_shader_parameter("milky_strength", 0.28)

	cam = Camera3D.new()
	cam.fov = 56.0
	cam.near = 0.1
	cam.far = 4000.0
	add_child(cam)
	_place_camera()

	var light := DirectionalLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.85)
	light.light_energy = 1.35
	light.shadow_enabled = false
	add_child(light)
	light.look_at_from_position(Vector3(0, 18, 12), Vector3.ZERO, Vector3.UP)

	# The Sun.
	var sun := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.55
	sm.height = 3.1
	sm.radial_segments = 32
	sm.rings = 16
	sun.mesh = sm
	var smat := ShaderMaterial.new()
	smat.shader = load("res://shaders/sun.gdshader")
	sun.material_override = smat
	add_child(sun)
	var sun_lab := Label3D.new()
	sun_lab.text = "SUN"
	sun_lab.font = UI.serif_font()
	sun_lab.font_size = 38
	sun_lab.pixel_size = 0.018
	sun_lab.modulate = G.GOLD
	sun_lab.outline_size = 6
	sun_lab.outline_modulate = Color(0.01, 0.02, 0.05, 0.9)
	sun_lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sun_lab.no_depth_test = true
	sun_lab.position = Vector3(0, 3.5, 0)
	add_child(sun_lab)
	var sun_glow := Sprite3D.new()
	sun_glow.texture = load("res://assets/fx/glow.png")
	sun_glow.pixel_size = 0.02
	sun_glow.scale = Vector3.ONE * 5.0
	sun_glow.modulate = Color(1.0, 0.76, 0.4, 0.8)
	sun_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sun_glow.shaded = false
	add_child(sun_glow)

	_build_orbits()

	for i in planets.size():
		var p: Dictionary = planets[i]
		var node := Node3D.new()
		node.name = str(p.get("name", "Planet"))
		add_child(node)
		var radius := _planet_size(i)
		planet_radii.append(radius)
		var mesh := MeshInstance3D.new()
		var mm := SphereMesh.new()
		mm.radius = radius
		mm.height = radius * 2.0
		mm.radial_segments = 32 if i < 5 else 24
		mm.rings = 16
		mesh.mesh = mm
		if i == 2:
			mesh.material_override = _earth_material()
		else:
			mesh.material_override = _planet_material(i)
		node.add_child(mesh)
		planet_meshes.append(mesh)
		planet_nodes.append(node)

		var glow := Sprite3D.new()
		glow.texture = load("res://assets/fx/glow.png")
		glow.pixel_size = 0.012
		glow.scale = Vector3.ONE * (1.5 + radius * 1.5)
		glow.modulate = Color(_planet_color(i), 0.5)
		glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glow.shaded = false
		node.add_child(glow)

		var plab := Label3D.new()
		plab.text = str(p.get("name", ""))
		plab.font = UI.body_med_font()
		plab.font_size = 34
		plab.pixel_size = 0.018
		plab.modulate = Color(0.95, 0.90, 0.78, 0.85)
		plab.outline_size = 5
		plab.outline_modulate = Color(0.01, 0.02, 0.05, 0.9)
		plab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		plab.no_depth_test = true
		var lift := 0.55
		if i == 0:
			lift = 1.35
		elif i == 1:
			lift = 0.50
		elif i == 2:
			lift = 1.25
		elif i == 3:
			lift = 0.45
		elif i == 4:
			lift = 0.85
		plab.position = Vector3(0, radius + lift, 0)
		plab.visible = not (UI.is_compact() and i < 4)
		node.add_child(plab)

		if i == 5:
			var ring := MeshInstance3D.new()
			ring.mesh = _ring_mesh(radius * 1.5, radius * 2.5)
			var rmat := StandardMaterial3D.new()
			rmat.albedo_color = Color(0.9, 0.82, 0.62, 0.65)
			rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			rmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ring.material_override = rmat
			ring.rotation_degrees = Vector3(18, 0, 8)
			node.add_child(ring)

		var area := Area3D.new()
		area.collision_layer = 1
		area.collision_mask = 0
		area.monitoring = false
		area.monitorable = true
		area.set_meta("planet_index", i)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = maxf(0.7, radius * 1.6)
		shape.shape = sphere
		area.add_child(shape)
		node.add_child(area)
		planet_areas.append(area)

		planet_angles.append(float(i) * 0.85 + 0.4)

	_update_orbits()

	# highlight ring
	_highlight_ring = MeshInstance3D.new()
	var hm := ImmediateMesh.new()
	hm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for k in 97:
		var a := TAU * k / 96.0
		hm.surface_set_color(Color(G.GOLD, 0.9))
		hm.surface_add_vertex(Vector3(cos(a), 0, sin(a)))
	hm.surface_end()
	var hmat := ShaderMaterial.new()
	hmat.shader = load("res://shaders/line.gdshader")
	hmat.set_shader_parameter("alpha", 1.0)
	_highlight_ring.mesh = hm
	_highlight_ring.material_override = hmat
	_highlight_ring.visible = false
	add_child(_highlight_ring)


func _earth_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/earth.gdshader")
	return m


func _planet_material(i: int) -> ShaderMaterial:
	var p: Dictionary = planets[i]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/planet.gdshader")
	var base := _planet_color(i)
	var accent := base.lightened(0.22)
	var bands := 0.55
	var freq := 16.0
	match str(p.get("name", "")):
		"Mercury": bands = 0.12; accent = base.darkened(0.2)
		"Venus": bands = 0.28; accent = Color("fff1cd"); freq = 8.0
		"Mars": bands = 0.2; accent = base.darkened(0.25)
		"Jupiter": bands = 0.75; accent = Color("f2e2c4"); freq = 22.0
		"Saturn": bands = 0.55; accent = Color("f7e8b8"); freq = 18.0
		"Uranus": bands = 0.2; accent = Color("c9f5f2"); freq = 10.0
		"Neptune": bands = 0.35; accent = Color("7f9dff"); freq = 12.0
	m.set_shader_parameter("base_color", base)
	m.set_shader_parameter("accent_color", accent)
	m.set_shader_parameter("bands", bands)
	m.set_shader_parameter("band_freq", freq)
	m.set_shader_parameter("mottle", 0.22)
	return m


func _ring_mesh(inner: float, outer: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var segs := 64
	for s in segs:
		var a0 := TAU * s / segs
		var a1 := TAU * (s + 1) / segs
		var p0 := Vector3(cos(a0) * inner, 0, sin(a0) * inner)
		var p1 := Vector3(cos(a0) * outer, 0, sin(a0) * outer)
		var p2 := Vector3(cos(a1) * outer, 0, sin(a1) * outer)
		var p3 := Vector3(cos(a1) * inner, 0, sin(a1) * inner)
		for v in [p0, p1, p2, p0, p2, p3]:
			verts.append(v)
			normals.append(Vector3.UP)
			uvs.append(Vector2(v.x, v.z))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_orbits() -> void:
	_orbits = MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in planets.size():
		var r := _orbit_radius(i)
		var segs := 96
		for s in segs:
			var a0 := TAU * s / segs
			var a1 := TAU * (s + 1) / segs
			im.surface_set_color(Color(G.GOLD, 0.16 + (0.12 if i == 2 else 0.0)))
			im.surface_add_vertex(Vector3(cos(a0) * r, 0, sin(a0) * r))
			im.surface_set_color(Color(G.GOLD, 0.16 + (0.12 if i == 2 else 0.0)))
			im.surface_add_vertex(Vector3(cos(a1) * r, 0, sin(a1) * r))
	im.surface_end()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/line.gdshader")
	mat.set_shader_parameter("alpha", 0.9)
	_orbits.mesh = im
	_orbits.material_override = mat
	add_child(_orbits)


func _update_orbits() -> void:
	for i in planets.size():
		var r := _orbit_radius(i)
		var a := planet_angles[i]
		planet_nodes[i].position = Vector3(cos(a) * r, 0, sin(a) * r)
		planet_nodes[i].rotation.y += 0.01


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		cam.position = Vector3(0, 58, 52)
		cam.fov = 64.0
		cam.look_at(Vector3(2.0, -8.0, 0), Vector3.UP)
	else:
		cam.position = Vector3(-1.0, 40, 38)
		cam.fov = 52.0
		cam.look_at(Vector3(4.2, -4.8, 0), Vector3.UP)


func _build_ui() -> void:
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

	panel = UI.panel(16, 0.92)
	if UI.is_portrait():
		var v := VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(v)
		v.add_child(UI.spacer(true, true))
		panel.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y * 0.45, 300, 420))
		panel.size_flags_vertical = Control.SIZE_SHRINK_END
		v.add_child(panel)
	else:
		var h := HBoxContainer.new()
		h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(h)
		h.add_child(UI.spacer(true, false))
		panel.custom_minimum_size = Vector2(370, 0)
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		h.add_child(panel)
	_portrait = UI.is_portrait()
	_fill_panel()
	_place_camera()
	UI.fade_in(ui_root, 0.05, 0.6)


func _top_bar() -> Control:
	var acts: Array = [{"text": "LESSON", "fn": func(): _show_learn()}]
	if not UI.is_compact():
		acts.append({"text": "SKY ATLAS", "fn": func(): Router.go("res://scenes/Atlas.tscn")})
	return UI.app_bar("The Long Road", "SOLAR SYSTEM SCALE  ·  A TRUE DISTANCE", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB")


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
	var hk := UI.micro("SKY RIDDLES", Color(G.GOLD, 0.9), 8)
	hk.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(hk)
	head.add_child(UI.spacer())
	riddle_dots = UI.hbox(4)
	head.add_child(riddle_dots)

	prompt_label = UI.label("", 14, G.CREAM)
	v.add_child(prompt_label)
	feedback_label = UI.label("", 12, G.GOLD)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(feedback_label)
	v.add_child(UI.divider())

	fact_title = UI.label("Tap a planet", 22, G.CREAM, "serif")
	fact_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	v.add_child(fact_title)
	fact_body = UI.rich("The orrery is a diagram, not a photograph: planet sizes and orbit spacing are compressed so they can share a screen. Use the Scale and Sizes buttons for the honest numbers.", 13, G.MUTED)
	v.add_child(fact_body)

	var chip_grid := GridContainer.new()
	chip_grid.columns = 4
	chip_grid.add_theme_constant_override("h_separation", 4)
	chip_grid.add_theme_constant_override("v_separation", 4)
	v.add_child(chip_grid)
	chips = chip_grid
	for i in planets.size():
		var chip := UI.ghost_button(str(planets[i].get("name", "")), 11)
		chip.custom_minimum_size = Vector2(0, 32)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.pressed.connect(func(): _select_planet(i, true))
		chips.add_child(chip)

	var tools := UI.hbox(6)
	v.add_child(tools)
	var scale := UI.ghost_button("Scale", 13)
	scale.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale.pressed.connect(_show_scale)
	tools.add_child(scale)
	var sizes := UI.ghost_button("Sizes", 13)
	sizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sizes.pressed.connect(_show_sizes)
	tools.add_child(sizes)
	var data := UI.ghost_button("Data", 13)
	data.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data.pressed.connect(_show_data)
	tools.add_child(data)

	next_btn = UI.button("Next riddle  ›", true, 16)
	next_btn.visible = false
	next_btn.pressed.connect(_advance_riddle)
	v.add_child(next_btn)

	_update_panel()


func _update_panel() -> void:
	if planets.is_empty():
		return
	var rid: Array = G.content.get("scale_riddles", [])
	if riddle_index >= rid.size():
		prompt_label.text = "All four riddles answered. The road is yours."
	else:
		prompt_label.text = str(rid[riddle_index].get("prompt", ""))
	for c in riddle_dots.get_children():
		c.queue_free()
	var states := []
	for i in rid.size():
		states.append(2 if i < riddle_index else (1 if i == riddle_index else 0))
	riddle_dots.add_child(UI.pip_row(states, 11.0))
	if next_btn:
		next_btn.visible = riddle_index < rid.size() and _riddle_solved


var _riddle_solved := false


func _select_planet(i: int, from_user: bool) -> void:
	selected = i
	var p: Dictionary = planets[i]
	var au := float(p.get("au", 1.0))
	var light_min := au * 8.317
	var widths := float(p.get("radius_km", EARTH_RADIUS_KM)) / EARTH_RADIUS_KM
	var year_days := float(p.get("year_days", 365.0))
	var year_text := "%d Earth days" % int(year_days)
	if year_days > 700:
		year_text = "%.1f Earth years" % (year_days / 365.25)
	fact_title.text = "%s  ·  %s" % [str(p.get("name", "")), str(p.get("kannada", ""))]
	fact_body.text = ("[b]%s[/b]\nDistance from the Sun: %.2f AU  (%.1f light-minutes)\n"
		+ "Width: %.2f Earths   ·   Year: %s\n\n%s") % [
			str(p.get("name", "")), au, light_min, widths, year_text, str(p.get("fact", ""))]
	_highlight_ring.visible = true
	_highlight_ring.scale = Vector3.ONE * _orbit_radius(i)
	_highlight_ring.position = Vector3(0, 0.01, 0)
	for k in planet_nodes.size():
		var s := 1.25 if k == i else 1.0
		planet_nodes[k].scale = planet_nodes[k].scale.lerp(Vector3.ONE * s, 0.2)
	Sfx.play("click")
	if from_user:
		_answer(i)


func _answer(i: int) -> void:
	var rid: Array = G.content.get("scale_riddles", [])
	if riddle_index >= rid.size() or _riddle_solved:
		return
	var answer := str(rid[riddle_index].get("answer", ""))
	if str(planets[i].get("name", "")) == answer:
		_riddle_solved = true
		feedback_label.add_theme_color_override("font_color", G.TEAL)
		feedback_label.text = "Correct — %s. %s" % [answer, _extra_fact(answer)]
		Sfx.play("success")
		if next_btn:
			next_btn.visible = true
			next_btn.text = "Finish the road  ›" if riddle_index >= rid.size() - 1 else "Next riddle  ›"
	else:
		feedback_label.add_theme_color_override("font_color", G.ROSE)
		feedback_label.text = "That is %s. Read its card, then try the clue again." % str(planets[i].get("name", ""))


func _extra_fact(name: String) -> String:
	match name:
		"Venus": return "Its thick CO₂ atmosphere traps heat — closer to the Sun does not always mean hotter."
		"Saturn": return "The rings are only about 10–100 m thick, though they span 2,82,000 km."
		"Mercury": return "It is small and close to the Sun, so it races around in just 88 days."
		"Uranus": return "Its 98° tilt probably came from a giant collision long ago."
	return ""


func _advance_riddle() -> void:
	var rid: Array = G.content.get("scale_riddles", [])
	riddle_index += 1
	_riddle_solved = false
	feedback_label.text = ""
	if riddle_index >= rid.size():
		G.complete("scale")
		_show_finish()
	else:
		_update_panel()
		Sfx.play("chime")


func _show_finish() -> void:
	var facts := [
		"If the Sun were a lantern in your hand, Earth would be a grain of sand about 15 paces away — and Neptune nearly half a kilometre off.",
		"Sunlight takes 8.3 minutes to reach Earth, but over 4 hours to reach Neptune.",
		"Jupiter is so large that about 1,300 Earths would fit inside it.",
	]
	Overlay.info(ui_root, "Road's end", "SOLAR SYSTEM  ·  SCALE",
		["You travelled from the Sun to Neptune. The solar system is mostly empty space. That emptiness is not a mistake in the drawing; it is the real thing."],
		facts, "res://assets/art/card_planets.webp", "Keep exploring")


var _compact := false


func _on_resize() -> void:
	_place_camera()
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_build_ui()


var _portrait := false


func _show_learn() -> void:
	G.show_briefing("scale")


func _show_scale() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.015, 0.036, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	overlay.add_child(center)
	var pan := UI.panel(UI.pad(), 0.98)
	pan.custom_minimum_size = Vector2(minf(680, UI.viewport_size().x - 28), 0)
	center.add_child(pan)
	var v := UI.vbox(7)
	pan.add_child(v)
	v.add_child(UI.micro("TRUE DISTANCES", Color(G.GOLD, 0.9), 8))
	v.add_child(UI.heading("The long, empty road", 28))
	v.add_child(UI.label("Bars are drawn to true proportion. One light-minute is about 1.8 crore km.", 13, G.MUTED))
	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.52, 380))
	v.add_child(scroll)
	var list := UI.vbox(5)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for p in planets:
		var row := UI.hbox(8)
		list.add_child(row)
		var nm := UI.label(str(p.get("name", "")), 13, G.CREAM)
		nm.custom_minimum_size = Vector2(78, 0)
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(nm)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 30.05
		bar.value = float(p.get("au", 1.0))
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.06)
		sb.set_corner_radius_all(2)
		var fb := StyleBoxFlat.new()
		fb.bg_color = Color(G.GOLD, 0.72)
		fb.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", sb)
		bar.add_theme_stylebox_override("fill", fb)
		row.add_child(bar)
		var val := UI.label("%.1f lm" % (float(p.get("au", 1.0)) * 8.317), 12, G.MUTED)
		val.custom_minimum_size = Vector2(58, 0)
		val.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(val)
	var close := UI.button("Back to the orrery", true, 16)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)


func _show_sizes() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.008, 0.015, 0.036, 0.9)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	overlay.add_child(center)
	var pan := UI.panel(UI.pad(), 0.98)
	pan.custom_minimum_size = Vector2(minf(680, UI.viewport_size().x - 28), 0)
	center.add_child(pan)
	var v := UI.vbox(7)
	pan.add_child(v)
	v.add_child(UI.micro("TRUE SIZES", Color(G.GOLD, 0.9), 8))
	v.add_child(UI.heading("How big is big?", 28))
	v.add_child(UI.label("Bars compare planet widths with Earth. The Sun is 109 Earths across — too big for this chart.", 13, G.MUTED))
	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.5, 380))
	v.add_child(scroll)
	var list := UI.vbox(5)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for p in planets:
		var widths := float(p.get("radius_km", EARTH_RADIUS_KM)) / EARTH_RADIUS_KM
		var row := UI.hbox(8)
		list.add_child(row)
		var nm := UI.label(str(p.get("name", "")), 13, G.CREAM)
		nm.custom_minimum_size = Vector2(78, 0)
		nm.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(nm)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 11.2
		bar.value = widths
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 14)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(1, 1, 1, 0.06)
		sb.set_corner_radius_all(2)
		var fb := StyleBoxFlat.new()
		fb.bg_color = Color(str(p.get("color", "cccccc")))
		fb.set_corner_radius_all(2)
		bar.add_theme_stylebox_override("background", sb)
		bar.add_theme_stylebox_override("fill", fb)
		row.add_child(bar)
		var val := UI.label("%.2f×" % widths, 12, G.MUTED)
		val.custom_minimum_size = Vector2(58, 0)
		val.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(val)
	var close := UI.button("Back to the orrery", true, 16)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)


func _show_data() -> void:
	var lines := []
	for p in planets:
		lines.append("%s — %.2f AU, %.1f light-minutes, %d km wide, %d-day year" % [
			str(p.get("name", "")), float(p.get("au", 1)), float(p.get("au", 1)) * 8.317,
			int(p.get("radius_km", 0)), int(p.get("year_days", 0))])
	Overlay.info(ui_root, "Planet data", "THE NUMBERS BEHIND THE ORRERY", lines, [], "res://assets/art/card_planets.webp", "Close")


func _unhandled_input(event: InputEvent) -> void:
	var pos := Vector2(-1, -1)
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pos = event.position
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pos = event.position
		pressed = true
	if not pressed:
		return
	var space := get_world_3d().direct_space_state
	var from := cam.project_ray_origin(pos)
	var to := from + cam.project_ray_normal(pos) * 2000.0
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return
	var col = hit.get("collider")
	if col and col.has_meta("planet_index"):
		_select_planet(int(col.get_meta("planet_index")), true)


func _process(delta: float) -> void:
	t += delta
	for i in planets.size():
		var au := float(planets[i].get("au", 1.0))
		planet_angles[i] += delta * 0.24 / sqrt(au)
	_update_orbits()
	if selected >= 0 and _highlight_ring:
		_highlight_ring.rotation.y += delta * 0.1

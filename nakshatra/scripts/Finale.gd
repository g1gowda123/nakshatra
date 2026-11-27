extends Node3D
## The lantern festival: a certificate, a hundred rising lights, a sky that answers.

var sky: SkyDome
var cam: Camera3D
var ui_root: Control
var lanterns: Array[Node3D] = []
var speeds: Array[float] = []
var phases: Array[float] = []


func _ready() -> void:
	_build_world()
	_build_ui()
	set_process(true)


func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 56.0
	cam.position = Vector3(0, 7, 21)
	add_child(cam)
	cam.look_at(Vector3(0, 15, -25), Vector3.UP)

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 118.0
	add_child(sky)
	sky.set_modern_lines(true)
	sky.set_nakshatra_lines(false)
	if sky.modern_lines and sky.modern_lines.material_override:
		(sky.modern_lines.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.55)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.4

	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 180.0
	gm.bottom_radius = 180.0
	gm.height = 1.0
	ground.mesh = gm
	ground.position = Vector3(0, -0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("070c12")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = mat
	add_child(ground)

	var hill := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 1.0
	hs.height = 1.0
	hill.mesh = hs
	hill.position = Vector3(-6, -5.5, -26)
	hill.scale = Vector3(34, 9, 22)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color("0a121a")
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hill.material_override = hm
	add_child(hill)

	for i in 26:
		var n := Node3D.new()
		n.position = Vector3(randf_range(-30, 30), randf_range(1, 30), randf_range(-45, -2))
		add_child(n)
		var body := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.12, 0.3)
		sm.height = sm.radius * 2.0
		body.mesh = sm
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.albedo_color = Color(1.0, 0.76, 0.4)
		bm.emission_enabled = true
		bm.emission = Color(1.0, 0.62, 0.28)
		bm.emission_energy_multiplier = 1.8
		body.material_override = bm
		n.add_child(body)
		var glow := Sprite3D.new()
		glow.texture = load("res://assets/fx/glow.png")
		glow.pixel_size = 0.012
		glow.scale = Vector3.ONE * randf_range(1.8, 3.6)
		glow.modulate = Color(1.0, 0.76, 0.44, 0.65)
		glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glow.shaded = false
		n.add_child(glow)
		lanterns.append(n)
		speeds.append(randf_range(0.25, 0.8))
		phases.append(randf() * TAU)


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

	ui_root.add_child(UI.print_frame(16))

	var horizon: Control = preload("res://scripts/FinaleHorizon.gd").new()
	ui_root.add_child(horizon)

	var outer := UI.margin(UI.pad() + 4, 22, UI.pad() + 4, 16)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(outer)
	var col := UI.vbox(0)
	outer.add_child(col)
	col.add_child(UI.app_bar("The Lantern Festival", "THE SKY ANSWERS  ·  SEVEN LANTERNS LIT", "res://scenes/Lab.tscn", [], Vector2i(-1, -1), "THE SKY LAB"))

	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(center)

	if not G.all_done():
		center.add_child(_not_yet_card())
	else:
		center.add_child(_certificate())
	ui_root.add_child(UI.grain(0.04))
	UI.fade_in(ui_root, 0.05, 0.8)


func _not_yet_card() -> Control:
	var p := UI.panel(UI.pad(), 0.96)
	p.custom_minimum_size = Vector2(minf(560, UI.viewport_size().x - 44), 0)
	var v := UI.vbox(12)
	p.add_child(v)
	v.add_child(UI.micro("THE LANTERNS ARE WAITING", Color(G.GOLD, 0.9), 9))
	var lit := G.done_count()
	var left := G.MODULES.size() - lit
	var headline := "The hill is dark. Seven are waiting."
	if lit == 1:
		headline = "One lantern is lit. Six are waiting."
	elif lit > 1:
		headline = "%d lanterns are lit. %d are waiting." % [lit, left]
	v.add_child(UI.heading(headline, 32))
	v.add_child(UI.label("Seven lanterns must burn before the town can light its own. You have lit %d of %d." % [G.done_count(), G.MODULES.size()], 15, Color(G.MUTED, 0.95)))
	v.add_child(UI.progress_pips(G.done_count(), G.MODULES.size(), 9.0))
	v.add_child(UI.rule(Color(G.GOLD, 0.18), 1))
	for id in G.MODULES:
		var row := UI.hbox(8)
		v.add_child(row)
		var mark := UI.micro("LIT" if G.is_done(id) else "—", G.TEAL if G.is_done(id) else Color(G.MUTED, 0.6), 9)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mark)
		var lbl := UI.label(str(G.module_info(id).get("title", id)), 14, G.CREAM if G.is_done(id) else Color(G.MUTED, 0.85))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
	v.add_child(UI.rule(Color(G.GOLD, 0.18), 1))
	var back := UI.button("Back to the sky lab   ›", true, 16)
	back.custom_minimum_size = Vector2(240, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func(): Router.go("res://scenes/Lab.tscn"))
	v.add_child(back)
	return p


func _certificate() -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 10)
	wrap.mouse_filter = Control.MOUSE_FILTER_PASS
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = G.PAPER
	sb.border_color = Color("6b4f2a", 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 24
	sb.content_margin_bottom = 22
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 12)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(minf(520, UI.viewport_size().x - 48), 0)
	wrap.add_child(p)

	var v := UI.vbox(5)
	p.add_child(v)
	var top := UI.micro("CHANDRAGIRI   ·   THE SKY WEAVERS", Color("8a6a3c"), 9)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(top)
	var title := UI.label("Sky Weaver", 46 if not UI.is_compact() else 38, G.INK, "serif")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var line := UI.label("This night, the sky was read true.", 14, G.INK_SOFT)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(line)

	var name_edit := LineEdit.new()
	name_edit.text = G.player_name
	name_edit.placeholder_text = "Write your name"
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.add_theme_font_override("font", UI.serif_font())
	name_edit.add_theme_font_size_override("font_size", 28)
	name_edit.add_theme_color_override("font_color", G.INK)
	name_edit.add_theme_color_override("font_placeholder_color", Color("8a6a3c", 0.7))
	var nsb := StyleBoxFlat.new()
	nsb.bg_color = Color(1, 1, 1, 0.0)
	nsb.border_color = Color(G.INK, 0.5)
	nsb.set_border_width_all(0)
	nsb.border_width_bottom = 1
	nsb.content_margin_left = 8
	nsb.content_margin_right = 8
	nsb.content_margin_top = 4
	nsb.content_margin_bottom = 2
	name_edit.add_theme_stylebox_override("normal", nsb)
	name_edit.add_theme_stylebox_override("focus", nsb)
	name_edit.text_changed.connect(func(t):
		G.player_name = t
		G.save_game())
	v.add_child(name_edit)

	var desc := UI.label("for reading seven lanterns of the night sky", 12, G.INK_SOFT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(desc)
	v.add_child(UI.rule(Color(G.INK, 0.22), 1))

	var stats := UI.micro("SEVEN LANTERNS LIT  ·  RIDDLES: %d OF %d CORRECT" % [G.quiz_best, G.content.get("quiz", []).size()], Color("6b4f2a"), 8)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(stats)
	var topics := UI.label("Moon phases  ·  Saptarishi  ·  the long road  ·  the turning year\nsolar storms  ·  black holes  ·  sky riddles", 10, Color(G.INK_SOFT, 0.9))
	topics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(topics)
	var seal_row := CenterContainer.new()
	v.add_child(seal_row)
	seal_row.add_child(UI.brand_mark(34))

	var row: BoxContainer = UI.vbox(8) if UI.is_compact() else UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	wrap.add_child(row)
	var back := UI.button("Return to the hill   →", true, 16)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func(): Router.go("res://scenes/Lab.tscn"))
	row.add_child(back)
	var atlas := UI.button("Sky Atlas", false, 15)
	atlas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atlas.pressed.connect(func(): Router.go("res://scenes/Atlas.tscn"))
	row.add_child(atlas)
	var note := UI.micro("TAKE A SCREENSHOT TO KEEP THIS PAGE  ·  EVERYTHING STAYS ON YOUR DEVICE", Color(G.MUTED, 0.7), 8)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(note)
	return wrap


func _process(delta: float) -> void:
	for i in lanterns.size():
		phases[i] += delta * 0.7
		lanterns[i].position.y += speeds[i] * delta
		lanterns[i].position.x += sin(phases[i]) * delta * 0.15
		if lanterns[i].position.y > 42.0:
			lanterns[i].position.y = -1.0
			lanterns[i].position.x = randf_range(-30, 30)
			lanterns[i].position.z = randf_range(-45, -2)
	if cam:
		cam.position.x = sin(Time.get_ticks_msec() * 0.00008) * 0.8

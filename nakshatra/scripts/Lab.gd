extends Node3D
## The hilltop Sky Lab. Every exhibit is open from the first second.

const MODULE_SCENES := {
	"moon": "res://scenes/MoonLab.tscn",
	"stars": "res://scenes/StarLab.tscn",
	"scale": "res://scenes/ScaleLab.tscn",
	"seasons": "res://scenes/SeasonLab.tscn",
	"flares": "res://scenes/SolarLab.tscn",
	"blackhole": "res://scenes/BlackHoleLab.tscn",
	"quiz": "res://scenes/QuizLab.tscn",
}

const ORDER := ["moon", "stars", "scale", "seasons", "flares", "blackhole", "quiz"]

## Compact cards cannot hold the long catalogue tags; these are the
## short forms that read cleanly at phone width.
const SHORT_TAG := {"flares": "Space weather", "blackhole": "Gravity & time"}

var sky: SkyDome
var cam: Camera3D
var hill: SkyHill
var ui_root: Control
var card_list: VBoxContainer
var lanterns: Dictionary = {}
var note_title: Label
var note_body: Label
var _wheel_done: Array = []
var _selected_id := ""
var _node_buttons: Dictionary = {}
var _hovered_id := ""
var _pointer := Vector2(-1, -1)
var _portrait := false
var _compact := false
var _move_t := 0.0
var _base_cam_pos := Vector3(0, 6.4, 17.0)
var _base_look := Vector3(0, 4.0, -2.0)
var _story_overlay: Control


func _ready() -> void:
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	G.language_changed.connect(_rebuild_ui)
	G.progress_changed.connect(_refresh_progress)
	set_process(true)
	if G.pending_guide:
		G.pending_guide = false
		await get_tree().process_frame
		G.show_field_guide()
	if G.last_completed != "":
		_celebrate_return.call_deferred()


func _celebrate_return() -> void:
	var id := G.last_completed
	G.last_completed = ""
	if not lanterns.has(id) or lanterns[id] == null:
		return
	await get_tree().create_timer(0.7).timeout
	if not is_inside_tree() or not lanterns.has(id) or lanterns[id] == null:
		return
	lanterns[id].set_done(false)
	lanterns[id].light_up()
	var title := str(G.module_info(id).get("title", id))
	var toast := UI.tracked("%s  ·  LIT" % title.to_upper(), 9, Color(G.GOLD, 0.95), 2)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast.offset_top = 86
	toast.offset_bottom = 106
	toast.modulate.a = 0.0
	ui_root.add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.3)
	tw.tween_interval(1.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.5)
	tw.tween_callback(toast.queue_free)


func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.position = _base_cam_pos
	add_child(cam)
	_place_camera()

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 108.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_star_scale(1.28)
	sky.set_star_intensity(1.12)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.66

	# The hill, observatory, path, grass and all seven lanterns are one
	# hand-built world object, so the hub scene stays readable and reusable.
	hill = SkyHill.new()
	hill.name = "SkyHill"
	add_child(hill)
	hill.build(true)
	lanterns = hill.lanterns
	hill.lantern_chosen.connect(_open_module)


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		_base_cam_pos = Vector3(0, 10.5, 32.0)
		_base_look = Vector3(0, 3.2, -2.0)
		cam.fov = 72.0
	else:
		_base_cam_pos = Vector3(0, 6.4, 17.0)
		_base_look = Vector3(0, 4.0, -2.0)
		cam.fov = 58.0
	cam.position = _base_cam_pos
	cam.look_at(_base_look, Vector3.UP)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 150.0
	gm.bottom_radius = 150.0
	gm.height = 1.2
	ground.mesh = gm
	ground.position = Vector3(0, -0.6, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("0d1720")
	mat.roughness = 1.0
	ground.material_override = mat
	add_child(ground)

	# A soft hill under the observatory, and distant layered ridges.
	var mound := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 10.0
	sm.height = 10.0
	sm.radial_segments = 24
	sm.rings = 12
	mound.mesh = sm
	mound.position = Vector3(-7, -5.6, -14)
	mound.scale = Vector3(1.5, 0.55, 1.1)
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color("0e1a22")
	mm.roughness = 1.0
	mound.material_override = mm
	add_child(mound)

	for spec in [
		{"pos": Vector3(-44, -7, -78), "scale": Vector3(64, 19, 40), "color": "0a121d"},
		{"pos": Vector3(38, -6, -96), "scale": Vector3(70, 17, 44), "color": "09101a"},
		{"pos": Vector3(0, -4, -58), "scale": Vector3(48, 10, 22), "color": "0b1520"},
	]:
		var ridge := MeshInstance3D.new()
		var rs := SphereMesh.new()
		rs.radius = 1.0
		rs.height = 1.0
		rs.radial_segments = 24
		rs.rings = 12
		ridge.mesh = rs
		ridge.position = spec["pos"]
		ridge.scale = spec["scale"]
		var rm := StandardMaterial3D.new()
		rm.albedo_color = Color(spec["color"])
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ridge.material_override = rm
		add_child(ridge)

	# Winding stone path to the lantern arc.
	var path := MeshInstance3D.new()
	var pm := ImmediateMesh.new()
	pm.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var pts: Array[Vector2] = []
	for i in 26:
		var t := i / 25.0
		var z := lerpf(11.0, -3.5, t)
		var x := sin(t * 2.4) * 1.6
		pts.append(Vector2(x, z))
	for i in pts.size():
		var p := pts[i]
		var w := 0.85 + sin(i * 0.7) * 0.12
		pm.surface_add_vertex(Vector3(p.x - w, 0.02, p.y))
		pm.surface_add_vertex(Vector3(p.x + w, 0.02, p.y))
	pm.surface_end()
	path.mesh = pm
	var path_mat := StandardMaterial3D.new()
	path_mat.albedo_color = Color("232a34")
	path_mat.roughness = 1.0
	path.material_override = path_mat
	add_child(path)


func _build_observatory() -> void:
	var obs := Node3D.new()
	obs.name = "Observatory"
	obs.position = Vector3(-7.0, 0.0, -14.0)
	add_child(obs)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color("253044")
	wall_mat.roughness = 0.85
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_color = Color("151f30")
	dome_mat.metallic = 0.5
	dome_mat.roughness = 0.5

	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 3.0
	bm.bottom_radius = 3.35
	bm.height = 2.4
	bm.radial_segments = 24
	base.mesh = bm
	base.position.y = 1.2
	base.material_override = wall_mat
	obs.add_child(base)

	var dome := MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 3.05
	dm.height = 3.05
	dm.is_hemisphere = true
	dm.radial_segments = 28
	dm.rings = 14
	dome.mesh = dm
	dome.position.y = 2.4
	dome.material_override = dome_mat
	obs.add_child(dome)

	var trim := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 2.95
	tm.outer_radius = 3.10
	tm.rings = 32
	tm.ring_segments = 6
	trim.mesh = tm
	trim.position.y = 2.4
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(G.GOLD, 0.7)
	trim_mat.metallic = 0.9
	trim_mat.roughness = 0.3
	trim.material_override = trim_mat
	obs.add_child(trim)

	var window := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(1.3, 0.9, 0.08)
	window.mesh = wm
	window.position = Vector3(0, 1.35, 2.96)
	var win_mat := StandardMaterial3D.new()
	win_mat.albedo_color = Color(1.0, 0.78, 0.46)
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.66, 0.32)
	win_mat.emission_energy_multiplier = 2.2
	window.material_override = win_mat
	obs.add_child(window)

	var telescope := MeshInstance3D.new()
	var tcm := CylinderMesh.new()
	tcm.top_radius = 0.16
	tcm.bottom_radius = 0.22
	tcm.height = 3.4
	telescope.mesh = tcm
	telescope.position = Vector3(0.4, 4.0, 1.1)
	telescope.rotation_degrees = Vector3(58, 0, -18)
	telescope.material_override = trim_mat
	obs.add_child(telescope)

	var warm := OmniLight3D.new()
	warm.position = Vector3(0, 1.4, 3.4)
	warm.light_color = Color(1.0, 0.72, 0.42)
	warm.light_energy = 1.1
	warm.omni_range = 7.0
	warm.shadow_enabled = false
	obs.add_child(warm)

	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.position = Vector3(0, 1.35, 3.1)
	glow.pixel_size = 0.012
	glow.scale = Vector3.ONE * 3.0
	glow.modulate = Color(1.0, 0.76, 0.44, 0.55)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	obs.add_child(glow)


func _tree(pos: Vector3, s: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.scale = Vector3.ONE * s
	add_child(root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("0a1418")
	mat.roughness = 1.0
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.12
	tm.bottom_radius = 0.2
	tm.height = 2.0
	trunk.mesh = tm
	trunk.position.y = 1.0
	trunk.material_override = mat
	root.add_child(trunk)
	for i in 3:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 1.5 - i * 0.35
		cm.height = 2.2
		cm.radial_segments = 8
		cone.mesh = cm
		cone.position.y = 2.1 + i * 0.85
		cone.material_override = mat
		root.add_child(cone)


func _build_trees() -> void:
	_tree(Vector3(-14, 0, -21), 1.35)
	_tree(Vector3(-20, 0, -28), 1.8)
	_tree(Vector3(11, 0, -18), 1.4)
	_tree(Vector3(17, 0, -25), 1.9)
	_tree(Vector3(22, 0, -12), 1.1)
	_tree(Vector3(-24, 0, -9), 1.0)


func _build_lanterns() -> void:
	var defs := [
		{"id": "scale", "angle": -78.0},
		{"id": "moon", "angle": -52.0},
		{"id": "stars", "angle": -26.0},
		{"id": "seasons", "angle": 0.0},
		{"id": "flares", "angle": 26.0},
		{"id": "blackhole", "angle": 52.0},
		{"id": "quiz", "angle": 78.0},
	]
	var center := Vector3(0, 0, -5.0)
	for d in defs:
		var id: String = d["id"]
		var a := deg_to_rad(float(d["angle"]))
		var pos := center + Vector3(sin(a) * 9.2, 0, cos(a) * 9.2)
		# Keep the whole arc in front of the camera.
		var l := SkyLantern.new()
		l.setup(id, str(G.module_info(id).get("title", id)), G.GOLD)
		l.position = pos
		l.done = G.is_done(id)
		add_child(l)
		l.chosen.connect(_open_module)
		lanterns[id] = l


func _build_fireflies() -> void:
	var p := CPUParticles3D.new()
	p.amount = 34
	p.lifetime = 7.0
	p.preprocess = 3.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(12, 3.2, 7)
	p.position = Vector3(0, 2.4, -4)
	p.direction = Vector3(0, 1, 0)
	p.spread = 70.0
	p.gravity = Vector3(0, 0.04, 0)
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.22
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.16
	p.color = Color(1.0, 0.85, 0.5, 0.9)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	p.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = load("res://assets/fx/glow.png")
	mat.vertex_color_use_as_albedo = true
	mat.disable_receive_shadows = true
	p.material_override = mat
	add_child(p)
	if G.reduced_motion:
		p.emitting = false


var _sky_lanterns: Array[Node3D] = []
var _sky_lantern_speeds: Array[float] = []


func _build_sky_lanterns() -> void:
	for i in 7:
		var n := Node3D.new()
		n.position = Vector3(randf_range(-22, 22), randf_range(9, 22), randf_range(-58, -34))
		add_child(n)
		var body := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.28
		sm.height = 0.55
		body.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.72, 0.36)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.62, 0.28)
		mat.emission_energy_multiplier = 1.6
		body.material_override = mat
		n.add_child(body)
		var sp := Sprite3D.new()
		sp.texture = load("res://assets/fx/glow.png")
		sp.pixel_size = 0.012
		sp.scale = Vector3.ONE * 1.5
		sp.modulate = Color(1.0, 0.76, 0.44, 0.6)
		sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sp.shaded = false
		n.add_child(sp)
		_sky_lanterns.append(n)
		_sky_lantern_speeds.append(randf_range(0.15, 0.4))


func _build_ui() -> void:
	if ui_root:
		ui_root.queue_free()
	_story_overlay = null
	_node_buttons.clear()
	_selected_id = ""
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
	var dim := ColorRect.new()
	dim.color = Color(0.030, 0.028, 0.024, 0.52)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(dim)
	ui_root.add_child(UI.scrim(false, 260, 0.72))

	if hill:
		hill.set_sign_visible(false)

	var col := UI.vbox(10)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(col)

	var top := _top_bar()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_right = -18
	top.offset_top = 48 if UI.is_compact() else 30
	col.add_child(top)

	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(mid)
	_star_wheel(mid)

	col.add_child(_hub_footer())
	ui_root.add_child(UI.grain(0.025))
	UI.fade_in(ui_root, 0.05, 0.65)


func _top_bar() -> Control:
	var row := UI.hbox(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var back := UI.link_button("‹", 16, Color(G.CREAM, 0.72))
	back.custom_minimum_size = Vector2(40, 38)
	back.pressed.connect(func():
		Sfx.play("click")
		Router.go("res://scenes/Boot.tscn"))
	row.add_child(back)
	row.add_child(UI.brand_mark(24))
	row.add_child(UI.spacer())
	var menu := UI.link_button("Menu", 11 if UI.is_compact() else 12, Color(G.CREAM, 0.76))
	menu.size_flags_horizontal = Control.SIZE_SHRINK_END
	menu.pressed.connect(func():
		Sfx.play("click")
		_show_menu())
	row.add_child(menu)
	var edge := Control.new()
	edge.custom_minimum_size = Vector2(8, 0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(edge)
	return row


func _go_atlas() -> void:
	Sfx.play("click")
	Router.go("res://scenes/Atlas.tscn")


func _go_seminar() -> void:
	Sfx.play("chime")
	Router.go("res://scenes/Seminar.tscn")


func _show_menu() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.030, 0.028, 0.024, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			overlay.queue_free())
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	overlay.add_child(center)
	var sheet := UI.paper(22)
	sheet.custom_minimum_size = Vector2(minf(340, UI.viewport_size().x - 40), 0)
	center.add_child(sheet)
	var v := UI.vbox(9)
	sheet.add_child(v)
	v.add_child(UI.micro("NAKSHATRA  ·  MENU", Color("6f5228"), 9))
	v.add_child(UI.heading("The Sky Lab", 27, G.INK))
	v.add_child(UI.rule(Color(G.INK, 0.22), 1))
	var present := UI.ink_button("Seminar mode", true, 15)
	present.pressed.connect(func():
		overlay.queue_free()
		_go_seminar())
	v.add_child(present)
	var atlas := UI.ink_button("Sky Atlas", false, 15)
	atlas.pressed.connect(func():
		overlay.queue_free()
		Router.go("res://scenes/Atlas.tscn"))
	v.add_child(atlas)
	var guide := UI.ink_button("Field Guide", false, 15)
	guide.pressed.connect(func():
		overlay.queue_free()
		G.show_field_guide())
	v.add_child(guide)
	var story := UI.ink_button("The Story", false, 15)
	story.pressed.connect(func():
		overlay.queue_free()
		_show_story())
	v.add_child(story)
	var lang := UI.ink_button("ಕನ್ನಡ  /  English", false, 15)
	lang.pressed.connect(func():
		overlay.queue_free()
		G.set_lang("kn" if G.lang == "en" else "en"))
	v.add_child(lang)
	var snd := UI.ink_button("Sound: " + ("On" if G.sound_on else "Off"), false, 15)
	snd.pressed.connect(func():
		G.sound_on = not G.sound_on
		G.save_game()
		Sfx.apply_sound_setting()
		overlay.queue_free()
		_show_menu())
	v.add_child(snd)
	var motion := UI.ink_button("Motion: " + ("Reduced" if G.reduced_motion else "Full"), false, 15)
	motion.pressed.connect(func():
		G.reduced_motion = not G.reduced_motion
		G.save_game()
		overlay.queue_free()
		_show_menu())
	v.add_child(motion)
	v.add_child(UI.rule(Color(G.INK, 0.15), 1))
	var close := UI.ink_button("Close", true, 15)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)


func _star_wheel(mid: Control) -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_child(holder)

	var compact := UI.is_compact()
	var wheel_size := clampf(minf(UI.viewport_size().x, UI.viewport_size().y) * 0.84, 340.0, 500.0)
	var wheel := Control.new()
	wheel.custom_minimum_size = Vector2(wheel_size, wheel_size)
	holder.add_child(wheel)

	_wheel_done = []
	for id in ORDER:
		_wheel_done.append(G.is_done(id))
	var ring: Control = preload("res://scripts/StarWheel.gd").new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.done = _wheel_done
	wheel.add_child(ring)

	var center := wheel_size * 0.5
	var radius := wheel_size * 0.38
	var node_size := 84.0 if not compact else 76.0
	for i in ORDER.size():
		var id := str(ORDER[i])
		var btn := _node_button(id, i, Vector2(center, center), radius, node_size)
		_node_buttons[id] = btn
		wheel.add_child(btn)

	var note_box := VBoxContainer.new()
	note_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_box.alignment = BoxContainer.ALIGNMENT_CENTER
	note_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wheel.add_child(note_box)
	var pad := VBoxContainer.new()
	pad.add_theme_constant_override("separation", 4)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note_box.add_child(pad)

	note_title = UI.label("", 26 if not compact else 20, Design.CREAM, "display")
	note_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	note_title.clip_text = true
	note_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	note_title.custom_minimum_size = Vector2(wheel_size * 0.72, 0)
	pad.add_child(note_title)

	note_body = UI.label("", 16 if not compact else 14, Color(Design.PHOSPHOR, 0.88), "mono")
	note_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_body.autowrap_mode = TextServer.AUTOWRAP_OFF
	note_body.clip_text = true
	note_body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	note_body.custom_minimum_size = Vector2(wheel_size * 0.52, 0)
	pad.add_child(note_body)

	var open := UI.button("Open", true, 15)
	open.custom_minimum_size = Vector2(132, 42)
	open.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	open.pressed.connect(func():
		if _selected_id != "":
			Sfx.play("click")
			_open_module(_selected_id))
	pad.add_child(open)

	var first := _first_incomplete()
	_note_update(first if first != "" else str(ORDER[0]))


func _node_icon(id: String) -> TextureRect:
	var paths := {
		"moon": "res://assets/art/icons/icon_moon.png",
		"stars": "res://assets/art/icons/icon_stars.png",
		"scale": "res://assets/art/icons/icon_scale.png",
		"seasons": "res://assets/art/icons/icon_seasons.png",
		"flares": "res://assets/art/icons/icon_flares.png",
		"blackhole": "res://assets/art/icons/icon_blackhole.png",
		"quiz": "res://assets/art/icons/icon_quiz.png",
	}
	var icon := TextureRect.new()
	icon.texture = load(str(paths.get(id, paths["moon"])))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _node_button(id: String, index: int, center: Vector2, radius: float, node_size: float) -> Button:
	var done := G.is_done(id)
	var b: Button = preload("res://scripts/MechanicalButton.gd").new()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = Vector2(node_size, node_size)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.0)
	normal.border_color = Color(G.GOLD, 0.68 if done else 0.42)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(int(node_size * 0.5))
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(G.GOLD, 0.16)
	hover.border_color = Color(G.GOLD, 0.95)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(G.VERMILION, 0.22)
	pressed.border_color = Color(G.VERMILION, 0.72)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", UI.focus_ring())

	var icon := _node_icon(id)
	icon.custom_minimum_size = Vector2(node_size * 0.68, node_size * 0.68)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.modulate = Color(1.0, 1.0, 1.0, 1.0 if done else 0.82)
	b.add_child(icon)

	var angle := -PI * 0.5 + TAU * float(index) / 7.0
	var pos := center + Vector2(cos(angle), sin(angle)) * radius
	b.position = pos - Vector2(node_size, node_size) * 0.5
	b.mouse_entered.connect(func(): _note_update(id))
	b.pressed.connect(func():
		Sfx.play("click")
		_open_module(id))
	return b


func _note_update(id: String) -> void:
	if note_title == null or id == "":
		return
	var info := G.module_info(id)
	_selected_id = id
	note_title.text = str(info.get("title", id))
	note_body.text = str(info.get("prompt", info.get("blurb", "")))
	for key in _node_buttons:
		var btn := _node_buttons[key] as Button
		var sb := btn.get_theme_stylebox("normal") as StyleBoxFlat
		if sb:
			if key == id:
				sb.border_color = Color(Design.PHOSPHOR, 1.0)
				sb.set_border_width_all(4)
			else:
				sb.border_color = Color(Design.GOLD, 0.48 if not G.is_done(str(key)) else 0.62)
				sb.set_border_width_all(2)
		for child in btn.get_children():
			if child is TextureRect:
				child.modulate = Color(1.0, 1.0, 1.0, 1.0 if key == id else 0.78)


func _hub_footer() -> Control:
	if not G.all_done():
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(0, 4)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return empty
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fest := UI.button("The lantern festival", true, 15)
	fest.custom_minimum_size = Vector2(230, 46)
	fest.pressed.connect(func():
		Sfx.play("lantern")
		Router.go("res://scenes/Finale.tscn"))
	center.add_child(fest)
	box.add_child(center)
	var lift := Control.new()
	lift.custom_minimum_size = Vector2(0, 36)
	lift.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lift)
	return box


func _cards() -> Control:
	var shelf := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.030, 0.028, 0.024, 1.0)
	sb.border_color = Color(G.GOLD, 0.16)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	shelf.add_theme_stylebox_override("panel", sb)

	var v := UI.vbox(8)
	shelf.add_child(v)

	var head := UI.hbox(8)
	head.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	v.add_child(head)
	var rail_title := UI.heading("PICK A LANTERN", 24, G.CREAM)
	rail_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	rail_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(rail_title)


	if UI.is_portrait():
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.54, 500))
		v.add_child(scroll)
		card_list = UI.vbox(6)
		card_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(card_list)
		for id in ORDER:
			card_list.add_child(_module_row(id))
	elif UI.is_compact():
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(grid)
		for id in ORDER:
			grid.add_child(_module_card(id))
	else:
		var rail := HBoxContainer.new()
		rail.add_theme_constant_override("separation", 5)
		rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(rail)
		for id in ORDER:
			rail.add_child(_module_poster(id))
	return shelf


func _colophon_card() -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = G.PAPER
	sb.border_color = Color("6b4f2a", 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(0, 94)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var v := UI.vbox(3)
	p.add_child(v)
	var top := UI.hbox(7)
	v.add_child(top)
	top.add_child(UI.brand_mark(16))
	top.add_child(UI.micro("A SKY ALMANAC", Color("8a6a3c"), 7))
	v.add_child(UI.label("No locks. No order. Just the sky.", 13, G.INK, "serif"))
	var note := UI.label("Every exhibit is open from the first second.", 10, G.INK_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	v.add_child(UI.micro("13° N  ·  CHANDRAGIRI", Color(G.INK_SOFT, 0.8), 7))
	return p


func _thumb(art_path: String, px: float) -> Control:
	var mat := PanelContainer.new()
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color("e9dcc4")
	msb.border_color = Color(0, 0, 0, 0.35)
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(1)
	msb.content_margin_left = 3
	msb.content_margin_right = 3
	msb.content_margin_top = 3
	msb.content_margin_bottom = 3
	mat.add_theme_stylebox_override("panel", msb)
	mat.custom_minimum_size = Vector2(px, px)
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := TextureRect.new()
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.custom_minimum_size = Vector2(px - 8, px - 8)
	tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(art_path):
		tex.texture = load(art_path)
	mat.add_child(tex)
	return mat


func _card_style(done: bool, current: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.034, 0.031, 0.027, 1.0)
	sb.border_color = Color(G.GOLD, 0.38 if current else (0.14 if done else 0.2))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


func _accent_bar(chosen: bool, done: bool) -> ColorRect:
	var bar := ColorRect.new()
	bar.color = Color(G.VERMILION if chosen else (G.TEAL if done else G.GOLD), 0.9 if (chosen or done) else 0.0)
	bar.custom_minimum_size = Vector2(2, 0)
	bar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	bar.offset_right = 2
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _module_card(id: String) -> Control:
	var info := G.module_info(id)
	var done := G.is_done(id)
	var current := _first_incomplete() == id
	var idx := ORDER.find(id) + 1

	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 94 if not UI.is_compact() else 80)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _card_style(done, current))
	var hover := _card_style(done, current)
	hover.bg_color = Color(0.055, 0.048, 0.040, 0.96)
	hover.border_color = Color(G.GOLD, 0.65)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UI.focus_ring())
	b.pressed.connect(func():
		Sfx.play("click")
		_open_module(id))
	b.add_child(_accent_bar(current, done))

	var m := UI.margin(10, 10, 10, 10)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var h := UI.hbox(11)
	m.add_child(h)
	h.add_child(_thumb(str(info.get("art", "")), 58 if not UI.is_compact() else 46))

	var v := UI.vbox(3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := UI.hbox(6)
	v.add_child(top)
	top.add_child(UI.micro("%02d" % idx, Color(G.GOLD, 0.9), 8))
	var tag_s: String = (SHORT_TAG.get(id, str(info.get("tag", ""))) if UI.is_compact() else str(info.get("tag", "")))
	if UI.is_compact() and tag_s.length() > 20:
		tag_s = tag_s.left(19) + "…"
	var tag := UI.micro(tag_s, Color(G.MUTED, 0.8), 8)
	tag.clip_text = true
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.custom_minimum_size = Vector2(0, 0)
	top.add_child(tag)

	var kn_title := str(info.get("kannada", ""))
	var use_kn := G.lang == "kn" and kn_title != ""
	var title := UI.label(kn_title if use_kn else str(info.get("title", id)), 17 if not use_kn else 16, G.CREAM, "kannada" if use_kn else "serif")
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size = Vector2(0, 0)
	v.add_child(title)

	v.add_child(UI.spacer(false, false))
	var bottom := UI.hbox(6)
	v.add_child(bottom)
	var meta := UI.micro(str(info.get("minutes", "")), Color(G.MUTED, 0.75), 8)
	bottom.add_child(meta)
	bottom.add_child(UI.spacer())
	if done:
		bottom.add_child(UI.micro("DONE", G.TEAL, 8))
	elif current:
		bottom.add_child(UI.micro("START HERE  ›", G.VERMILION, 8))
	else:
		bottom.add_child(UI.micro("OPEN  ›", Color(G.CREAM, 0.65), 8))
	return b


func _module_poster(id: String) -> Control:
	var info := G.module_info(id)
	var done := G.is_done(id)
	var current := _first_incomplete() == id
	var idx := ORDER.find(id) + 1
	var accent: Color = [G.VERMILION, G.GOLD, G.TEAL, G.ROSE, G.VERMILION, G.TEAL, G.GOLD][idx - 1]
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 128)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.rotation = 0.0
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.042, 0.038, 0.032, 0.98)
	normal.border_color = Color(G.CREAM, 0.3)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(0)
	normal.content_margin_left = 0
	normal.content_margin_right = 0
	normal.content_margin_top = 0
	normal.content_margin_bottom = 0
	normal.shadow_color = Color(0, 0, 0, 0.55)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(5, 5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.070, 0.058, 0.046, 1.0)
	hover.border_color = accent
	hover.shadow_color = Color(accent, 0.5)
	hover.shadow_offset = Vector2(7, 7)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UI.focus_ring())
	b.pressed.connect(func():
		Sfx.play("click")
		Juice.stamp(str(info.get("title", id)).to_upper(), accent)
		_open_module(id))
	b.mouse_entered.connect(func(): b.z_index = 8)
	b.mouse_exited.connect(func(): b.z_index = 0)
	UI.juice_button(b)

	var stripe := ColorRect.new()
	stripe.color = accent
	stripe.custom_minimum_size = Vector2(0, 7)
	stripe.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(stripe)

	var m := UI.margin(8, 8, 8, 5)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var box := UI.vbox(3)
	m.add_child(box)

	var top := UI.hbox(4)
	box.add_child(top)
	var num := UI.display("%02d" % idx, 23, accent)
	num.autowrap_mode = TextServer.AUTOWRAP_OFF
	num.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(num)
	top.add_child(UI.spacer())
	if done:
		top.add_child(UI.sticker("LIT", G.TEAL, G.INK, 0.0))
	elif current:
		top.add_child(UI.sticker("START", G.VERMILION, G.CREAM, 0.0))

	box.add_child(_thumb(str(info.get("art", "")), 40))
	var title := UI.label(str(info.get("title", id)), 13, G.CREAM, "display")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.max_lines_visible = 2
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(title)

	var bottom := UI.hbox(4)
	box.add_child(bottom)
	bottom.add_child(UI.micro(str(info.get("minutes", "")), Color(G.MUTED, 0.85), 8))
	return b


func _module_row(id: String) -> Control:
	var info := G.module_info(id)
	var done := G.is_done(id)
	var current := _first_incomplete() == id
	var idx := ORDER.find(id) + 1

	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 58)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", _card_style(done, current))
	var hover := _card_style(done, current)
	hover.bg_color = Color(0.055, 0.048, 0.040, 0.96)
	hover.border_color = Color(G.GOLD, 0.65)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", UI.focus_ring())
	b.pressed.connect(func():
		Sfx.play("click")
		Juice.stamp(str(info.get("title", id)).to_upper(), G.GOLD)
		_open_module(id))
	UI.juice_button(b)
	b.mouse_entered.connect(func(): b.z_index = 8)
	b.mouse_exited.connect(func(): b.z_index = 0)
	b.add_child(_accent_bar(current, done))

	var m := UI.margin(9, 6, 10, 6)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)
	var h := UI.hbox(10)
	m.add_child(h)
	h.add_child(_thumb(str(info.get("art", "")), 44))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	var kn_row := str(info.get("kannada", ""))
	var use_kn_row := G.lang == "kn" and kn_row != ""
	var title := UI.label(kn_row if use_kn_row else str(info.get("title", id)), 17 if not use_kn_row else 14, G.CREAM, "kannada" if use_kn_row else "display")
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.custom_minimum_size = Vector2(0, 0)
	v.add_child(title)
	var tag_row: String = (SHORT_TAG.get(id, str(info.get("tag", ""))) if UI.is_compact() else str(info.get("tag", "")))
	if tag_row.length() > 26:
		tag_row = tag_row.left(25) + "…"
	var meta := UI.tracked(tag_row, 9, Color(G.MUTED, 0.82), 1)
	meta.clip_text = true
	meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.custom_minimum_size = Vector2(0, 0)
	v.add_child(meta)

	var rail := UI.vbox(0)
	rail.custom_minimum_size = Vector2(52, 0)
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(rail)
	var num := UI.micro("%02d" % idx, G.VERMILION if current else Color(G.GOLD, 0.8), 8)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rail.add_child(num)
	var mins := UI.micro(str(info.get("minutes", "")), Color(G.MUTED, 0.7), 8)
	mins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rail.add_child(mins)
	if done:
		var st := UI.micro("DONE", G.TEAL, 8)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rail.add_child(st)
	elif current:
		var st := UI.micro("START", G.VERMILION, 7)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rail.add_child(st)
	return b


func _first_incomplete() -> String:
	for id in ORDER:
		if not G.is_done(id):
			return id
	return ""


func _refresh_progress() -> void:
	for id in lanterns:
		if lanterns[id]:
			lanterns[id].set_done(G.is_done(id))
	_rebuild_ui()


func _rebuild_ui() -> void:
	_build_ui()


func _open_module(id: String) -> void:
	var path: String = MODULE_SCENES.get(id, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	Router.go(path)


func _pick_lantern(screen_pos: Vector2) -> void:
	var space := get_world_3d().direct_space_state
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * 200.0
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1
	var hit := space.intersect_ray(params)
	var col = hit.get("collider") if not hit.is_empty() else null
	if col and col.has_meta("module_id"):
		var id: String = col.get_meta("module_id")
		if lanterns.has(id):
			lanterns[id].activate()
			return
	# Touch-friendly fallback: open the nearest visible lantern orb.
	var best_id := ""
	var best_d := 62.0 * 62.0
	for lid in lanterns:
		var l = lanterns[lid]
		if l == null:
			continue
		var wp: Vector3 = l.global_transform * Vector3(0.72, 2.43, 0)
		if cam.is_position_behind(wp):
			continue
		var sp := cam.unproject_position(wp)
		var d := sp.distance_squared_to(screen_pos)
		if d < best_d:
			best_d = d
			best_id = str(lid)
	if best_id != "" and lanterns.has(best_id):
		lanterns[best_id].activate()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_pick_lantern(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_pick_lantern(event.position)


func _process(delta: float) -> void:
	_move_t += delta
	if cam:
		var mouse := get_viewport().get_mouse_position()
		var vp := get_viewport().get_visible_rect().size
		var nx := 0.0
		var ny := 0.0
		if not DisplayServer.is_touchscreen_available():
			nx = (mouse.x / maxf(vp.x, 1.0) - 0.5) * 2.0
			ny = (mouse.y / maxf(vp.y, 1.0) - 0.5) * 2.0
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				nx *= 0.2
				ny *= 0.2
		var target := _base_cam_pos + Vector3(nx * 0.5, -ny * 0.25 + sin(_move_t * 0.4) * 0.06, 0)
		if not G.reduced_motion:
			cam.position = cam.position.lerp(target, delta * 2.0)
			cam.look_at(_base_look + Vector3(nx * 0.7, -ny * 0.35, 0), Vector3.UP)
		_update_hover(mouse, vp)
	if G.reduced_motion:
		return
	for i in _sky_lanterns.size():
		var n := _sky_lanterns[i]
		n.position.y += _sky_lantern_speeds[i] * delta
		if n.position.y > 40.0:
			n.position.y = 8.0
			n.position.x = randf_range(-28, 28)


func _update_hover(mouse: Vector2, vp: Vector2) -> void:
	if mouse.x < 0 or mouse.y < 0 or mouse.x > vp.x or mouse.y > vp.y:
		return
	if not (event_is_mouse_available()):
		return
	var space := get_world_3d().direct_space_state
	var from := cam.project_ray_origin(mouse)
	var to := from + cam.project_ray_normal(mouse) * 200.0
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1
	var hit := space.intersect_ray(params)
	var id := ""
	if not hit.is_empty():
		var col = hit.get("collider")
		if col and col.has_meta("module_id"):
			id = col.get_meta("module_id")
	if id != _hovered_id:
		if lanterns.has(_hovered_id) and lanterns[_hovered_id]:
			lanterns[_hovered_id].set_hover(false)
		_hovered_id = id
		if lanterns.has(id) and lanterns[id]:
			lanterns[id].set_hover(true)


func event_is_mouse_available() -> bool:
	return DisplayServer.is_touchscreen_available() == false


func _on_resize() -> void:
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_place_camera()
		_build_ui()


func _show_story() -> void:
	if _story_overlay:
		return
	_story_overlay = Control.new()
	_story_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_story_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_story_overlay.theme = UI.theme()
	ui_root.add_child(_story_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.030, 0.028, 0.024, 0.84)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_story_overlay.queue_free()
			_story_overlay = null)
	_story_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	center.offset_top = 16
	center.offset_bottom = -16
	_story_overlay.add_child(center)
	var sheet := UI.paper(UI.pad())
	sheet.custom_minimum_size = Vector2(minf(620, UI.viewport_size().x - 32), 0)
	center.add_child(sheet)
	var v := UI.vbox(11)
	sheet.add_child(v)
	v.add_child(UI.micro("NAKSHATRA  ·  A STORY YOU CAN SKIP", Color("8a6a3c"), 9))
	v.add_child(UI.heading("The Lantern Festival", 30, G.INK))
	v.add_child(UI.rule(Color(G.INK, 0.22), 1))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.5, 380))
	v.add_child(scroll)
	var body := UI.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	for p in G.content.get("story", []):
		body.add_child(UI.label(str(p), 16, G.INK))
	var close := UI.ink_button("Back to the lab", true, 16)
	close.pressed.connect(func():
		_story_overlay.queue_free()
		_story_overlay = null)
	v.add_child(close)

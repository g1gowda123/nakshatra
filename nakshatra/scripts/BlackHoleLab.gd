extends Node3D
## Black Hole Lab: an event horizon you can approach, and a clock that tells the
## truth about gravity. The visual is deliberately simple; the numbers are real.

var cam: Camera3D
var sky: SkyDome
var ui_root: Control
var panel: PanelContainer
var hole: MeshInstance3D
var disk: MeshInstance3D
var photon_ring: MeshInstance3D
var probe: Node3D
var probe_glow: Sprite3D
var orbit_ring: MeshInstance3D
var disk_mat: ShaderMaterial

var mass_suns := 10.0
var distance_rs := 2.2
var probe_angle := 0.0
var stage := 0
var feedback := ""
var lost := false
var _options_built := false

var mass_slider: HSlider
var mass_label: Label
var rs_label: Label
var dist_slider: HSlider
var dist_label: Label
var clock_label: Label
var clock_sub: Label
var prompt_label: Label
var feedback_label: Label
var pips_box: HBoxContainer
var options_box: VBoxContainer
var progress_label: Label
var controls_box: VBoxContainer
var readout_label: Label
var timeline_box: VBoxContainer
var lower_btn: Button
var pull_btn: Button

const HOLE_RADIUS := 1.35
const PROBE_SCALE := 1.4


func _ready() -> void:
	_build_world()
	UI.attach_dither(self, 4.0, 2.0)
	_build_ui()
	if ui_root:
		ui_root.add_child(UI.scanlines())
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)
	G.maybe_briefing(ui_root, "blackhole")


func _build_world() -> void:
	cam = Camera3D.new()
	cam.current = true
	add_child(cam)
	_place_camera()

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 212.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_star_scale(1.25)
	sky.set_star_intensity(1.1)

	var amb := DirectionalLight3D.new()
	amb.light_color = Color(0.6, 0.7, 1.0)
	amb.light_energy = 0.18
	amb.rotation_degrees = Vector3(-35, 20, 0)
	add_child(amb)

	hole = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = HOLE_RADIUS
	hm.height = HOLE_RADIUS * 2.0
	hm.radial_segments = 48
	hm.rings = 32
	hole.mesh = hm
	var black := StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color(0.001, 0.001, 0.002)
	black.disable_receive_shadows = true
	hole.material_override = black
	add_child(hole)

	disk = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(12.0, 12.0)
	disk.mesh = pm
	disk_mat = ShaderMaterial.new()
	disk_mat.shader = load("res://shaders/accretion_disk.gdshader")
	disk.material_override = disk_mat
	disk.rotation_degrees = Vector3(68.0, 0.0, 12.0)
	disk_mat.render_priority = 1
	add_child(disk)

	photon_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = HOLE_RADIUS * 1.015
	tm.outer_radius = HOLE_RADIUS * 1.06
	tm.rings = 96
	tm.ring_segments = 8
	photon_ring.mesh = tm
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(1.0, 0.82, 0.55)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.55, 0.18)
	ring_mat.emission_energy_multiplier = 2.6
	photon_ring.material_override = ring_mat
	photon_ring.rotation_degrees = Vector3(68.0, 0.0, 12.0)
	add_child(photon_ring)

	# A face-on Einstein/photon ring: the thin circle that makes the shadow read
	# instantly as a black hole, even while the accretion disk is nearly edge-on.
	var face_ring := MeshInstance3D.new()
	var fr := TorusMesh.new()
	fr.inner_radius = HOLE_RADIUS * 1.12
	fr.outer_radius = HOLE_RADIUS * 1.135
	fr.rings = 96
	fr.ring_segments = 6
	face_ring.mesh = fr
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fmat.albedo_color = Color(1.0, 0.86, 0.62, 0.62)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.65, 0.32)
	fmat.emission_energy_multiplier = 1.6
	face_ring.material_override = fmat
	face_ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	add_child(face_ring)

	# A second, cooler ring of lensed starlight just outside the shadow.
	var lens := MeshInstance3D.new()
	var lm := TorusMesh.new()
	lm.inner_radius = HOLE_RADIUS * 1.18
	lm.outer_radius = HOLE_RADIUS * 1.195
	lm.rings = 96
	lm.ring_segments = 6
	lens.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	lmat.albedo_color = Color(0.3, 0.65, 1.0, 0.45)
	lmat.emission_enabled = true
	lmat.emission = Color(0.2, 0.55, 1.0)
	lmat.emission_energy_multiplier = 1.1
	lens.material_override = lmat
	lens.rotation_degrees = Vector3(68.0, 0.0, 12.0)
	add_child(lens)

	# The old hard-edged polar jets read as a rendering artefact at this scale;
	# the accretion disk and photon ring carry the silhouette on their own.

	probe = Node3D.new()
	add_child(probe)
	var pb := MeshInstance3D.new()
	var psm := SphereMesh.new()
	psm.radius = 0.075
	psm.height = 0.15
	pb.mesh = psm
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(0.55, 0.95, 1.0)
	pmat.emission_enabled = true
	pmat.emission = Color(0.25, 0.9, 1.0)
	pmat.emission_energy_multiplier = 2.4
	pb.material_override = pmat
	probe.add_child(pb)
	probe_glow = Sprite3D.new()
	probe_glow.texture = load("res://assets/fx/glow.png")
	probe_glow.pixel_size = 0.005
	probe_glow.scale = Vector3.ONE * 1.6
	probe_glow.modulate = Color(0.35, 0.95, 1.0, 0.52)
	probe_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	probe_glow.shaded = false
	probe.add_child(probe_glow)

	_update_orbit()
	_update_probe_position()


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		cam.position = Vector3(0, 8.5, 27.0)
		cam.fov = 60.0
	else:
		cam.position = Vector3(0, 5.0, 17.0)
		cam.fov = 50.0
	cam.look_at(Vector3(0, 0.3, 0), Vector3.UP)


func _update_orbit() -> void:
	if orbit_ring:
		orbit_ring.queue_free()
	orbit_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	var r := HOLE_RADIUS * distance_rs
	tm.inner_radius = r - 0.006
	tm.outer_radius = r + 0.006
	tm.rings = 96
	tm.ring_segments = 6
	orbit_ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.2, 0.75, 0.95, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.65, 0.9)
	mat.emission_energy_multiplier = 0.7
	orbit_ring.material_override = mat
	orbit_ring.rotation_degrees = Vector3(18.0, 0.0, -8.0)
	add_child(orbit_ring)


func _update_probe_position() -> void:
	if not probe:
		return
	var r := HOLE_RADIUS * distance_rs
	probe.position = Vector3(cos(probe_angle) * r, sin(probe_angle * 0.55) * 0.35, sin(probe_angle) * r)
	probe.visible = not lost
	if probe_glow:
		probe_glow.visible = not lost


func _build_ui() -> void:
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.theme()
	add_child(ui_root)
	var vp := UI.viewport_size()

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui_root.add_child(vignette)
	ui_root.add_child(UI.scrim(true, 156, 0.72))

	var top := _top_bar()
	top.position = Vector2(UI.pad(), 12)
	top.size = Vector2(vp.x - UI.pad() * 2, 56)
	ui_root.add_child(top)

	panel = UI.panel(14, 0.9)
	ui_root.add_child(panel)
	if UI.is_portrait():
		panel.position = Vector2(10, vp.y * 0.52)
		panel.size = Vector2(vp.x - 20, vp.y * 0.46)
	else:
		panel.position = Vector2(vp.x - 408, 92)
		panel.size = Vector2(390, vp.y - 112)

	var m := UI.margin(4, 4, 4, 4)
	panel.add_child(m)
	var col := UI.vbox(8)
	m.add_child(col)

	var lesson: Dictionary = G.module_info("blackhole").get("lesson", {})
	col.add_child(UI.micro("BIG IDEA", Color(G.GOLD, 0.9), 8))
	var big := UI.label(str(lesson.get("big_idea", "")), 13, Color(G.CREAM, 0.9), "serif")
	big.custom_minimum_size = Vector2(0, 32)
	col.add_child(big)

	var scroll := UI.scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var body := UI.vbox(7)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	controls_box = UI.vbox(7)
	body.add_child(controls_box)
	mass_label = UI.label("Mass: 10 Suns", 13, G.CREAM, "body_med")
	controls_box.add_child(mass_label)
	mass_slider = HSlider.new()
	mass_slider.min_value = 5
	mass_slider.max_value = 50
	mass_slider.step = 1
	mass_slider.value = mass_suns
	mass_slider.custom_minimum_size = Vector2(0, 28)
	mass_slider.value_changed.connect(_on_mass)
	controls_box.add_child(mass_slider)
	rs_label = UI.label("Event horizon radius: 30 km", 12, G.GOLD)
	controls_box.add_child(rs_label)

	controls_box.add_child(UI.divider())
	dist_label = UI.label("Probe distance: 4.00 Rs", 13, G.CREAM, "body_med")
	controls_box.add_child(dist_label)
	dist_slider = HSlider.new()
	dist_slider.min_value = 1.02
	dist_slider.max_value = 8.0
	dist_slider.step = 0.01
	dist_slider.value = distance_rs
	dist_slider.custom_minimum_size = Vector2(0, 28)
	dist_slider.value_changed.connect(_on_distance)
	controls_box.add_child(dist_slider)

	var clock_box := PanelContainer.new()
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color(0.04, 0.09, 0.15, 0.85)
	csb.border_color = Color(G.TEAL, 0.3)
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(2)
	csb.content_margin_left = 12
	csb.content_margin_right = 12
	csb.content_margin_top = 8
	csb.content_margin_bottom = 8
	clock_box.add_theme_stylebox_override("panel", csb)
	controls_box.add_child(clock_box)
	var cb := UI.vbox(2)
	clock_box.add_child(cb)
	clock_label = UI.micro("1 hour here = 1.7 hours on Earth", Color(G.GOLD, 0.9), 8)
	cb.add_child(clock_label)
	clock_sub = UI.label("Gravitational time dilation at the probe", 10, G.MUTED)
	cb.add_child(clock_sub)

	readout_label = UI.label("", 12, G.GOLD)
	body.add_child(readout_label)
	body.add_child(UI.divider())
	prompt_label = UI.label("", 13, G.CREAM, "body_med")
	body.add_child(prompt_label)
	feedback_label = UI.label("", 13, G.MUTED)
	body.add_child(feedback_label)
	pips_box = UI.hbox(4)
	body.add_child(pips_box)
	for i in 4:
		var pip := StarPip.new()
		pip.setup(false, G.GOLD, 11.0)
		pips_box.add_child(pip)
	options_box = UI.vbox(6)
	body.add_child(options_box)
	_options_built = false

	var buttons := UI.hbox(8)
	col.add_child(buttons)
	lower_btn = UI.button("Lower probe", false, 13)
	lower_btn.custom_minimum_size = Vector2(0, 44)
	lower_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_btn.pressed.connect(func(): _nudge(-0.25))
	buttons.add_child(lower_btn)
	pull_btn = UI.button("Pull back", false, 13)
	pull_btn.custom_minimum_size = Vector2(0, 44)
	pull_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pull_btn.pressed.connect(func(): _nudge(0.25))
	buttons.add_child(pull_btn)

	_update_ui()


func _top_bar() -> Control:
	progress_label = UI.micro("0 / 4", Color(G.GOLD, 0.9), 9)
	var acts: Array = []
	if not UI.is_compact():
		acts.append({"text": "LESSON", "fn": func(): G.show_briefing("blackhole")})
	return UI.app_bar("Black Hole Lab", "EVENT HORIZONS  ·  TIME DILATION", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB", progress_label)


func _on_resize() -> void:
	_place_camera()
	_build_ui()


func _on_mass(value: float) -> void:
	mass_suns = value
	var rs_km := 2.953 * mass_suns
	mass_label.text = "Mass: %d Suns" % int(mass_suns)
	rs_label.text = "Event horizon radius: %.0f km" % rs_km
	_update_ui()


func _on_distance(value: float) -> void:
	distance_rs = value
	_update_probe_position()
	if distance_rs < 1.1 and stage == 0 and not lost:
		stage = 1
		mass_suns = 10.0
		mass_slider.value = mass_suns
		var rs_km := 2.953 * mass_suns
		mass_label.text = "Mass: 10 Suns"
		rs_label.text = "Event horizon radius: %.0f km" % rs_km
		feedback = "At 1.05 Rs the probe's clock is crawling. It has not crossed the horizon — but it can never come back from here without a rocket that does not exist."
		Sfx.play("success")
		_build_options()
	elif distance_rs <= 1.03:
		lost = true
		probe.visible = false
		feedback = "The probe crossed the event horizon. No signal can return. From outside, it fades and freezes; the probe itself feels nothing unusual at the crossing."
	_update_ui()


func _nudge(amount: float) -> void:
	distance_rs = clampf(distance_rs + amount, 1.02, 8.0)
	dist_slider.value = distance_rs
	_update_probe_position()
	_update_ui()


func _build_options() -> void:
	if _options_built:
		return
	_options_built = true
	for c in options_box.get_children():
		c.queue_free()
	var challenge := _current_challenge()
	if challenge.is_empty():
		return
	var opts: Array = challenge.get("options", [])
	for i in opts.size():
		var b := UI.button(str(opts[i]), false, 12)
		b.custom_minimum_size = Vector2(0, 38)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): _answer(i, int(challenge.get("answer", -1))))
		options_box.add_child(b)
	options_box.visible = true


func _current_challenge() -> Dictionary:
	var ids := ["size", "myth", "detect"]
	if stage <= 0 or stage > 3:
		return {}
	var want: String = ids[clampi(stage - 1, 0, 2)]
	for ch in G.content.get("blackhole", {}).get("challenges", []):
		if str(ch.get("id", "")) == want:
			return ch
	return {}


func _answer(index: int, correct: int) -> void:
	if index == correct:
		if stage == 1:
			stage = 2
			feedback = "A 10-solar-mass black hole's event horizon is about 30 km in radius. The entire mass of ten Suns, squeezed inside a city."
		elif stage == 2:
			stage = 3
			feedback = "Gravity is gravity. Far away, a black hole pulls just like a star of the same mass. Only close does the horizon change everything."
		elif stage == 3:
			stage = 4
			feedback = "The EHT linked radio dishes across the planet into one virtual Earth-sized telescope. In 2019 it imaged the shadow of M87*."
			G.complete("blackhole")
			_show_finish()
		_options_built = false
		Sfx.play("success")
		_update_ui()
		if stage < 4:
			_build_options()
	else:
		feedback = "Not yet. Read the explanation in the lesson, then try once more."
		Sfx.play("soft_error")
		_update_ui()


func _update_ui() -> void:
	if prompt_label == null:
		return
	var prompts := [
		"Lower the probe below 1.1 Rs and watch its clock.",
		"At 10 Suns, how large is the event horizon's radius?",
		"Which statement about black holes is true?",
		"How did the Event Horizon Telescope image a black hole?",
		"You reached the edge of an event horizon. The universe keeps its receipts."
	]
	prompt_label.text = prompts[clampi(stage, 0, 4)]
	feedback_label.text = feedback
	dist_label.text = "Probe distance: %.2f Rs" % distance_rs
	var factor := sqrt(maxf(0.0, 1.0 - 1.0 / maxf(distance_rs, 1.0001)))
	var ratio := 1.0 / maxf(factor, 0.0001)
	clock_label.text = "1 hour here = %.1f hours on Earth" % ratio
	clock_sub.text = "Gravitational time dilation at %.2f Rs  ·  not to scale" % distance_rs
	mass_label.text = "Mass: %d Suns" % int(mass_suns)
	rs_label.text = "Event horizon radius: %.0f km  ·  Rs = 2.95 km per solar mass" % (2.953 * mass_suns)
	controls_box.visible = stage == 0
	readout_label.visible = stage > 0
	readout_label.text = "READOUT   ·   %d Suns   ·   horizon %.0f km   ·   probe %.2f Rs" % [int(mass_suns), 2.953 * mass_suns, distance_rs]
	lower_btn.visible = stage == 0
	pull_btn.visible = stage == 0
	progress_label.text = "%d / 4" % clampi(stage, 0, 4)
	for i in pips_box.get_child_count():
		var pip := pips_box.get_child(i) as StarPip
		if pip:
			pip.setup(stage > i, G.GOLD if stage > i else Color(G.GOLD, 0.55), 11.0)
	if stage in [1, 2, 3]:
		_build_options()
	else:
		options_box.visible = false


func _process(delta: float) -> void:
	probe_angle += delta * 0.24
	if probe and not lost:
		_update_probe_position()
	if photon_ring:
		photon_ring.rotation.y += delta * 0.06
	if disk:
		disk.rotation.z += delta * 0.02
	if orbit_ring:
		orbit_ring.rotation.y += delta * 0.04


func _show_finish() -> void:
	var facts: Array = G.content.get("blackhole", {}).get("facts", [])
	var lesson: Dictionary = G.module_info("blackhole").get("lesson", {})
	Overlay.info(ui_root, "At the edge", "BLACK HOLES  ·  GRAVITY & TIME",
		[
			str(lesson.get("big_idea", "")),
			"You lowered a probe, watched its clock slow, measured a horizon and separated the science from the movie myths. The numbers are real: a 10-solar-mass black hole's horizon is about 30 km in radius.",
			"Black holes are not vacuum cleaners. They are extreme gravity, revealed by orbiting stars, hot accretion disks, gravitational waves and the shadow imaged by the Event Horizon Telescope."
		], facts, "res://assets/art/card_blackhole.webp", "Back to the dark")

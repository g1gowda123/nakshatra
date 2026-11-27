extends Node3D
## Solar Storm Lab: build magnetic stress, trigger a flare, race a CME to Earth.
## The point is not the explosion — it is the chain: magnetic energy -> light ->
## charged particles -> aurora -> a satellite at risk.

var cam: Camera3D
var sky: SkyDome
var ui_root: Control
var panel: PanelContainer
var sun_node: Node3D
var earth_node: Node3D
var cme: Node3D
var flare_fx: CPUParticles3D
var satellite: Node3D
var shield_mesh: MeshInstance3D
var satellite_body: MeshInstance3D
var aurora_mats: Array[StandardMaterial3D] = []
var aurora_halo: Sprite3D
var aurora_poles: Array[Sprite3D] = []
var loop_mats: Array[StandardMaterial3D] = []
var sun_mat: ShaderMaterial

var stress := 35.0
var shield_on := false
var flare_active := false
var cme_t := 0.0
var stage := 0
var finished := false
var satellite_hit := false
var feedback := ""
var cme_start := Vector3.ZERO
var cme_end := Vector3.ZERO
var _options_built := false

var stress_bar: ProgressBar
var stress_label: Label
var stress_slider: HSlider
var prompt_label: Label
var feedback_label: Label
var shield_btn: Button
var release_btn: Button
var pips_box: HBoxContainer
var options_box: VBoxContainer
var light_label: Label
var cme_label: Label
var aurora_label: Label
var progress_label: Label

const SUN_POS := Vector3(-7.6, 3.1, -3.0)
const EARTH_POS := Vector3(7.2, -1.1, -1.0)
const SUN_RADIUS := 3.8
const EARTH_RADIUS := 0.78


func _ready() -> void:
	_build_world()
	_build_ui()
	set_process(true)
	G.maybe_briefing(ui_root, "flares")


func _build_world() -> void:
	cam = Camera3D.new()
	cam.current = true
	add_child(cam)
	_place_camera()

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 108.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_star_scale(1.15)
	sky.set_star_intensity(1.05)

	var amb := DirectionalLight3D.new()
	amb.light_color = Color(0.55, 0.65, 0.95)
	amb.light_energy = 0.22
	amb.rotation_degrees = Vector3(-45, -30, 0)
	add_child(amb)

	_build_sun()
	_build_earth()
	_build_cme()
	_build_flare()
	_place_camera()


func _place_camera() -> void:
	if not cam:
		return
	if UI.is_portrait():
		cam.position = Vector3(0, 8.5, 42.0)
		cam.fov = 66.0
		cam.look_at(Vector3(0, 1.6, 0), Vector3.UP)
		if earth_node:
			earth_node.position = Vector3(6.4, 6.4, -1.0)
		if sun_node:
			sun_node.position = SUN_POS + Vector3(0, 2.0, 0)
			if flare_fx:
				flare_fx.position = sun_node.position + Vector3(SUN_RADIUS * 0.86, 1.1, 1.2)
	else:
		cam.position = Vector3(0, 6.8, 27.0)
		cam.fov = 55.0
		cam.look_at(Vector3(0, 1.2, 0), Vector3.UP)
		if earth_node:
			earth_node.position = EARTH_POS
		if sun_node:
			sun_node.position = SUN_POS
			if flare_fx:
				flare_fx.position = sun_node.position + Vector3(SUN_RADIUS * 0.86, 1.1, 1.2)


func _build_sun() -> void:
	sun_node = Node3D.new()
	sun_node.position = SUN_POS
	add_child(sun_node)

	var sphere := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = SUN_RADIUS
	sm.height = SUN_RADIUS * 2.0
	sm.radial_segments = 48
	sm.rings = 32
	sphere.mesh = sm
	sun_mat = ShaderMaterial.new()
	sun_mat.shader = load("res://shaders/sun_surface.gdshader")
	sun_mat.set_shader_parameter("stress", stress / 100.0)
	sphere.material_override = sun_mat
	sun_node.add_child(sphere)

	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.02
	glow.scale = Vector3.ONE * 7.5
	glow.modulate = Color(1.0, 0.58, 0.22, 0.48)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	sun_node.add_child(glow)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.62, 0.28)
	light.light_energy = 3.2
	light.omni_range = 90.0
	sun_node.add_child(light)

	# The panel calls it AR-7; give the active region a visible home.
	var ar := MeshInstance3D.new()
	var ar_mesh := SphereMesh.new()
	ar_mesh.radius = 0.30
	ar_mesh.height = 0.60
	ar_mesh.radial_segments = 12
	ar_mesh.rings = 6
	ar.mesh = ar_mesh
	var ar_mat := StandardMaterial3D.new()
	ar_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ar_mat.albedo_color = Color(0.23, 0.08, 0.03)
	ar.material_override = ar_mat
	ar.position = Vector3(2.25, 1.55, 2.42)
	sun_node.add_child(ar)
	var ar_glow := Sprite3D.new()
	ar_glow.texture = load("res://assets/fx/glow.png")
	ar_glow.pixel_size = 0.012
	ar_glow.scale = Vector3.ONE * 1.4
	ar_glow.modulate = Color(1.0, 0.42, 0.16, 0.55)
	ar_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ar_glow.shaded = false
	ar_glow.position = ar.position + Vector3(0, 0.05, 0.10)
	sun_node.add_child(ar_glow)
	var ar_label := Label3D.new()
	ar_label.text = "AR-7"
	ar_label.font = UI.body_med_font()
	ar_label.font_size = 28
	ar_label.pixel_size = 0.014
	ar_label.modulate = Color(1.0, 0.92, 0.72, 0.98)
	ar_label.outline_size = 9
	ar_label.outline_modulate = Color(0.05, 0.01, 0.0, 0.95)
	ar_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ar_label.position = ar.position + Vector3(0.0, 0.72, 0.15)
	sun_node.add_child(ar_label)

	for i in 3:
		_add_loop(i * 52.0, 1.55 + i * 0.08, 1.15 - i * 0.12, 1.4 + i * 0.18)


func _add_loop(yaw: float, radius: float, height: float, z: float) -> void:
	var root := Node3D.new()
	root.rotation.y = deg_to_rad(yaw)
	root.position = Vector3(0, 2.2, z)
	sun_node.add_child(root)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.72, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.55, 0.16)
	mat.emission_energy_multiplier = 1.2
	loop_mats.append(mat)
	for i in 14:
		var t := float(i) / 13.0
		var x := lerpf(-radius, radius, t)
		var y := sin(t * PI) * height
		var bead := MeshInstance3D.new()
		var bm := SphereMesh.new()
		bm.radius = 0.045 if i % 2 == 0 else 0.033
		bm.height = bm.radius * 2.0
		bead.mesh = bm
		bead.material_override = mat
		bead.position = Vector3(x, y, 0)
		root.add_child(bead)


func _build_earth() -> void:
	earth_node = Node3D.new()
	earth_node.position = EARTH_POS
	add_child(earth_node)

	var em := MeshInstance3D.new()
	var esm := SphereMesh.new()
	esm.radius = EARTH_RADIUS
	esm.height = EARTH_RADIUS * 2.0
	esm.radial_segments = 40
	esm.rings = 24
	em.mesh = esm
	var earth_mat := ShaderMaterial.new()
	earth_mat.shader = load("res://shaders/earth.gdshader")
	em.material_override = earth_mat
	earth_node.add_child(em)

	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.009
	glow.scale = Vector3.ONE * 3.4
	glow.modulate = Color(0.3, 0.55, 1.0, 0.55)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	earth_node.add_child(glow)

	# Magnetosphere: two faint teal shells.
	_magnet_ring(1.35, 0.012, Color(0.25, 0.8, 0.9, 0.4), 90.0, 0.0)
	_magnet_ring(1.62, 0.009, Color(0.2, 0.6, 0.95, 0.28), 65.0, 18.0)

	# Auroral ovals near both poles.
	aurora_mats.append(_aurora_ring(EARTH_RADIUS * 0.88, 0.11, 1.0))
	aurora_mats.append(_aurora_ring(-EARTH_RADIUS * 0.88, 0.11, -1.0))
	aurora_halo = Sprite3D.new()
	aurora_halo.texture = load("res://assets/fx/glow.png")
	aurora_halo.pixel_size = 0.008
	aurora_halo.scale = Vector3.ONE * 3.0
	aurora_halo.modulate = Color(0.25, 1.0, 0.5, 0.0)
	aurora_halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	aurora_halo.shaded = false
	aurora_halo.no_depth_test = true
	earth_node.add_child(aurora_halo)
	for pole in [-1.0, 1.0]:
		var pg := Sprite3D.new()
		pg.texture = load("res://assets/fx/glow.png")
		pg.pixel_size = 0.006
		pg.scale = Vector3.ONE * 2.6
		pg.modulate = Color(0.2, 1.0, 0.4, 0.0)
		pg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pg.shaded = false
		pg.no_depth_test = true
		pg.position = Vector3(0, 0.9 * pole, 0)
		earth_node.add_child(pg)
		aurora_poles.append(pg)

	satellite = Node3D.new()
	satellite.position = Vector3(1.5, 0.35, 0.5)
	earth_node.add_child(satellite)
	satellite_body = MeshInstance3D.new()
	var body_sphere := SphereMesh.new()
	body_sphere.radius = 0.09
	body_sphere.height = 0.18
	body_sphere.radial_segments = 16
	body_sphere.rings = 8
	satellite_body.mesh = body_sphere
	var sat_mat := StandardMaterial3D.new()
	sat_mat.albedo_color = Color(0.82, 0.84, 0.82)
	sat_mat.metallic = 0.5
	sat_mat.roughness = 0.35
	satellite_body.material_override = sat_mat
	satellite.add_child(satellite_body)
	for side in [-1, 1]:
		var panel := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.34, 0.008, 0.15)
		panel.mesh = pm
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.16, 0.26, 0.52)
		pmat.emission_enabled = true
		pmat.emission = Color(0.1, 0.22, 0.7)
		pmat.emission_energy_multiplier = 0.25
		panel.material_override = pmat
		panel.position = Vector3(0.26 * side, 0, 0)
		panel.rotation_degrees = Vector3(0, 0, 10.0 * side)
		satellite.add_child(panel)
	var sat_label := Label3D.new()
	sat_label.text = "SATELLITE"
	sat_label.font = UI.body_med_font()
	sat_label.font_size = 30
	sat_label.pixel_size = 0.014
	sat_label.modulate = Color(G.GOLD, 0.95)
	sat_label.outline_size = 5
	sat_label.outline_modulate = Color(0.01, 0.02, 0.05, 0.9)
	sat_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sat_label.no_depth_test = true
	sat_label.position = Vector3(0, 0.5, 0)
	satellite.add_child(sat_label)

	shield_mesh = MeshInstance3D.new()
	var shm := SphereMesh.new()
	shm.radius = 0.55
	shm.height = 1.1
	shm.radial_segments = 24
	shm.rings = 12
	shield_mesh.mesh = shm
	var shmat := StandardMaterial3D.new()
	shmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shmat.albedo_color = Color(0.2, 0.9, 0.85, 0.16)
	shmat.emission_enabled = true
	shmat.emission = Color(0.1, 0.8, 0.75)
	shmat.emission_energy_multiplier = 0.8
	shield_mesh.material_override = shmat
	shield_mesh.visible = false
	satellite.add_child(shield_mesh)


func _magnet_ring(major: float, minor: float, col: Color, tilt_x: float, tilt_y: float) -> void:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = major - minor
	tm.outer_radius = major + minor
	tm.rings = 64
	tm.ring_segments = 8
	ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = Color(col.r, col.g, col.b)
	mat.emission_energy_multiplier = 1.2
	ring.material_override = mat
	ring.rotation_degrees = Vector3(tilt_x, tilt_y, 0)
	earth_node.add_child(ring)


func _aurora_ring(y: float, thickness: float, dir: float) -> StandardMaterial3D:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = EARTH_RADIUS * 0.86
	tm.outer_radius = EARTH_RADIUS * 1.08
	tm.rings = 48
	tm.ring_segments = 6
	ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(0.2, 1.0, 0.4, 0.22)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 1.0, 0.35)
	mat.emission_energy_multiplier = 1.0
	mat.no_depth_test = true
	mat.render_priority = 2
	ring.material_override = mat
	ring.position.y = y
	ring.scale = Vector3(1, 0.55, 1)
	earth_node.add_child(ring)
	return mat


func _build_cme() -> void:
	cme = Node3D.new()
	cme.visible = false
	add_child(cme)
	var torus := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.36
	tm.outer_radius = 0.52
	tm.rings = 32
	tm.ring_segments = 8
	torus.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.55, 0.15, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.42, 0.08)
	mat.emission_energy_multiplier = 2.4
	torus.material_override = mat
	cme.add_child(torus)
	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.012
	glow.scale = Vector3.ONE * 4.6
	glow.modulate = Color(1.0, 0.55, 0.18, 0.85)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	cme.add_child(glow)


func _build_flare() -> void:
	flare_fx = CPUParticles3D.new()
	flare_fx.amount = 48
	flare_fx.lifetime = 1.6
	flare_fx.one_shot = true
	flare_fx.emitting = false
	flare_fx.direction = Vector3(1, 0.25, 0)
	flare_fx.spread = 28.0
	flare_fx.initial_velocity_min = 5.0
	flare_fx.initial_velocity_max = 12.0
	flare_fx.gravity = Vector3(0, 0.4, 0)
	flare_fx.scale_amount_min = 0.08
	flare_fx.scale_amount_max = 0.3
	flare_fx.color = Color(1.0, 0.62, 0.18, 1.0)
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	flare_fx.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_texture = load("res://assets/fx/glow.png")
	mat.vertex_color_use_as_albedo = true
	flare_fx.material_override = mat
	flare_fx.position = SUN_POS + Vector3(SUN_RADIUS * 0.86, 1.1, 1.2)
	add_child(flare_fx)


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

	var lesson: Dictionary = G.module_info("flares").get("lesson", {})
	col.add_child(UI.micro("BIG IDEA", Color(G.GOLD, 0.9), 8))
	var big := UI.label(str(lesson.get("big_idea", "")), 13, Color(G.CREAM, 0.9), "serif")
	big.custom_minimum_size = Vector2(0, 32)
	col.add_child(big)

	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var body := UI.vbox(7)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	var status_row := UI.label("ACTIVE REGION AR-7   ·   MAGNETIC STRESS", 10, G.GOLD, "body_med")
	status_row.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.add_child(status_row)

	stress_label = UI.label("Magnetic stress: 35%", 13, G.CREAM, "body_med")
	body.add_child(stress_label)
	stress_bar = ProgressBar.new()
	stress_bar.show_percentage = false
	stress_bar.custom_minimum_size = Vector2(0, 8)
	stress_bar.max_value = 100
	stress_bar.value = stress
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.18, 0.12, 0.12)
	bsb.set_corner_radius_all(2)
	stress_bar.add_theme_stylebox_override("background", bsb)
	var bfill := StyleBoxFlat.new()
	bfill.bg_color = Color(1.0, 0.45, 0.22)
	bfill.set_corner_radius_all(2)
	stress_bar.add_theme_stylebox_override("fill", bfill)
	body.add_child(stress_bar)

	stress_slider = HSlider.new()
	stress_slider.min_value = 0
	stress_slider.max_value = 100
	stress_slider.step = 1
	stress_slider.value = stress
	stress_slider.custom_minimum_size = Vector2(0, 28)
	stress_slider.value_changed.connect(_on_stress)
	body.add_child(stress_slider)

	body.add_child(UI.divider())
	prompt_label = UI.label("", 14, G.CREAM, "body_med")
	prompt_label.custom_minimum_size = Vector2(0, 38)
	body.add_child(prompt_label)
	feedback_label = UI.label("", 13, G.MUTED)
	body.add_child(feedback_label)
	pips_box = UI.hbox(4)
	body.add_child(pips_box)
	for i in 3:
		var pip := StarPip.new()
		pip.setup(false, G.GOLD, 11.0)
		pips_box.add_child(pip)

	options_box = UI.vbox(6)
	body.add_child(options_box)
	_options_built = false

	body.add_child(UI.divider())
	body.add_child(UI.micro("THE CHAIN, IN REAL TIME", Color(G.GOLD, 0.9), 8))
	light_label = UI.label("Light  ·  8 min 20 s to reach Earth", 12, G.GOLD)
	cme_label = UI.label("CME  ·  15 hours – 3 days to arrive", 12, G.MUTED)
	aurora_label = UI.label("Aurora  ·  when the particles arrive", 12, G.MUTED)
	body.add_child(light_label)
	body.add_child(cme_label)
	body.add_child(aurora_label)

	var buttons := UI.hbox(8)
	col.add_child(buttons)
	shield_btn = UI.button("Shield: OFF", false, 13)
	shield_btn.custom_minimum_size = Vector2(0, 44)
	shield_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shield_btn.pressed.connect(_toggle_shield)
	buttons.add_child(shield_btn)
	release_btn = UI.button("Release flare", true, 14)
	release_btn.custom_minimum_size = Vector2(0, 44)
	release_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	release_btn.pressed.connect(_release)
	buttons.add_child(release_btn)

	_connect_resize()
	_update_ui()


func _top_bar() -> Control:
	progress_label = UI.micro("0 / 3", Color(G.GOLD, 0.9), 9)
	var acts: Array = []
	if not UI.is_compact():
		acts.append({"text": "LESSON", "fn": func(): G.show_briefing("flares")})
	return UI.app_bar("Solar Storm Lab", "SOLAR FLARES  ·  SPACE WEATHER", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB", progress_label)


func _connect_resize() -> void:
	if not get_viewport().size_changed.is_connected(_on_resize):
		get_viewport().size_changed.connect(_on_resize)


func _on_resize() -> void:
	_place_camera()
	_build_ui()


func _on_stress(value: float) -> void:
	stress = value
	stress_label.text = "Magnetic stress: %d%%" % int(stress)
	stress_bar.value = stress
	stress_slider.value = stress
	if sun_mat:
		sun_mat.set_shader_parameter("stress", stress / 100.0)
	for mat in loop_mats:
		mat.emission_energy_multiplier = 0.8 + stress / 100.0 * 2.6
	if stage == 0 and not flare_active:
		if stress >= 70.0:
			feedback = "The field is tangled and loaded. Release when you are ready."
		else:
			feedback = "The magnetic field is still calm. Push it above 70 to build a storm."
	_update_ui()


func _toggle_shield() -> void:
	shield_on = not shield_on
	shield_mesh.visible = shield_on
	Sfx.play("click")
	if stage == 1:
		feedback = "Shield is on. Release a flare and watch the CME arrive." if shield_on else "Shield is off. The satellite is exposed."
	_update_ui()


func _release() -> void:
	if flare_active or stage >= 2:
		return
	if stage == 0 and stress < 70.0:
		feedback = "The field is too calm. Raise the magnetic stress above 70 first."
		Sfx.play("soft_error")
		_update_ui()
		return
	_trigger_flare()


func _trigger_flare() -> void:
	flare_active = true
	cme_t = 0.0
	flare_fx.restart()
	flare_fx.emitting = true
	cme.visible = true
	cme_start = sun_node.position + Vector3(SUN_RADIUS * 0.9, 1.2, 1.4)
	cme_end = earth_node.position + Vector3(-1.4, 0.2, 0.3)
	cme.position = cme_start
	cme.scale = Vector3.ONE
	Sfx.play("whoosh", -4.0)
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.55, 0.16, 0.22)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.7)
	tw.tween_callback(flash.queue_free)
	feedback = "Flare released. Light reaches Earth in 8 min 20 s. The CME is behind it."
	if stage == 0:
		stage = 1
	_update_ui()


func _process(delta: float) -> void:
	if flare_active:
		cme_t = minf(cme_t + delta / 3.2, 1.0)
		var t := cme_t
		cme.position = cme_start.lerp(cme_end, t) + Vector3(0, sin(t * PI) * 1.2, 0)
		cme.scale = Vector3.ONE * (1.0 + t * 1.5)
		if t >= 1.0:
			_arrive()
	if satellite:
		satellite.rotation.y += delta * 0.5
	if sun_node:
		sun_node.rotation.y += delta * 0.01


func _arrive() -> void:
	flare_active = false
	cme.visible = false
	cme_t = 0.0
	for mat in aurora_mats:
		var tw := create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 3.4, 0.6)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.8, 0.6)
	if aurora_halo:
		var ht := create_tween()
		ht.tween_property(aurora_halo, "modulate:a", 0.8, 0.7)
	for pg in aurora_poles:
		var pt := create_tween()
		pt.tween_property(pg, "modulate:a", 0.95, 0.7)
	if stage == 1:
		if shield_on:
			stage = 2
			feedback = "The CME arrived. The shield held; the satellite is safe. Auroras are glowing at both poles."
			Sfx.play("success")
			_build_options()
		else:
			satellite_hit = true
			var sat_mat := satellite_body.material_override as StandardMaterial3D
			if sat_mat:
				sat_mat.albedo_color = Color(0.7, 0.15, 0.12)
			feedback = "The CME hit the satellite. Switch the shield ON and try again — this is why space-weather forecasting matters."
			Sfx.play("soft_error")
	elif stage == 0:
		feedback = "Auroras are glowing. The CME has arrived."
	_update_ui()


func _build_options() -> void:
	if _options_built:
		return
	_options_built = true
	for c in options_box.get_children():
		c.queue_free()
	var data: Dictionary = {}
	for ch in G.content.get("flares", {}).get("challenges", []):
		if str(ch.get("id", "")) == "delay":
			data = ch
	if data.is_empty():
		return
	options_box.add_child(UI.label(str(data.get("prompt", "")), 13, G.GOLD, "body_med"))
	var opts: Array = data.get("options", [])
	for i in opts.size():
		var b := UI.button(str(opts[i]), false, 13)
		b.custom_minimum_size = Vector2(0, 40)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func(): _answer(i, int(data.get("answer", -1))))
		options_box.add_child(b)
	options_box.visible = true


func _answer(index: int, correct: int) -> void:
	if index == correct:
		stage = 3
		finished = true
		feedback = "Exactly. Light is fast; the CME's charged particles are much slower. That delay is our warning window."
		Sfx.play("success")
		G.complete("flares")
		_update_ui()
		_show_finish()
	else:
		feedback = "Not quite. Think about what travels at the speed of light and what does not."
		Sfx.play("soft_error")
		_update_ui()


func _update_ui() -> void:
	if prompt_label == null:
		return
	var prompts := [
		"Build the magnetic stress above 70, then release a flare.",
		"Protect the satellite: switch its shield on, then release another flare.",
		"Why does the aurora arrive much later than the flare's light?",
		"Storm cleared. You traced energy from the Sun to Earth."
	]
	prompt_label.text = prompts[clampi(stage, 0, 3)]
	feedback_label.text = feedback
	shield_btn.text = "Shield: ON" if shield_on else "Shield: OFF"
	shield_btn.add_theme_color_override("font_color", G.TEAL if shield_on else G.CREAM)
	release_btn.disabled = flare_active or stage >= 2 or stress < 70.0
	release_btn.tooltip_text = "Build the magnetic stress above 70% first." if stress < 70.0 else "Release the flare."
	if stage >= 2:
		release_btn.text = "Storm answered"
	elif shield_on:
		release_btn.text = "Release flare"
	else:
		release_btn.text = "Release flare"
	for i in pips_box.get_child_count():
		var pip := pips_box.get_child(i) as StarPip
		if pip:
			pip.setup(stage > i, G.GOLD if stage > i else Color(G.GOLD, 0.55), 11.0)
	progress_label.text = "%d / 3" % clampi(stage, 0, 3)
	light_label.add_theme_color_override("font_color", G.GOLD if flare_active or stage > 0 else Color(G.GOLD, 0.7))
	if flare_active:
		cme_label.text = "CME  ·  crossing space… (compressed)"
		cme_label.add_theme_color_override("font_color", G.ROSE)
	elif stage >= 2:
		cme_label.text = "CME  ·  arrived; the shield held"
		cme_label.add_theme_color_override("font_color", G.TEAL)
	else:
		cme_label.text = "CME  ·  15 hours – 3 days to arrive"
		cme_label.add_theme_color_override("font_color", G.MUTED)
	aurora_label.text = "Aurora  ·  glowing at both poles" if stage >= 2 else "Aurora  ·  when the particles arrive"
	aurora_label.add_theme_color_override("font_color", G.TEAL if stage >= 2 else G.MUTED)
	if stage == 2:
		_build_options()


func _show_finish() -> void:
	var facts: Array = G.content.get("flares", {}).get("facts", [])
	var lesson: Dictionary = G.module_info("flares").get("lesson", {})
	Overlay.info(ui_root, "Storm cleared", "SOLAR STORMS  ·  SPACE WEATHER",
		[
			str(lesson.get("big_idea", "")),
			"You built the magnetic stress, released a flare, raced its CME to Earth, protected a satellite and explained the delay. That whole chain is real space weather.",
			"The flare's light arrives in 8 minutes; the particles take hours to days. That gap is why we watch the Sun from space — and why a shield, a forecast and a little humility matter."
		], facts, "res://assets/art/card_flares.webp", "Back to the Sun")

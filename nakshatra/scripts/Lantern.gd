class_name SkyLantern
extends Node3D
## A paper sky lantern on a lacquered pole: the seven lessons of the hill.
## Everything is built in code; no external mesh, no sprite sheet. The body is
## a lathe-turned paper shell with a warm shader, a brass cap, a tassel, a soft
## ground pool and a hover title. Deliberately quieter than the old glow ball.

signal chosen(id: String)

var id := ""
var title := ""
var done := false
var accent := Color("d9b36c")
var number := 1
var phase := 0.0
var base_y := 0.0

var _swing: Node3D
var _body: MeshInstance3D
var _body_mat: ShaderMaterial
var _light: OmniLight3D
var _glow: Sprite3D
var _pool: MeshInstance3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _title_label: Label3D
var _number_label: Label3D
var _area: Area3D
var _hover := false
var _busy := false
var _hover_t := 0.0
var _pop := 0.0

const BODY_HEIGHT := 0.80
const BODY_RADIUS := 0.395
const HANG_Y := 2.82


func setup(module_id: String, module_title: String, color: Color, index: int = -1) -> void:
	id = module_id
	title = module_title
	accent = color
	number = index if index > 0 else G.MODULES.find(module_id) + 1


func _ready() -> void:
	phase = randf() * TAU
	base_y = position.y
	_build()


func _build() -> void:
	# --- stone foot, lacquered pole, brass finial -------------------------
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("22262b")
	stone.roughness = 0.95
	var foot := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.22
	fm.bottom_radius = 0.26
	fm.height = 0.16
	fm.radial_segments = 10
	foot.mesh = fm
	foot.position.y = 0.08
	foot.material_override = stone
	add_child(foot)

	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("1a1713")
	wood.roughness = 0.62
	wood.metallic = 0.15
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.038
	pm.bottom_radius = 0.060
	pm.height = 2.94
	pm.radial_segments = 10
	pole.mesh = pm
	pole.position.y = 1.55
	pole.material_override = wood
	add_child(pole)

	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("8a6a3a")
	brass.metallic = 0.85
	brass.roughness = 0.36
	var finial := MeshInstance3D.new()
	var fim := SphereMesh.new()
	fim.radius = 0.055
	fim.height = 0.11
	fim.radial_segments = 10
	fim.rings = 6
	finial.mesh = fim
	finial.position.y = 3.04
	finial.material_override = brass
	add_child(finial)

	var arm := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(0.78, 0.048, 0.048)
	arm.mesh = am
	arm.position = Vector3(0.36, HANG_Y, 0)
	arm.material_override = wood
	add_child(arm)

	var brace := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.035, 0.035)
	brace.mesh = bm
	brace.position = Vector3(0.16, HANG_Y - 0.13, 0)
	brace.rotation_degrees.z = -38.0
	brace.material_override = wood
	add_child(brace)

	var hang := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.010
	hm.bottom_radius = 0.010
	hm.height = 0.20
	hm.radial_segments = 6
	hang.mesh = hm
	hang.position = Vector3(0.72, HANG_Y - 0.10, 0)
	hang.material_override = wood
	add_child(hang)

	# --- swinging paper body ---------------------------------------------
	_swing = Node3D.new()
	_swing.position = Vector3(0.72, HANG_Y - 0.20, 0)
	add_child(_swing)

	_body_mat = ShaderMaterial.new()
	_body_mat.shader = load("res://shaders/paper_lantern.gdshader")
	_body_mat.set_shader_parameter("paper_color", Color("f2b56a"))
	_body_mat.set_shader_parameter("light_color", Color("ffd48a"))
	_body_mat.set_shader_parameter("rib_color", Color("4a2410"))
	_body_mat.set_shader_parameter("lit", 0.88)
	_body_mat.set_shader_parameter("done_tint", Color("ffe6ae"))
	_body_mat.set_shader_parameter("ribs", 9.0)

	_body = MeshInstance3D.new()
	_body.mesh = _make_paper_mesh()
	_body.position.y = -0.19
	_body.material_override = _body_mat
	_body.name = "Paper"
	_swing.add_child(_body)

	var cap_mat := brass
	for spec in [[-0.19 + BODY_HEIGHT * 0.5 + 0.03, 0.10, 0.17], [-0.19 - BODY_HEIGHT * 0.5 - 0.03, 0.19, 0.12]]:
		var cap := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = float(spec[1])
		cm.bottom_radius = float(spec[2])
		cm.height = 0.055
		cm.radial_segments = 12
		cap.mesh = cm
		cap.position.y = float(spec[0])
		cap.material_override = cap_mat
		_swing.add_child(cap)

	# Tassel: a red bead and three swaying threads.
	var tassel_mat := StandardMaterial3D.new()
	tassel_mat.albedo_color = Color("8d2e1e")
	tassel_mat.roughness = 0.8
	var bead := MeshInstance3D.new()
	var bdm := SphereMesh.new()
	bdm.radius = 0.035
	bdm.height = 0.07
	bdm.radial_segments = 8
	bdm.rings = 5
	bead.mesh = bdm
	bead.position.y = -0.70
	bead.material_override = tassel_mat
	_swing.add_child(bead)
	for i in 3:
		var thread := MeshInstance3D.new()
		var tm := BoxMesh.new()
		tm.size = Vector3(0.010, 0.20, 0.010)
		thread.mesh = tm
		thread.position = Vector3(-0.026 + i * 0.026, -0.80, 0)
		thread.rotation_degrees.z = (i - 1) * 5.0
		thread.material_override = tassel_mat
		_swing.add_child(thread)

	# --- light and halo ---------------------------------------------------
	_light = OmniLight3D.new()
	_light.position = Vector3(0, -0.19, 0)
	_light.light_color = Color("ffb45f")
	_light.light_energy = 1.15
	_light.omni_range = 6.2
	_light.omni_attenuation = 1.7
	_light.shadow_enabled = false
	_swing.add_child(_light)

	_glow = Sprite3D.new()
	_glow.texture = load("res://assets/fx/glow.png")
	_glow.pixel_size = 0.010
	_glow.scale = Vector3.ONE * 1.15
	_glow.modulate = Color(1.0, 0.74, 0.42, 0.40)
	_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_glow.shaded = false
	_glow.no_depth_test = false
	_glow.render_priority = 2
	_glow.position = Vector3(0, -0.19, 0)
	_swing.add_child(_glow)

	_pool = MeshInstance3D.new()
	var pq := QuadMesh.new()
	pq.size = Vector2(3.8, 2.7)
	pq.orientation = PlaneMesh.FACE_Y
	_pool.mesh = pq
	_pool.position = Vector3(0.72, 0.035, 0)
	var pool_mat := StandardMaterial3D.new()
	pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	pool_mat.albedo_texture = load("res://assets/fx/glow.png")
	pool_mat.albedo_color = Color(1.0, 0.66, 0.34, 0.30)
	pool_mat.disable_receive_shadows = true
	pool_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_pool.material_override = pool_mat
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pool)

	# A quiet ring of gold, only visible when the lantern is visited or hovered.
	_ring = MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.46
	rm.outer_radius = 0.485
	rm.rings = 28
	rm.ring_segments = 5
	_ring.mesh = rm
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.albedo_color = Color(accent, 0.0)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = accent
	_ring_mat.emission_energy_multiplier = 0.8
	_ring.material_override = _ring_mat
	_ring.position = Vector3(0, -0.19, 0)
	_ring.visible = false
	_swing.add_child(_ring)

	# --- typography -------------------------------------------------------
	# The number is painted on the glowing paper, matching the lesson cards.
	_number_label = Label3D.new()
	_number_label.text = "%02d" % number
	_number_label.font = UI.serif_font()
	_number_label.font_size = 96
	_number_label.pixel_size = 0.0052
	_number_label.modulate = Color("2a1608")
	_number_label.outline_size = 0
	_number_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_number_label.no_depth_test = true
	_number_label.render_priority = 5
	_number_label.position = Vector3(0.0, 2.82, 0.405)
	add_child(_number_label)

	# A small hanging paper tag, so the number still reads when the lantern is
	# across the hill and the glowing body is only a few pixels wide.
	var tag_back := MeshInstance3D.new()
	var bq := QuadMesh.new()
	bq.size = Vector2(0.54, 0.68)
	tag_back.mesh = bq
	var bm_tag := StandardMaterial3D.new()
	bm_tag.albedo_color = Color("2a1608")
	bm_tag.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm_tag.cull_mode = BaseMaterial3D.CULL_DISABLED
	tag_back.material_override = bm_tag
	tag_back.position = Vector3(0.0, 2.10, 0.02)
	add_child(tag_back)

	var tag_face := MeshInstance3D.new()
	var tq := QuadMesh.new()
	tq.size = Vector2(0.46, 0.60)
	tag_face.mesh = tq
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color("efe0c4")
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.emission_enabled = true
	tm.emission = Color(1.0, 0.84, 0.56)
	tm.emission_energy_multiplier = 0.16
	tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tag_face.material_override = tm
	tag_face.position = Vector3(0.0, 2.10, 0.032)
	add_child(tag_face)

	var tag_label := Label3D.new()
	tag_label.text = "%02d" % number
	tag_label.font = UI.serif_font()
	tag_label.font_size = 100
	tag_label.pixel_size = 0.0055
	tag_label.modulate = Color("4a1c0e")
	tag_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	tag_label.no_depth_test = true
	tag_label.render_priority = 6
	tag_label.position = Vector3(0.0, 2.10, 0.045)
	add_child(tag_label)

	_title_label = Label3D.new()
	_title_label.text = title
	_title_label.font = UI.body_med_font()
	_title_label.font_size = 44
	_title_label.pixel_size = 0.0058
	_title_label.modulate = Color(G.CREAM, 0.0)
	_title_label.visible = false
	_title_label.outline_size = 8
	_title_label.outline_modulate = Color(0.02, 0.03, 0.06, 0.85)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.no_depth_test = true
	_title_label.render_priority = 5
	_title_label.position = Vector3(0.72, 3.56, 0)
	add_child(_title_label)

	# --- pick area --------------------------------------------------------
	_area = Area3D.new()
	_area.name = "Hit"
	_area.collision_layer = 1
	_area.collision_mask = 0
	_area.monitoring = false
	_area.monitorable = true
	_area.input_ray_pickable = true
	_area.set_meta("module_id", id)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.95
	shape.shape = sphere
	shape.position = Vector3(0.72, HANG_Y - 0.39, 0)
	_area.add_child(shape)
	add_child(_area)

	if done:
		set_done(true)


func _make_paper_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 16
	var segs := 24
	var height := BODY_HEIGHT
	var verts: Array = []
	for r in rings + 1:
		var t := float(r) / float(rings)
		var y := -height * 0.5 + t * height
		var belly := 0.58 + 0.42 * sin(t * PI)
		# Slightly asymmetric shoulder so it reads hand-made.
		var shoulder := 1.0 + 0.04 * sin(t * 3.1)
		var rad := BODY_RADIUS * belly * shoulder
		var row: Array = []
		for s in segs + 1:
			var a := TAU * float(s) / float(segs)
			row.append(Vector3(cos(a) * rad, y, sin(a) * rad))
		verts.append(row)
	for r in rings:
		for s in segs:
			var a: Vector3 = verts[r][s]
			var b: Vector3 = verts[r][s + 1]
			var c: Vector3 = verts[r + 1][s + 1]
			var d: Vector3 = verts[r + 1][s]
			var u0 := float(s) / float(segs)
			var u1 := float(s + 1) / float(segs)
			var v0 := float(r) / float(rings)
			var v1 := float(r + 1) / float(rings)
			# Two triangles, UVs carried per corner.
			st.set_uv(Vector2(u0, v0)); st.add_vertex(a)
			st.set_uv(Vector2(u1, v0)); st.add_vertex(b)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(c)
			st.set_uv(Vector2(u0, v0)); st.add_vertex(a)
			st.set_uv(Vector2(u1, v1)); st.add_vertex(c)
			st.set_uv(Vector2(u0, v1)); st.add_vertex(d)
	st.generate_normals()
	return st.commit()


func set_done(value: bool) -> void:
	done = value
	if _body_mat:
		_body_mat.set_shader_parameter("lit", 1.0 if value else 0.88)
	if _light:
		_light.light_energy = 1.55 if value else 1.15
	if _glow:
		_glow.modulate.a = 0.72 if value else 0.58
	if _pool:
		var m := _pool.material_override as StandardMaterial3D
		if m:
			m.albedo_color.a = 0.40 if value else 0.30
	_ring.visible = value or _hover
	if _ring_mat:
		_ring_mat.albedo_color = Color(accent, 0.75 if value else 0.0)
	if _number_label:
		_number_label.modulate = Color("2a1608") if not value else Color("3b230c")


func set_hover(value: bool) -> void:
	if _hover == value:
		return
	_hover = value
	_hover_t = 0.0
	if _ring:
		_ring.visible = value or done
		if _ring_mat:
			_ring_mat.albedo_color = Color(accent, 0.55 if value else (0.75 if done else 0.0))


func _process(delta: float) -> void:
	var motion := not G.reduced_motion
	phase += delta if motion else 0.0
	_hover_t = minf(_hover_t + delta, 1.0)
	_pop = maxf(_pop - delta * 3.4, 0.0)
	# A single writer for the pop: activate() raises _pop, this decays it and
	# folds it into the hover scale. Tweening the same properties here fought
	# the hover lerp and the tap read as a dead click.
	var pop := 1.0 + _pop * 0.17
	var target := (1.0 + (0.055 if _hover else 0.0)) * pop
	_swing.scale = _swing.scale.lerp(Vector3.ONE * target, delta * 7.0)
	# A slow, organic pendulum; the paper body is light, the pole is not.
	_swing.rotation.z = sin(phase * 0.9) * 0.025 + (_hover_t * 0.02 if _hover else 0.0) if motion else 0.0
	_swing.rotation.x = cos(phase * 0.7) * 0.018 if motion else 0.0
	var flicker := 0.965 + sin(phase * 7.1) * 0.025 + sin(phase * 13.7 + 1.7) * 0.012 if motion else 1.0
	if _body_mat:
		_body_mat.set_shader_parameter("flicker", flicker)
	if _light:
		_light.light_energy = (1.55 if done else 1.15) + (0.28 if _hover else 0.0) + (flicker - 1.0) * 0.9 + _pop * 1.25
	if _glow:
		var g := 1.30 if done else (1.50 if _hover else 1.15)
		_glow.scale = _glow.scale.lerp(Vector3.ONE * (g + _pop * 0.9), delta * 4.0)
	if _title_label:
		var a := _title_label.modulate.a
		a = move_toward(a, 1.0 if _hover else 0.0, delta * 5.0)
		_title_label.modulate.a = a
		_title_label.visible = _hover or a > 0.01
	position.y = base_y + (sin(phase * 0.55) * 0.012 if motion else 0.0)


func activate() -> void:
	if _busy:
		return
	_busy = true
	_pop = 1.0
	Sfx.play("lantern", -7.0, 1.02)
	await get_tree().create_timer(0.17).timeout
	chosen.emit(id)
	await get_tree().create_timer(0.10).timeout
	_busy = false

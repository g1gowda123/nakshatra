class_name SkyHill
extends Node3D
## The hilltop itself: ink-washed ground, a lantern path, a working brass
## observatory, silhouetted pines, drifting mist and seven paper lanterns.
## Built entirely in code so the web build carries no heavy environment assets.

signal lantern_chosen(id: String)

var sign_label: Label3D

const SPOTS := [
	{"id": "moon", "x": -10.2, "z": -2.8},
	{"id": "stars", "x": -7.2, "z": -6.3},
	{"id": "scale", "x": -3.6, "z": -8.8},
	{"id": "seasons", "x": 0.4, "z": -9.8},
	{"id": "flares", "x": 4.3, "z": -8.6},
	{"id": "blackhole", "x": 7.6, "z": -5.8},
	{"id": "quiz", "x": 10.0, "z": -1.8},
]

const OBS_POS := Vector3(-7.8, 0.0, -14.2)

var lanterns: Dictionary = {}
var _path_samples: PackedVector3Array = PackedVector3Array()
var _sky_lanterns: Array[Node3D] = []
var _sky_speeds: Array[float] = []
var _sky_phases: Array[float] = []
var _mists: Array[MeshInstance3D] = []
var _mist_speeds: Array[float] = []
var _dome: Node3D
var _obs_light: OmniLight3D
var _t := 0.0
var _moon_light: DirectionalLight3D


func build(add_moon_light: bool = true) -> void:
	_t = 0.0
	_build_spot_positions()
	_build_underlay()
	_build_ground()
	_build_path()
	_build_lantern_trail()
	_build_ridges()
	_build_mist()
	_build_observatory()
	_build_trees()
	_build_horizon_treeline()
	_build_bench()
	_build_rocks()
	_build_grass()
	_build_lanterns()
	_build_fireflies()
	_build_sky_lanterns()
	_build_moon()
	if add_moon_light:
		_build_moon_light()
	var meteors := ShootingStarField.new()
	meteors.name = "Meteors"
	add_child(meteors)


# --------------------------------------------------------------------------
# Terrain helpers
# --------------------------------------------------------------------------

func ground_height(x: float, z: float) -> float:
	var h := 0.30 * sin(x * 0.16 + 0.4) * cos(z * 0.13 - 0.2)
	h += 0.10 * sin((x + z) * 0.31 + 1.2)
	var d := Vector2(x - 0.6, z + 4.0).length()
	h += 0.45 * exp(-d * d / 170.0)
	var rim := smoothstep(34.0, 58.0, Vector2(x, z).length())
	h -= rim * 0.85
	return h


func warmth_at(x: float, z: float) -> float:
	var w := 0.0
	for spot in SPOTS:
		var dx: float = x - float(spot["x"])
		var dz: float = z - float(spot["z"])
		w += 0.72 * exp(-(dx * dx + dz * dz) / 38.0)
	var ox := x - OBS_POS.x
	var oz := z - OBS_POS.z
	w += 0.62 * exp(-(ox * ox + oz * oz) / 52.0)
	return clampf(w, 0.0, 1.0)


func _build_spot_positions() -> void:
	pass


func _near_path(x: float, z: float, reach: float) -> bool:
	for p in _path_samples:
		var dx := x - p.x
		var dz := z - p.z
		if dx * dx + dz * dz < reach * reach:
			return true
	return false


func _build_underlay() -> void:
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(420, 1.0, 420)
	base.mesh = bm
	base.position = Vector3(0, -2.2, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("05080e")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	base.material_override = mat
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(base)


func _build_ground() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "InkGround"
	mi.mesh = _make_ground_mesh()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground_ink.gdshader")
	mat.set_shader_parameter("deep_color", Color("0a1110"))
	mat.set_shader_parameter("thicket_color", Color("0d1a17"))
	mat.set_shader_parameter("warm_color", Color(1.0, 0.64, 0.32))
	mat.set_shader_parameter("warm_emission", 0.36)
	mat.set_shader_parameter("noise_scale", 0.55)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


func _make_ground_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := 84
	var extent := 72.0
	var step := extent * 2.0 / float(cells)
	var width := cells + 1
	for zi in cells + 1:
		var z := -extent + float(zi) * step
		for xi in cells + 1:
			var x := -extent + float(xi) * step
			var y := ground_height(x, z)
			var e := 0.35
			var hx := ground_height(x + e, z) - ground_height(x - e, z)
			var hz := ground_height(x, z + e) - ground_height(x, z - e)
			var n := Vector3(-hx / (2.0 * e), 1.0, -hz / (2.0 * e)).normalized()
			var n1 := 0.5 + 0.5 * sin(x * 0.37 + z * 0.21) * sin(x * 0.13 - z * 0.41)
			var n2 := 0.5 + 0.5 * sin(x * 0.051 - z * 0.073 + 1.7)
			var col := Color(0.075, 0.108, 0.102).lerp(Color(0.052, 0.082, 0.086), n1)
			col = col.lerp(Color(0.095, 0.088, 0.066), n2 * 0.30)
			col = col.lerp(Color(0.20, 0.14, 0.08), warmth_at(x, z) * 0.12)
			st.set_color(Color(col.r, col.g, col.b, warmth_at(x, z)))
			st.set_normal(n)
			st.set_uv(Vector2(x, z) * 0.09)
			st.add_vertex(Vector3(x, y, z))
	for zi in cells:
		for xi in cells:
			var a := zi * width + xi
			var b := a + 1
			var c := a + width
			var d := c + 1
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	return st.commit()


func _build_path() -> void:
	var curve := Curve3D.new()
	for p in [
		Vector3(0.6, 0, 14.2), Vector3(-0.5, 0, 9.6), Vector3(1.3, 0, 4.8),
		Vector3(-0.4, 0, 0.2), Vector3(-3.2, 0, -4.4), Vector3(-6.1, 0, -8.6),
		Vector3(-7.0, 0, -12.2), Vector3(-7.6, 0, -14.2),
	]:
		curve.add_point(p)
	var length := curve.get_baked_length()
	var steps := 88
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := curve.sample_baked(t * length)
		var p2 := curve.sample_baked(minf(t * length + 0.3, length))
		var tan := p2 - p
		tan.y = 0.0
		if tan.length() < 0.001:
			tan = Vector3(0, 0, -1)
		tan = tan.normalized()
		var side := Vector3(-tan.z, 0, tan.x)
		var w := 1.05 + 0.22 * sin(t * 5.1) + 0.10 * sin(t * 11.3)
		var y := ground_height(p.x, p.z) + 0.045
		left.append(Vector3(p.x, y, p.z) + side * w)
		right.append(Vector3(p.x, y, p.z) - side * w)
		_path_samples.append(Vector3(p.x, y, p.z))
	var base := Color(0.15, 0.155, 0.145)
	for i in steps + 1:
		var warm := warmth_at(left[i].x, left[i].z)
		st.set_color(Color(base.r, base.g, base.b, warm))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, float(i) * 0.11))
		st.add_vertex(left[i])
		st.set_color(Color(base.r, base.g, base.b, warm))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, float(i) * 0.11))
		st.add_vertex(right[i])
	for i in steps:
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		st.add_index(a); st.add_index(c); st.add_index(b)
		st.add_index(b); st.add_index(c); st.add_index(d)
	var mi := MeshInstance3D.new()
	mi.name = "LanternPath"
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/path_ink.gdshader")
	mat.set_shader_parameter("stone_color", Color(0.16, 0.17, 0.16))
	mat.set_shader_parameter("mortar_color", Color(0.04, 0.05, 0.055))
	mat.set_shader_parameter("warm_color", Color(1.0, 0.68, 0.36))
	mat.set_shader_parameter("warm_emission", 0.32)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

	# Individual flagstones make the route legible even on a dark phone screen.
	var slab_mats: Array[StandardMaterial3D] = []
	for band in 4:
		var sm := StandardMaterial3D.new()
		var warm := float(band) / 3.0
		sm.albedo_color = Color(0.34, 0.32, 0.26).lerp(Color(0.56, 0.39, 0.22), warm * 0.65)
		sm.roughness = 0.92
		sm.emission_enabled = true
		sm.emission = Color(1.0, 0.58, 0.28)
		sm.emission_energy_multiplier = 0.08 + warm * 0.36
		slab_mats.append(sm)
	var i := 4
	while i < _path_samples.size() - 5:
		var p := _path_samples[i]
		var p2 := _path_samples[i + 1]
		var dir := p2 - p
		dir.y = 0.0
		var yaw := atan2(dir.x, dir.z)
		var warm := warmth_at(p.x, p.z)
		var slab := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = randf_range(0.46, 0.60)
		cyl.bottom_radius = 0.62
		cyl.height = 0.09
		cyl.radial_segments = 8
		slab.mesh = cyl
		slab.position = Vector3(p.x, ground_height(p.x, p.z) + 0.055, p.z)
		slab.rotation_degrees.y = rad_to_deg(yaw) + randf_range(-9.0, 9.0)
		slab.scale = Vector3(1.18, 1.0, 0.68)
		slab.material_override = slab_mats[clampi(int(warm * 3.99), 0, 3)]
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(slab)
		i += 2

	# Star-flowers: small warm lights that keep the near path legible and give
	# the foreground the same hand-made magic as the lanterns.
	var star_mat := StandardMaterial3D.new()
	star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_mat.emission_enabled = true
	star_mat.emission = Color(1.0, 0.68, 0.36)
	star_mat.emission_energy_multiplier = 1.8
	star_mat.albedo_color = Color(1.0, 0.8, 0.5)
	for idx in [6, 17, 28, 39, 50, 61]:
		if idx >= _path_samples.size():
			continue
		var centre: Vector3 = _path_samples[idx]
		for side_sign in [-1.0, 1.0]:
			var sp := centre + Vector3(0.95 * side_sign, 0.22, 0.15 * side_sign)
			var flower := MeshInstance3D.new()
			var fm := SphereMesh.new()
			fm.radius = 0.065
			fm.height = 0.11
			fm.radial_segments = 6
			fm.rings = 4
			flower.mesh = fm
			flower.position = sp
			flower.material_override = star_mat
			add_child(flower)
			var halo := Sprite3D.new()
			halo.texture = load("res://assets/fx/glow.png")
			halo.pixel_size = 0.010
			halo.scale = Vector3.ONE * 0.55
			halo.modulate = Color(1.0, 0.74, 0.44, 0.36)
			halo.position = sp
			halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			halo.shaded = false
			add_child(halo)

	# Two small guide lamps bridge the darker middle of the walk.
	for idx in [16, 38]:
		if idx + 1 < _path_samples.size():
			var a: Vector3 = _path_samples[idx]
			var b: Vector3 = _path_samples[idx + 1]
			var tan := b - a
			tan.y = 0.0
			var side := Vector3(-tan.z, 0, tan.x).normalized()
			_path_bollard(a + side * 1.25)

	# A welcome lantern at the near end of the path, and a second midway.
	_floor_lantern(Vector3(2.9, 0, 10.6), 1.2)
	_floor_lantern(Vector3(-2.5, 0, 3.0), 0.95)


func _floor_lantern(pos: Vector3, s: float) -> void:
	var y := ground_height(pos.x, pos.z)
	var root := Node3D.new()
	root.position = Vector3(pos.x, y, pos.z)
	root.scale = Vector3.ONE * s
	add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("20262a")
	stone.roughness = 0.92
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.34
	bm.bottom_radius = 0.42
	bm.height = 0.25
	bm.radial_segments = 8
	base.mesh = bm
	base.position.y = 0.12
	base.material_override = stone
	root.add_child(base)
	var paper := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.46, 0.54, 0.46)
	paper.mesh = pm
	paper.position.y = 0.53
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.66, 0.34)
	glass.emission_energy_multiplier = 1.25
	glass.albedo_color = Color(1.0, 0.76, 0.44)
	paper.material_override = glass
	root.add_child(paper)
	var roof := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.0
	rm.bottom_radius = 0.42
	rm.height = 0.28
	rm.radial_segments = 4
	roof.mesh = rm
	roof.position.y = 0.95
	roof.rotation_degrees.y = 45.0
	roof.material_override = stone
	root.add_child(roof)
	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.010
	glow.scale = Vector3.ONE * 1.7
	glow.modulate = Color(1.0, 0.72, 0.40, 0.6)
	glow.position.y = 0.6
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.position.y = 0.66
	light.light_color = Color(1.0, 0.68, 0.36)
	light.light_energy = 1.25
	light.omni_range = 5.4
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	root.add_child(light)


func _path_bollard(pos: Vector3) -> void:
	var y := ground_height(pos.x, pos.z)
	var root := Node3D.new()
	root.position = Vector3(pos.x, y, pos.z)
	add_child(root)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("1b2024")
	stone.roughness = 0.92
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.11
	pm.height = 0.72
	pm.radial_segments = 8
	post.mesh = pm
	post.position.y = 0.36
	post.material_override = stone
	root.add_child(post)
	var lamp := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.24, 0.24, 0.24)
	lamp.mesh = lm
	lamp.position.y = 0.84
	var glass := StandardMaterial3D.new()
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.emission_enabled = true
	glass.emission = Color(1.0, 0.68, 0.36)
	glass.emission_energy_multiplier = 1.4
	glass.albedo_color = Color(1.0, 0.78, 0.45)
	lamp.material_override = glass
	root.add_child(lamp)
	var cap := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.20
	cm.height = 0.12
	cm.radial_segments = 4
	cap.mesh = cm
	cap.position.y = 1.02
	cap.rotation_degrees.y = 45.0
	cap.material_override = stone
	root.add_child(cap)
	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.010
	glow.scale = Vector3.ONE * 1.0
	glow.modulate = Color(1.0, 0.74, 0.44, 0.55)
	glow.position.y = 0.84
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	root.add_child(glow)
	var light := OmniLight3D.new()
	light.position.y = 0.84
	light.light_color = Color(1.0, 0.70, 0.38)
	light.light_energy = 0.85
	light.omni_range = 3.8
	light.omni_attenuation = 1.6
	light.shadow_enabled = false
	root.add_child(light)


func _build_lantern_trail() -> void:
	# A narrower stone thread that links the seven lanterns into one walk.
	# It crosses the main path and makes the arc read as an exhibit trail
	# instead of seven unrelated poles.
	var curve := Curve3D.new()
	for p in [
		Vector3(-10.0, 0, -0.4), Vector3(-8.2, 0, -3.2), Vector3(-5.2, 0, -5.8),
		Vector3(-1.5, 0, -7.2), Vector3(2.2, 0, -6.4), Vector3(5.8, 0, -3.8),
		Vector3(8.8, 0, -0.4), Vector3(10.4, 0, 2.2),
	]:
		curve.add_point(p)
	var length := curve.get_baked_length()
	var steps := 72
	var start_index := _path_samples.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in steps + 1:
		var t := float(i) / float(steps)
		var p := curve.sample_baked(t * length)
		var p2 := curve.sample_baked(minf(t * length + 0.3, length))
		var tan := p2 - p
		tan.y = 0.0
		if tan.length() < 0.001:
			tan = Vector3(0, 0, -1)
		tan = tan.normalized()
		var side := Vector3(-tan.z, 0, tan.x)
		var w := 0.56 + 0.08 * sin(t * 7.0)
		var y := ground_height(p.x, p.z) + 0.038
		left.append(Vector3(p.x, y, p.z) + side * w)
		right.append(Vector3(p.x, y, p.z) - side * w)
		_path_samples.append(Vector3(p.x, y, p.z))
	for i in steps + 1:
		var warm := warmth_at(left[i].x, left[i].z)
		st.set_color(Color(0.13, 0.14, 0.13, warm))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, float(i) * 0.1))
		st.add_vertex(left[i])
		st.set_color(Color(0.13, 0.14, 0.13, warm))
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, float(i) * 0.1))
		st.add_vertex(right[i])
	for i in steps:
		var a := i * 2
		var b := a + 1
		var c := a + 2
		var d := a + 3
		st.add_index(a); st.add_index(c); st.add_index(b)
		st.add_index(b); st.add_index(c); st.add_index(d)
	var mi := MeshInstance3D.new()
	mi.name = "LanternTrail"
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/path_ink.gdshader")
	mat.set_shader_parameter("stone_color", Color(0.14, 0.15, 0.14))
	mat.set_shader_parameter("mortar_color", Color(0.035, 0.045, 0.05))
	mat.set_shader_parameter("warm_color", Color(1.0, 0.66, 0.34))
	mat.set_shader_parameter("warm_emission", 0.19)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

	var mats: Array[StandardMaterial3D] = []
	for band in 4:
		var sm := StandardMaterial3D.new()
		var warm := float(band) / 3.0
		sm.albedo_color = Color(0.26, 0.25, 0.22).lerp(Color(0.48, 0.35, 0.21), warm * 0.7)
		sm.roughness = 0.94
		sm.emission_enabled = true
		sm.emission = Color(1.0, 0.57, 0.28)
		sm.emission_energy_multiplier = 0.06 + warm * 0.30
		mats.append(sm)
	var i := 3
	var trail_count := _path_samples.size() - start_index
	while i < trail_count - 3:
		var p := _path_samples[start_index + i]
		var p2 := _path_samples[start_index + mini(i + 1, trail_count - 1)]
		var dir := p2 - p
		dir.y = 0.0
		var yaw := atan2(dir.x, dir.z)
		var warm := warmth_at(p.x, p.z)
		var slab := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = randf_range(0.34, 0.44)
		cyl.bottom_radius = 0.46
		cyl.height = 0.07
		cyl.radial_segments = 7
		slab.mesh = cyl
		slab.position = Vector3(p.x, ground_height(p.x, p.z) + 0.048, p.z)
		slab.rotation_degrees.y = rad_to_deg(yaw) + randf_range(-12.0, 12.0)
		slab.scale = Vector3(1.15, 1.0, 0.7)
		slab.material_override = mats[clampi(int(warm * 3.99), 0, 3)]
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(slab)
		i += 2


func _build_ridges() -> void:
	var defs := [
		{"pos": Vector3(-34, -7.0, -62.0), "scale": Vector3(58, 15, 26), "low": Color("0a1420"), "high": Color("142433")},
		{"pos": Vector3(32, -7.5, -74.0), "scale": Vector3(54, 13, 28), "low": Color("08111b"), "high": Color("111f2c")},
		{"pos": Vector3(-4, -9.0, -98.0), "scale": Vector3(86, 17, 34), "low": Color("060c14"), "high": Color("0d1722")},
		{"pos": Vector3(0, -10.0, -128.0), "scale": Vector3(120, 20, 40), "low": Color("04080e"), "high": Color("0a121c")},
	]
	for def in defs:
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 1.0
		sphere.radial_segments = 28
		sphere.rings = 14
		mi.mesh = sphere
		mi.position = def["pos"]
		mi.scale = def["scale"]
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/ridge.gdshader")
		mat.set_shader_parameter("low_color", def["low"])
		mat.set_shader_parameter("high_color", def["high"])
		mat.set_shader_parameter("base_y", float(def["pos"].y) - 4.0)
		mat.set_shader_parameter("top_y", float(def["pos"].y) + 10.0)
		mat.set_shader_parameter("mist", 0.32)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)

	# Warm village lights, far away on the first ridge.
	for i in 9:
		var light := Sprite3D.new()
		light.texture = load("res://assets/fx/glow.png")
		light.pixel_size = 0.035
		light.scale = Vector3.ONE * 0.8
		light.modulate = Color(1.0, 0.66, 0.32, 0.55)
		light.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		light.shaded = false
		light.position = Vector3(-33.0 + i * 2.1, -3.6 + sin(i * 2.3) * 0.7, -54.0 - abs(i - 4) * 0.3)
		add_child(light)


func _build_mist() -> void:
	var defs := [
		{"pos": Vector3(0, 3.0, -48), "size": Vector2(86, 15), "alpha": 0.15, "speed": 0.035},
		{"pos": Vector3(10, 5.0, -68), "size": Vector2(110, 20), "alpha": 0.13, "speed": -0.025},
		{"pos": Vector3(-12, 7.0, -92), "size": Vector2(140, 26), "alpha": 0.10, "speed": 0.018},
	]
	var tex := load("res://assets/fx/mist_band.png") if ResourceLoader.exists("res://assets/fx/mist_band.png") else null
	if tex == null:
		return
	for def in defs:
		var mi := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = def["size"]
		mi.mesh = quad
		mi.position = def["pos"]
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_texture = tex
		mat.albedo_color = Color(0.72, 0.79, 0.90, def["alpha"])
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.disable_receive_shadows = true
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_mists.append(mi)
		_mist_speeds.append(float(def["speed"]))


# --------------------------------------------------------------------------
# Observatory
# --------------------------------------------------------------------------

func set_sign_visible(v: bool) -> void:
	if sign_label:
		sign_label.visible = v


func _build_observatory() -> void:
	var y := ground_height(OBS_POS.x, OBS_POS.z)
	var root := Node3D.new()
	root.name = "Observatory"
	root.position = Vector3(OBS_POS.x, y, OBS_POS.z)
	root.scale = Vector3.ONE * 1.32
	add_child(root)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("172331")
	stone.roughness = 0.92
	var stone_dark := StandardMaterial3D.new()
	stone_dark.albedo_color = Color("0f1822")
	stone_dark.roughness = 0.95
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("8b6a37")
	brass.metallic = 0.85
	brass.roughness = 0.34
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.albedo_color = Color(1.0, 0.72, 0.38)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.64, 0.30)
	glow_mat.emission_energy_multiplier = 1.9

	# Plinth and drum.
	var plinth := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 4.35
	pm.bottom_radius = 4.65
	pm.height = 0.55
	pm.radial_segments = 32
	plinth.mesh = pm
	plinth.position.y = 0.27
	plinth.material_override = stone_dark
	root.add_child(plinth)

	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 3.55
	dm.bottom_radius = 3.85
	dm.height = 3.0
	dm.radial_segments = 32
	drum.mesh = dm
	drum.position.y = 2.05
	drum.material_override = stone
	root.add_child(drum)

	# Stone courses.
	for i in 4:
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 3.62 + i * 0.015
		rm.outer_radius = 3.70 + i * 0.015
		rm.rings = 36
		rm.ring_segments = 4
		ring.mesh = rm
		ring.position.y = 0.9 + i * 0.62
		ring.material_override = stone_dark
		root.add_child(ring)

	# Cornice.
	var cornice := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 4.05
	cm.bottom_radius = 3.85
	cm.height = 0.28
	cm.radial_segments = 32
	cornice.mesh = cm
	cornice.position.y = 3.62
	cornice.material_override = brass
	root.add_child(cornice)

	# Dome, with a slit and a telescope.
	_dome = Node3D.new()
	_dome.position.y = 3.72
	root.add_child(_dome)
	var dome := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 3.65
	sm.height = 3.65
	sm.is_hemisphere = true
	sm.radial_segments = 40
	sm.rings = 18
	dome.mesh = sm
	var dome_mat := ShaderMaterial.new()
	dome_mat.shader = load("res://shaders/dome_panel.gdshader")
	dome_mat.set_shader_parameter("dome_color", Color("223542"))
	dome_mat.set_shader_parameter("sheen_color", Color("637783"))
	dome_mat.set_shader_parameter("seam_color", Color("080e14"))
	dome_mat.set_shader_parameter("warm_color", Color(1.0, 0.66, 0.34))
	dome_mat.set_shader_parameter("warmth", 0.95)
	dome.material_override = dome_mat
	_dome.add_child(dome)

	# Slit housing and rails, aimed at the sky over the player's left shoulder.
	var slit := MeshInstance3D.new()
	var slitm := BoxMesh.new()
	slitm.size = Vector3(0.62, 2.55, 0.7)
	slit.mesh = slitm
	slit.position = Vector3(0, 1.75, 2.95)
	slit.rotation_degrees.x = 18.0
	var slit_mat := StandardMaterial3D.new()
	slit_mat.albedo_color = Color("05090e")
	slit_mat.roughness = 0.95
	slit.material_override = slit_mat
	_dome.add_child(slit)
	for sx in [-0.42, 0.42]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.07, 2.6, 0.10)
		rail.mesh = rm
		rail.position = Vector3(sx, 1.78, 3.02)
		rail.rotation_degrees.x = 18.0
		rail.material_override = brass
		_dome.add_child(rail)

	var scope := MeshInstance3D.new()
	var scm := CylinderMesh.new()
	scm.top_radius = 0.16
	scm.bottom_radius = 0.28
	scm.height = 2.9
	scm.radial_segments = 14
	scope.mesh = scm
	scope.position = Vector3(0.0, 1.62, 2.82)
	scope.rotation_degrees.x = 32.0
	scope.material_override = brass
	_dome.add_child(scope)
	var lens := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.34
	lm.bottom_radius = 0.28
	lm.height = 0.14
	lm.radial_segments = 16
	lens.mesh = lm
	lens.position = Vector3(0.0, 1.62 + 1.24, 2.82 + 0.77)
	lens.rotation_degrees.x = 32.0
	lens.material_override = stone_dark
	_dome.add_child(lens)
	var lens_glint := Sprite3D.new()
	lens_glint.texture = load("res://assets/fx/glow.png")
	lens_glint.pixel_size = 0.01
	lens_glint.scale = Vector3.ONE * 0.8
	lens_glint.modulate = Color(1.0, 0.82, 0.52, 0.55)
	lens_glint.position = lens.position
	lens_glint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lens_glint.shaded = false
	_dome.add_child(lens_glint)

	# Door, steps, windows.
	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(1.35, 2.15, 0.18)
	door.mesh = door_mesh
	door.position = Vector3(0, 1.35, 3.84)
	door.material_override = stone_dark
	root.add_child(door)
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.62, 2.42, 0.10)
	frame.mesh = frame_mesh
	frame.position = Vector3(0, 1.41, 3.80)
	frame.material_override = brass
	root.add_child(frame)
	var sill := MeshInstance3D.new()
	var sill_mesh := BoxMesh.new()
	sill_mesh.size = Vector3(1.55, 0.12, 0.22)
	sill.mesh = sill_mesh
	sill.position = Vector3(0, 0.30, 3.94)
	sill.material_override = brass
	root.add_child(sill)
	for i in 3:
		var step := MeshInstance3D.new()
		var stm := BoxMesh.new()
		stm.size = Vector3(2.1 - i * 0.22, 0.16, 0.55)
		step.mesh = stm
		step.position = Vector3(0, 0.10 - i * 0.03, 4.22 + i * 0.42)
		step.material_override = stone_dark
		root.add_child(step)

	# A warm strip under the door.
	var lintel := MeshInstance3D.new()
	var lim := BoxMesh.new()
	lim.size = Vector3(1.3, 0.05, 0.06)
	lintel.mesh = lim
	lintel.position = Vector3(0, 2.46, 3.92)
	lintel.material_override = glow_mat
	root.add_child(lintel)

	for s in [-1, 1]:
		var win := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = Vector3(0.55, 0.8, 0.08)
		win.mesh = wm
		win.position = Vector3(s * 2.25, 2.0, 3.05)
		win.rotation_degrees.y = s * 36.0
		win.material_override = glow_mat
		root.add_child(win)
		var wbar := MeshInstance3D.new()
		var wbm := BoxMesh.new()
		wbm.size = Vector3(0.65, 0.06, 0.10)
		wbar.mesh = wbm
		wbar.position = win.position
		wbar.rotation_degrees.y = win.rotation_degrees.y
		wbar.material_override = brass
		root.add_child(wbar)

	# A painted sign board on the facade, with the lettering on its face.
	var sign_board := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(3.05, 0.72, 0.07)
	sign_board.mesh = sbm
	sign_board.position = Vector3(0, 3.04, 3.96)
	var board_mat := StandardMaterial3D.new()
	board_mat.albedo_color = Color("101a24")
	board_mat.roughness = 0.9
	sign_board.material_override = board_mat
	root.add_child(sign_board)
	var sign_trim := MeshInstance3D.new()
	var stm := BoxMesh.new()
	stm.size = Vector3(2.62, 0.05, 0.08)
	sign_trim.mesh = stm
	sign_trim.position = Vector3(0, 3.34, 3.965)
	sign_trim.material_override = brass
	root.add_child(sign_trim)

	var sign := Label3D.new()
	sign.text = "ಚಂದ್ರಗಿರಿ ಆಕಾಶ ವೀಕ್ಷಣಾಲಯ"
	sign.font = UI.kannada_font()
	sign.font_size = 54
	sign.pixel_size = 0.0088
	sign.modulate = Color(1.0, 0.88, 0.64, 1.0)
	sign.outline_size = 0
	sign.position = Vector3(0, 3.08, 4.01)
	sign.no_depth_test = false
	root.add_child(sign)
	sign_label = sign
	# The English line is deliberately omitted: at classroom distance the
	# 3D type became a smudge. The painted Kannada sign is the diegetic mark.

	_obs_light = OmniLight3D.new()
	_obs_light.position = Vector3(0, 1.6, 4.3)
	_obs_light.light_color = Color(1.0, 0.68, 0.36)
	_obs_light.light_energy = 1.6
	_obs_light.omni_range = 8.5
	_obs_light.omni_attenuation = 1.6
	_obs_light.shadow_enabled = false
	root.add_child(_obs_light)

	var rim_light := OmniLight3D.new()
	rim_light.position = Vector3(0, 9.2, 8.0)
	rim_light.light_color = Color(0.52, 0.68, 1.0)
	rim_light.light_energy = 1.5
	rim_light.omni_range = 16.0
	rim_light.omni_attenuation = 1.1
	rim_light.shadow_enabled = false
	root.add_child(rim_light)

	var window_glow := Sprite3D.new()
	window_glow.texture = load("res://assets/fx/glow.png")
	window_glow.pixel_size = 0.012
	window_glow.scale = Vector3.ONE * 2.1
	window_glow.modulate = Color(1.0, 0.72, 0.40, 0.5)
	window_glow.position = Vector3(0, 1.5, 4.3)
	window_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	window_glow.shaded = false
	root.add_child(window_glow)

	# Two small brass path lanterns.
	for s in [-1, 1]:
		var bollard := Node3D.new()
		bollard.position = Vector3(s * 2.3, 0, 5.2)
		root.add_child(bollard)
		var post := MeshInstance3D.new()
		var pm2 := CylinderMesh.new()
		pm2.top_radius = 0.05
		pm2.bottom_radius = 0.07
		pm2.height = 0.9
		pm2.radial_segments = 8
		post.mesh = pm2
		post.position.y = 0.45
		post.material_override = brass
		bollard.add_child(post)
		var cage := MeshInstance3D.new()
		var cgm := BoxMesh.new()
		cgm.size = Vector3(0.28, 0.34, 0.28)
		cage.mesh = cgm
		cage.position.y = 1.02
		cage.material_override = glow_mat
		bollard.add_child(cage)


func _build_moon_light() -> void:
	_moon_light = DirectionalLight3D.new()
	_moon_light.name = "Moonlight"
	_moon_light.light_color = Color(0.64, 0.74, 1.0)
	_moon_light.light_energy = 0.42
	_moon_light.rotation_degrees = Vector3(-52, 26, 0)
	_moon_light.shadow_enabled = false
	add_child(_moon_light)


# --------------------------------------------------------------------------
# Trees, rocks, grass
# --------------------------------------------------------------------------

func _pine(pos: Vector3, s: float, shade: float) -> void:
	var y := ground_height(pos.x, pos.z)
	var root := Node3D.new()
	root.position = Vector3(pos.x, y, pos.z)
	root.scale = Vector3.ONE * s
	root.rotation_degrees.y = randf_range(0, 360)
	add_child(root)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.045, 0.040, 0.034)
	trunk_mat.roughness = 0.95
	var needle := StandardMaterial3D.new()
	needle.albedo_color = Color(0.030 + shade * 0.012, 0.058 + shade * 0.018, 0.055 + shade * 0.014)
	needle.roughness = 0.94
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.07
	tm.bottom_radius = 0.16
	tm.height = 2.1
	tm.radial_segments = 7
	trunk.mesh = tm
	trunk.position.y = 1.05
	trunk.material_override = trunk_mat
	root.add_child(trunk)
	for i in 5:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 1.35 - i * 0.20
		cm.height = 1.55
		cm.radial_segments = 9
		cone.mesh = cm
		cone.position = Vector3(sin(i * 2.2) * 0.07, 1.25 + i * 0.72, cos(i * 1.7) * 0.05)
		cone.rotation_degrees.y = i * 27.0
		cone.material_override = needle
		root.add_child(cone)


func _bare_tree(pos: Vector3, s: float) -> void:
	var y := ground_height(pos.x, pos.z)
	var root := Node3D.new()
	root.position = Vector3(pos.x, y, pos.z)
	root.scale = Vector3.ONE * s
	add_child(root)
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.045, 0.040, 0.036)
	bark.roughness = 0.95
	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.05
	tm.bottom_radius = 0.17
	tm.height = 2.5
	tm.radial_segments = 7
	trunk.mesh = tm
	trunk.position.y = 1.25
	trunk.material_override = bark
	root.add_child(trunk)
	for i in 5:
		var branch := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.012
		bm.bottom_radius = 0.05
		bm.height = 1.1 + i * 0.12
		bm.radial_segments = 5
		branch.mesh = bm
		branch.position.y = 1.7 + i * 0.22
		branch.rotation_degrees = Vector3(randf_range(-50, -20), i * 62.0, randf_range(-18, 18))
		branch.material_override = bark
		root.add_child(branch)


func _build_trees() -> void:
	var defs := [
		{"x": -20.5, "z": -17.0, "s": 1.6, "shade": 1.0},
		{"x": -16.0, "z": -25.0, "s": 1.9, "shade": 0.4},
		{"x": 17.5, "z": -18.0, "s": 1.7, "shade": 0.8},
		{"x": 23.0, "z": -27.0, "s": 2.1, "shade": 0.2},
		{"x": -27.0, "z": -30.0, "s": 2.4, "shade": 0.0},
		{"x": 30.0, "z": -11.0, "s": 1.4, "shade": 0.7},
		{"x": -25.0, "z": 1.0, "s": 1.2, "shade": 0.6},
		{"x": 25.0, "z": 4.0, "s": 1.1, "shade": 0.4},
		{"x": -18.0, "z": 8.0, "s": 0.9, "shade": 0.2},
		{"x": 19.0, "z": 10.0, "s": 0.8, "shade": 0.0},
	]
	for d in defs:
		_pine(Vector3(d["x"], 0, d["z"]), float(d["s"]), float(d["shade"]))
	_bare_tree(Vector3(-14.5, 0, -12.0), 1.15)
	_bare_tree(Vector3(14.5, 0, -11.0), 1.0)
	_bare_tree(Vector3(-23.0, 0, 7.0), 0.9)


func _build_horizon_treeline() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("08111a")
	for i in 19:
		var x := -48.0 + i * 5.3 + sin(i * 1.7) * 0.9
		var z := -53.0 - absf(i - 9.0) * 0.25
		var base_y := 0.4 + sin(i * 0.9) * 0.35
		for layer in 3:
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 1.45 - layer * 0.34
			cm.height = 1.9
			cm.radial_segments = 7
			cone.mesh = cm
			cone.position = Vector3(x, base_y + 1.2 + layer * 0.85, z)
			cone.rotation_degrees.y = i * 23.0
			cone.material_override = mat
			cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(cone)


func _build_bench() -> void:
	var y := ground_height(11.6, 4.4)
	var root := Node3D.new()
	root.position = Vector3(11.6, y, 4.4)
	root.rotation_degrees.y = -72.0
	root.scale = Vector3.ONE * 1.18
	add_child(root)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("3a2c1e")
	wood.roughness = 0.82
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color("0c1116")
	iron.metallic = 0.6
	iron.roughness = 0.6
	var seat := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.35, 0.12, 0.62)
	seat.mesh = sm
	seat.position.y = 0.55
	seat.material_override = wood
	root.add_child(seat)
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.35, 0.52, 0.10)
	back.mesh = bm
	back.position = Vector3(0, 0.95, -0.28)
	back.rotation_degrees.x = -10.0
	back.material_override = wood
	root.add_child(back)
	for x in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.12, 0.55, 0.52)
		leg.mesh = lm
		leg.position = Vector3(x, 0.275, 0)
		leg.material_override = iron
		root.add_child(leg)
	# A single small lantern left on the bench, as if someone just got up.
	var lamp := MeshInstance3D.new()
	var lm2 := SphereMesh.new()
	lm2.radius = 0.13
	lm2.height = 0.24
	lm2.radial_segments = 8
	lm2.rings = 5
	lamp.mesh = lm2
	lamp.position = Vector3(0.72, 0.78, 0.08)
	var lamp_mat := StandardMaterial3D.new()
	lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.68, 0.36)
	lamp_mat.emission_energy_multiplier = 1.5
	lamp_mat.albedo_color = Color(1.0, 0.78, 0.45)
	lamp.material_override = lamp_mat
	root.add_child(lamp)
	var halo := Sprite3D.new()
	halo.texture = load("res://assets/fx/glow.png")
	halo.pixel_size = 0.01
	halo.scale = Vector3.ONE * 1.4
	halo.modulate = Color(1.0, 0.74, 0.44, 0.65)
	halo.position = lamp.position
	halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	halo.shaded = false
	root.add_child(halo)
	var bench_light := OmniLight3D.new()
	bench_light.position = lamp.position
	bench_light.light_color = Color(1.0, 0.70, 0.40)
	bench_light.light_energy = 1.35
	bench_light.omni_range = 3.2
	bench_light.omni_attenuation = 1.5
	bench_light.shadow_enabled = false
	root.add_child(bench_light)


func _build_rocks() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.105, 0.115, 0.115)
	var spots := [
		Vector3(-6.6, 0, 2.2), Vector3(-2.0, 0, -1.7), Vector3(5.2, 0, 0.0),
		Vector3(8.6, 0, -10.8), Vector3(-11.5, 0, -9.2), Vector3(-1.2, 0, -13.0),
		Vector3(12.0, 0, 4.0), Vector3(-9.0, 0, -17.5),
	]
	for i in spots.size():
		var p: Vector3 = spots[i]
		var mi := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 1.0
		sphere.radial_segments = 7
		sphere.rings = 4
		mi.mesh = sphere
		mi.position = Vector3(p.x, ground_height(p.x, p.z) + 0.10, p.z)
		mi.scale = Vector3(randf_range(0.5, 1.0), randf_range(0.24, 0.45), randf_range(0.45, 0.8))
		mi.rotation_degrees.y = randf_range(0, 360)
		mi.material_override = mat
		add_child(mi)

	# Two big foreground boulders frame the view without blocking a lantern.
	for spec in [[Vector3(-12.8, 0, 10.0), Vector3(2.1, 0.85, 1.35)], [Vector3(13.2, 0, 8.6), Vector3(1.5, 0.62, 1.0)]]:
		var p: Vector3 = spec[0]
		var s: Vector3 = spec[1]
		var big := MeshInstance3D.new()
		var bs := SphereMesh.new()
		bs.radius = 1.0
		bs.height = 1.0
		bs.radial_segments = 8
		bs.rings = 5
		big.mesh = bs
		big.position = Vector3(p.x, ground_height(p.x, p.z) + s.y * 0.35, p.z)
		big.scale = s
		big.rotation_degrees.y = randf_range(0, 360)
		big.material_override = mat
		add_child(big)

	# A small stone cairn on the right makes the emptier side feel tended.
	var cairn := Node3D.new()
	cairn.position = Vector3(14.2, ground_height(14.2, -4.0), -4.0)
	add_child(cairn)
	for i in 3:
		var stone := MeshInstance3D.new()
		var ss := SphereMesh.new()
		ss.radius = 1.0
		ss.height = 1.0
		ss.radial_segments = 7
		ss.rings = 4
		stone.mesh = ss
		stone.position.y = 0.14 + i * 0.22
		stone.scale = Vector3(0.42 - i * 0.09, 0.16, 0.34 - i * 0.07)
		stone.rotation_degrees.y = randf_range(0, 360)
		stone.material_override = mat
		cairn.add_child(stone)


func _make_grass_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_index := 0
	for b in 3:
		var a := TAU * float(b) / 3.0
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var h := 0.34 + float(b) * 0.045
		var lean := dir * 0.10
		var v0 := -side * 0.035
		var v1 := side * 0.035
		var v2 := lean + Vector3(0, h, 0) - side * 0.006
		var v3 := lean + Vector3(0, h, 0) + side * 0.006
		st.set_uv(Vector2(0, 0)); st.set_color(Color(1, 1, 1, 1)); st.set_normal(Vector3.UP); st.add_vertex(v0)
		st.set_uv(Vector2(1, 0)); st.set_color(Color(1, 1, 1, 1)); st.set_normal(Vector3.UP); st.add_vertex(v1)
		st.set_uv(Vector2(1, 1)); st.set_color(Color(1, 1, 1, 1)); st.set_normal(Vector3.UP); st.add_vertex(v2)
		st.set_uv(Vector2(0, 1)); st.set_color(Color(1, 1, 1, 1)); st.set_normal(Vector3.UP); st.add_vertex(v3)
		st.add_index(base_index + 0); st.add_index(base_index + 2); st.add_index(base_index + 1)
		st.add_index(base_index + 1); st.add_index(base_index + 2); st.add_index(base_index + 3)
		base_index += 4
	return st.commit()


func _build_grass() -> void:
	var mesh := _make_grass_mesh()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var count := 650
	mm.instance_count = count
	var placed := 0
	var attempts := 0
	while placed < count and attempts < count * 8:
		attempts += 1
		var x := randf_range(-27.0, 27.0)
		var z := randf_range(-24.0, 15.0)
		var d_obs := Vector2(x - OBS_POS.x, z - OBS_POS.z).length()
		if d_obs < 5.2 or _near_path(x, z, 1.45):
			continue
		var y := ground_height(x, z)
		var basis := Basis(Vector3.UP, randf() * TAU).scaled(Vector3.ONE * randf_range(0.7, 1.45))
		mm.set_instance_transform(placed, Transform3D(basis, Vector3(x, y + 0.01, z)))
		var warm := warmth_at(x, z)
		mm.set_instance_color(placed, Color(1, 1, 1, warm * 0.8))
		placed += 1
	mm.instance_count = placed
	var mi := MultiMeshInstance3D.new()
	mi.name = "Grass"
	mi.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/grass_blade.gdshader")
	mat.set_shader_parameter("base_color", Color(0.042, 0.070, 0.060))
	mat.set_shader_parameter("tip_color", Color(0.115, 0.145, 0.105))
	mat.set_shader_parameter("warm_color", Color(1.0, 0.68, 0.36))
	mat.set_shader_parameter("sway", 0.11)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


# --------------------------------------------------------------------------
# Lanterns, particles, sky furniture
# --------------------------------------------------------------------------

func _build_lanterns() -> void:
	var idx := 1
	for spot in SPOTS:
		var id := str(spot["id"])
		var x := float(spot["x"])
		var z := float(spot["z"])
		var info := G.module_info(id)
		var lantern := SkyLantern.new()
		lantern.setup(id, str(info.get("title", id)), G.GOLD, idx)
		lantern.position = Vector3(x, ground_height(x, z), z)
		# The middle lanterns sit farther from the camera; a small scale lift
		# keeps their painted numbers as readable as 01 and 07.
		lantern.scale = Vector3.ONE * (1.0 if idx == 1 or idx == 7 else 1.14)
		lantern.done = G.is_done(id)
		add_child(lantern)
		lantern.chosen.connect(func(chosen_id: String): lantern_chosen.emit(chosen_id))
		lanterns[id] = lantern
		idx += 1


func _build_fireflies() -> void:
	var p := CPUParticles3D.new()
	p.amount = 16
	p.lifetime = 8.0
	p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(13, 3.6, 8)
	p.position = Vector3(0, 2.2, -4)
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.gravity = Vector3(0, 0.035, 0)
	p.initial_velocity_min = 0.04
	p.initial_velocity_max = 0.20
	p.scale_amount_min = 0.035
	p.scale_amount_max = 0.10
	p.color = Color(1.0, 0.84, 0.52, 0.72)
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

	# A cooler drift of tiny blue sparks near the observatory.
	var p2 := CPUParticles3D.new()
	p2.amount = 7
	p2.lifetime = 9.0
	p2.preprocess = 5.0
	p2.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p2.emission_sphere_radius = 5.0
	p2.position = Vector3(-6.0, 2.0, -12.0)
	p2.direction = Vector3(0, 1, 0)
	p2.spread = 60.0
	p2.gravity = Vector3(0, 0.02, 0)
	p2.initial_velocity_min = 0.03
	p2.initial_velocity_max = 0.12
	p2.scale_amount_min = 0.03
	p2.scale_amount_max = 0.07
	p2.color = Color(0.62, 0.80, 1.0, 0.55)
	var q2 := QuadMesh.new()
	q2.size = Vector2(1, 1)
	p2.mesh = q2
	p2.material_override = mat
	add_child(p2)


func _build_sky_lanterns() -> void:
	for i in 10:
		var n := Node3D.new()
		n.position = Vector3(randf_range(-24, 24), randf_range(6, 24), randf_range(-40, -8))
		add_child(n)
		var body := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.20
		sm.bottom_radius = 0.27
		sm.height = 0.52
		sm.radial_segments = 10
		body.mesh = sm
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/paper_lantern.gdshader")
		mat.set_shader_parameter("paper_color", Color("f2b56a"))
		mat.set_shader_parameter("light_color", Color("ffd48a"))
		mat.set_shader_parameter("rib_color", Color("4a2410"))
		mat.set_shader_parameter("lit", 0.92)
		mat.set_shader_parameter("done_tint", Color("ffe6ae"))
		mat.set_shader_parameter("ribs", 8.0)
		body.material_override = mat
		n.add_child(body)
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = Color("2a1a0d")
		cap_mat.roughness = 0.8
		for cy in [0.28, -0.28]:
			var cap := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.09
			cm.bottom_radius = 0.12
			cm.height = 0.05
			cm.radial_segments = 8
			cap.mesh = cm
			cap.position.y = cy
			cap.material_override = cap_mat
			n.add_child(cap)
		var glow := Sprite3D.new()
		glow.texture = load("res://assets/fx/glow.png")
		glow.pixel_size = 0.010
		glow.scale = Vector3.ONE * randf_range(1.0, 1.5)
		glow.modulate = Color(1.0, 0.74, 0.42, 0.45)
		glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glow.shaded = false
		n.add_child(glow)
		_sky_lanterns.append(n)
		_sky_speeds.append(randf_range(0.16, 0.42))
		_sky_phases.append(randf() * TAU)


func _build_moon() -> void:
	if not ResourceLoader.exists("res://assets/fx/moon_disc.png"):
		return
	var glow := Sprite3D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.pixel_size = 0.16
	glow.scale = Vector3.ONE * 2.7
	glow.modulate = Color(1.0, 0.92, 0.74, 0.22)
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	glow.position = Vector3(135, 96, -355)
	glow.render_priority = 18
	add_child(glow)

	var moon := Sprite3D.new()
	moon.name = "Moon"
	moon.texture = load("res://assets/fx/moon_disc.png")
	moon.pixel_size = 0.082
	moon.position = Vector3(135, 96, -355)
	moon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	moon.shaded = false
	moon.modulate = Color(1.0, 0.97, 0.88, 0.96)
	moon.render_priority = 19
	add_child(moon)


func _process(delta: float) -> void:
	_t += delta
	for i in _sky_lanterns.size():
		_sky_phases[i] += delta * 0.35
		var n := _sky_lanterns[i]
		n.position.y += _sky_speeds[i] * delta
		n.position.x += sin(_sky_phases[i]) * delta * 0.10
		if n.position.y > 30.0:
			n.position.y = 5.0
			n.position.x = randf_range(-24, 24)
			n.position.z = randf_range(-40, -8)
	for i in _mists.size():
		var m := _mists[i]
		m.position.x = fmod(m.position.x + _mist_speeds[i] * delta + 60.0, 120.0) - 60.0
	if _dome:
		_dome.rotation_degrees.y = sin(_t * 0.045) * 0.6
	if _obs_light:
		_obs_light.light_energy = 1.6 + sin(_t * 2.1) * 0.10


func set_lantern_done(id: String, value: bool) -> void:
	var lantern = lanterns.get(id)
	if lantern:
		lantern.set_done(value)


func set_lantern_hover(id: String, value: bool) -> void:
	var lantern = lanterns.get(id)
	if lantern:
		lantern.set_hover(value)


func activate_lantern(id: String) -> void:
	var lantern = lanterns.get(id)
	if lantern:
		lantern.activate()


func lantern_world_position(id: String) -> Vector3:
	var lantern = lanterns.get(id)
	if lantern == null:
		return Vector3.ZERO
	return lantern.global_transform * Vector3(0.72, 2.43, 0.0)

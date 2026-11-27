class_name SkyDome
extends Node3D
## The real sky: 8,800 HYG stars, constellation lines, nakshatra lines and
## a hand-written galactic sky shader. Works on the GL Compatibility renderer.

const STAR_RADIUS := 800.0
const LINE_RADIUS := 792.0

var star_mesh: MultiMeshInstance3D
var modern_lines: MeshInstance3D
var nak_lines: MeshInstance3D
var highlight_lines: MeshInstance3D
var label_root: Node3D
var env: WorldEnvironment
var sky_material: ShaderMaterial

var star_positions: PackedVector3Array = PackedVector3Array()
var star_indices: PackedInt32Array = PackedInt32Array()

var latitude_deg := 13.0
var sidereal_deg := 0.0
var show_modern := true
var show_nakshatra := false
var show_labels := false
var _highlight_id := ""

var _star_material: ShaderMaterial
var _line_material: ShaderMaterial


func _ready() -> void:
	_build_environment()
	_build_stars()
	_build_lines()
	_build_labels()
	set_latitude(latitude_deg)
	set_sidereal(sidereal_deg)


func _build_environment() -> void:
	env = WorldEnvironment.new()
	env.name = "NightEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ShaderMaterial.new()
	sky.sky_material.shader = load("res://shaders/sky.gdshader")
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	e.sky = sky
	sky_material = sky.sky_material
	if DisplayServer.is_touchscreen_available():
		sky_material.set_shader_parameter("low_quality", 1.0)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.30, 0.40, 0.62)
	e.ambient_light_energy = 0.55
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 1.0
	e.glow_enabled = false
	e.fog_enabled = false
	env.environment = e
	add_child(env)


func _build_stars() -> void:
	star_mesh = MultiMeshInstance3D.new()
	star_mesh.name = "Stars"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	mm.mesh = quad
	mm.instance_count = StarDB.hips.size()
	star_positions.resize(mm.instance_count)
	star_indices.resize(mm.instance_count)

	for i in mm.instance_count:
		var dir := StarDB.star_dir(i)
		var pos := dir * STAR_RADIUS
		star_positions[i] = pos
		mm.set_instance_transform(i, Transform3D(Basis(), pos))
		var m: float = StarDB.mag[i]
		var bv: float = StarDB.ci[i]
		var col := StarDB.star_color(bv)
		var bright: float = clampf(pow(10.0, -0.075 * (m - 0.4)), 0.18, 1.0)
		col = Color(col.r * bright, col.g * bright, col.b * bright, 1.0)
		mm.set_instance_color(i, col)
		var size: float = clampf(9.2 * pow(10.0, -0.105 * m), 0.9, 15.0)
		mm.set_instance_custom_data(i, Color(size, randf(), 0.0, 0.0))

	_star_material = ShaderMaterial.new()
	_star_material.shader = load("res://shaders/star.gdshader")
	_star_material.set_shader_parameter("intensity", 1.0)
	_star_material.render_priority = 1
	star_mesh.multimesh = mm
	star_mesh.material_override = _star_material
	star_mesh.custom_aabb = AABB(Vector3(-900, -900, -900), Vector3(1800, 1800, 1800))
	star_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(star_mesh)


func _line_mesh(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var count := 0
	for c in StarDB.constellations:
		for e in c.get("edges", []):
			var a: int = StarDB.star_index_by_hip(int(e[0]))
			var b: int = StarDB.star_index_by_hip(int(e[1]))
			if a < 0 or b < 0:
				continue
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(StarDB.star_dir(a) * radius)
			mesh.surface_set_color(color)
			mesh.surface_add_vertex(StarDB.star_dir(b) * radius)
			count += 1
	mesh.surface_end()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/line.gdshader")
	mat.set_shader_parameter("alpha", 1.0)
	mi.mesh = mesh
	mi.material_override = mat
	mi.custom_aabb = AABB(Vector3(-900, -900, -900), Vector3(1800, 1800, 1800))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("edge_count", count)
	add_child(mi)
	return mi


func _build_lines() -> void:
	modern_lines = _line_mesh(LINE_RADIUS, Color(G.GOLD, 0.62))
	modern_lines.name = "ModernConstellations"

	# Nakshatra lines use a different mesh builder.
	nak_lines = MeshInstance3D.new()
	nak_lines.name = "Nakshatras"
	var nm := ImmediateMesh.new()
	nm.surface_begin(Mesh.PRIMITIVE_LINES)
	for n in StarDB.nakshatras:
		for e in n.get("edges", []):
			var a: int = StarDB.star_index_by_hip(int(e[0]))
			var b: int = StarDB.star_index_by_hip(int(e[1]))
			if a < 0 or b < 0:
				continue
			nm.surface_set_color(Color(G.TEAL, 0.50))
			nm.surface_add_vertex(StarDB.star_dir(a) * (LINE_RADIUS - 4.0))
			nm.surface_set_color(Color(G.TEAL, 0.50))
			nm.surface_add_vertex(StarDB.star_dir(b) * (LINE_RADIUS - 4.0))
	nm.surface_end()
	var nmat := ShaderMaterial.new()
	nmat.shader = load("res://shaders/line.gdshader")
	nmat.set_shader_parameter("alpha", 1.0)
	nak_lines.mesh = nm
	nak_lines.material_override = nmat
	nak_lines.custom_aabb = AABB(Vector3(-900, -900, -900), Vector3(1800, 1800, 1800))
	nak_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(nak_lines)

	highlight_lines = MeshInstance3D.new()
	highlight_lines.name = "Highlight"
	highlight_lines.mesh = ImmediateMesh.new()
	var hl := ShaderMaterial.new()
	hl.shader = load("res://shaders/line.gdshader")
	hl.set_shader_parameter("alpha", 1.0)
	highlight_lines.material_override = hl
	highlight_lines.custom_aabb = AABB(Vector3(-900, -900, -900), Vector3(1800, 1800, 1800))
	highlight_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(highlight_lines)

	modern_lines.visible = show_modern
	nak_lines.visible = show_nakshatra
	highlight_lines.visible = false


func _build_labels() -> void:
	label_root = Node3D.new()
	label_root.name = "SkyLabels"
	add_child(label_root)
	label_root.visible = false


func _make_labels() -> void:
	if label_root.get_child_count() > 0:
		return
	var shown := 0
	for ns in StarDB.named_stars:
		if float(ns.get("mag", 9.0)) > 2.3:
			continue
		var hip: int = int(ns.get("hip", 0))
		var idx := StarDB.star_index_by_hip(hip)
		if idx < 0:
			continue
		var l := Label3D.new()
		l.text = str(ns.get("name", ""))
		l.font = UI.body_med_font()
		l.font_size = 64
		l.pixel_size = 0.20
		l.modulate = Color(G.CREAM, 1.0)
		l.outline_size = 12
		l.outline_modulate = Color(0.01, 0.02, 0.05, 0.98)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = StarDB.star_dir(idx) * (STAR_RADIUS - 14.0)
		l.render_priority = 3
		l.set_meta("base_alpha", 1.0)
		label_root.add_child(l)
		shown += 1
		if shown >= 34:
			break
	# Every IAU constellation gets a name; at any one view only a handful are
	# on screen, so the atlas reads as a real printed chart rather than a blank.
	for c in StarDB.constellations:
		var cid := str(c.get("id", ""))
		var center := constellation_center(cid)
		var l := Label3D.new()
		l.text = str(c.get("name", cid))
		l.font = UI.serif_font()
		l.font_size = 84
		l.pixel_size = 0.24
		l.modulate = Color(0.99, 0.86, 0.62, 1.0)
		l.outline_size = 15
		l.outline_modulate = Color(0.01, 0.02, 0.05, 0.99)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = center * (STAR_RADIUS - 30.0)
		l.render_priority = 3
		l.set_meta("base_alpha", 1.0)
		label_root.add_child(l)


func set_labels(value: bool) -> void:
	show_labels = value
	if value:
		_make_labels()
	label_root.visible = value


func _process(_delta: float) -> void:
	# Labels are 3D billboards; fade them before their text can clip on the
	# viewport edge or disappear under the Atlas panel.
	if not label_root or not label_root.visible:
		return
	var cam := get_viewport().get_camera_3d()
	if not cam:
		return
	var vp := get_viewport().get_visible_rect().size
	for l in label_root.get_children():
		var base := float(l.get_meta("base_alpha", 1.0))
		var wp: Vector3 = l.global_position
		if cam.is_position_behind(wp):
			l.modulate.a = 0.0
			continue
		var sp := cam.unproject_position(wp)
		var edge := minf(minf(sp.x, vp.x - sp.x), minf(sp.y, vp.y - sp.y))
		var a := 0.0 if edge < 40.0 else clampf((edge - 40.0) / 80.0, 0.0, 1.0)
		l.modulate.a = base * a


func set_star_scale(value: float) -> void:
	if _star_material:
		_star_material.set_shader_parameter("size_scale", value)


func set_star_intensity(value: float) -> void:
	if _star_material:
		_star_material.set_shader_parameter("intensity", value)


func set_modern_lines(value: bool) -> void:
	show_modern = value
	if modern_lines:
		modern_lines.visible = value


func set_nakshatra_lines(value: bool) -> void:
	show_nakshatra = value
	if nak_lines:
		nak_lines.visible = value


func _apply_basis(b: Basis) -> void:
	basis = b
	if sky_material:
		sky_material.set_shader_parameter("sky_basis", b)


func set_latitude(lat: float) -> void:
	latitude_deg = clampf(lat, -80.0, 80.0)
	set_sidereal(sidereal_deg)


func set_hour(hour: float) -> void:
	# 15 degrees of sidereal rotation per hour; the offset is chosen so the
	# night sky feels right for an evening in early winter in India.
	set_sidereal(hour * 15.0 + 95.0)


func set_sidereal(deg: float) -> void:
	sidereal_deg = fmod(deg, 360.0)
	var tilt := deg_to_rad(-(90.0 - latitude_deg))
	var spin := deg_to_rad(90.0 - sidereal_deg)
	_apply_basis(Basis(Vector3.RIGHT, tilt) * Basis(Vector3.UP, spin))


func guided_to_ra_dec(ra_deg: float, dec_deg: float, camera_forward: Vector3) -> void:
	var local := StarDB.dir_from_ra_dec(ra_deg, dec_deg)
	var target := camera_forward.normalized()
	_apply_basis(Basis(Quaternion(local, target)))


func guided_to_constellation(id: String) -> Dictionary:
	var c := StarDB.constellation(id)
	if c.is_empty():
		return {}
	var center := constellation_center(id)
	var ra = atan2(-center.z, center.x)
	var dec = asin(clampf(center.y, -1.0, 1.0))
	var ra_deg = fposmod(rad_to_deg(ra), 360.0)
	var dec_deg = rad_to_deg(dec)
	guided_to_ra_dec(ra_deg, dec_deg, Vector3(0, 0, -1))
	return {"ra": ra_deg, "dec": dec_deg}


func constellation_center(id: String) -> Vector3:
	var c := StarDB.constellation(id)
	var sum := Vector3.ZERO
	var n := 0
	for hip in c.get("stars", []):
		var idx := StarDB.star_index_by_hip(int(hip))
		if idx >= 0:
			sum += StarDB.star_dir(idx)
			n += 1
	if n == 0:
		return Vector3(0, 0, -1)
	return sum.normalized()


func set_highlight(id: String, color: Color) -> void:
	_highlight_id = id
	var mesh := ImmediateMesh.new()
	var c := StarDB.constellation(id)
	if not c.is_empty():
		mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		for e in c.get("edges", []):
			var a: int = StarDB.star_index_by_hip(int(e[0]))
			var b: int = StarDB.star_index_by_hip(int(e[1]))
			if a < 0 or b < 0:
				continue
			mesh.surface_set_color(Color(color, 0.95))
			mesh.surface_add_vertex(StarDB.star_dir(a) * (LINE_RADIUS + 6.0))
			mesh.surface_set_color(Color(color, 0.95))
			mesh.surface_add_vertex(StarDB.star_dir(b) * (LINE_RADIUS + 6.0))
		mesh.surface_end()
	highlight_lines.mesh = mesh
	highlight_lines.visible = not c.is_empty()


func clear_highlight() -> void:
	_highlight_id = ""
	if highlight_lines:
		highlight_lines.visible = false


func star_world(i: int) -> Vector3:
	return global_transform * star_positions[i]


func star_screen(i: int, cam: Camera3D) -> Vector2:
	return cam.unproject_position(star_world(i))


func pick_star(screen_pos: Vector2, cam: Camera3D, radius_px: float = 34.0) -> Dictionary:
	# Prefer the brightest star under the finger. A human is tapping the visible
	# dot, not the faintest catalogue entry that happens to be nearby.
	var candidates: Array = []
	var vp := get_viewport()
	var screen_size := vp.get_visible_rect().size
	var r2 := radius_px * radius_px
	for i in star_positions.size():
		var w := star_world(i)
		if cam.is_position_behind(w):
			continue
		var sp := cam.unproject_position(w)
		if sp.x < -50 or sp.y < -50 or sp.x > screen_size.x + 50 or sp.y > screen_size.y + 50:
			continue
		var d := sp.distance_squared_to(screen_pos)
		if d < r2:
			candidates.append({"i": i, "d": d, "mag": StarDB.mag[i]})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a, b):
		if absf(float(a["mag"]) - float(b["mag"])) > 0.35:
			return float(a["mag"]) < float(b["mag"])
		return float(a["d"]) < float(b["d"]))
	var best: int = int(candidates[0]["i"])
	return {"index": best, "hip": StarDB.hips[best], "screen": star_screen(best, cam)}


func random_star_index_for_hip(hip: int) -> int:
	return StarDB.star_index_by_hip(hip)

class_name ShootingStarField
extends Node3D
## A quiet meteor every so often: a tapered ribbon in the sky, drawn additively.
## One at a time, no particle storm. Works in any 3D scene with a current camera.

var camera: Camera3D
var _timer := 6.0
var _active := false
var _t := 0.0
var _life := 1.0
var _start := Vector3.ZERO
var _dir := Vector3.ZERO
var _length := 22.0
var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _spark: Sprite3D


func _ready() -> void:
	_timer = randf_range(4.0, 9.0)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Meteor"
	_mesh.mesh = ImmediateMesh.new()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.no_depth_test = true
	_mat.disable_receive_shadows = true
	_mesh.material_override = _mat
	_mesh.visible = false
	add_child(_mesh)

	_spark = Sprite3D.new()
	_spark.texture = load("res://assets/fx/glow.png")
	_spark.pixel_size = 0.02
	_spark.scale = Vector3.ONE * 1.6
	_spark.modulate = Color(1.0, 0.86, 0.62, 0.9)
	_spark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_spark.shaded = false
	_spark.no_depth_test = true
	_spark.render_priority = 12
	_spark.visible = false
	add_child(_spark)


func _process(delta: float) -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	if not _active:
		_timer -= delta
		if _timer <= 0.0:
			_spawn()
		return
	_t += delta / _life
	if _t >= 1.0:
		_active = false
		_mesh.visible = false
		_spark.visible = false
		_timer = randf_range(8.0, 18.0)
		return
	_draw_streak()


func _spawn() -> void:
	var b := camera.global_transform.basis
	var forward := -b.z
	var right := b.x
	var up := b.y
	var anchor := (camera.global_position + forward * randf_range(55.0, 85.0)
		+ right * randf_range(-28.0, 28.0) + up * randf_range(10.0, 26.0))
	var heading := (right * randf_range(-1.0, 1.0) + up * randf_range(-0.55, -0.1)).normalized()
	_start = anchor
	_dir = heading
	_length = randf_range(14.0, 30.0)
	_life = randf_range(0.7, 1.25)
	_t = 0.0
	_active = true
	_mesh.visible = true
	_spark.visible = true


func _draw_streak() -> void:
	var head := _start + _dir * _length * _t
	var tail := head - _dir * _length * 0.42
	var side := _dir.cross((camera.global_position - head).normalized()).normalized()
	if side.length() < 0.01:
		side = Vector3.UP
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var segments := 7
	for i in segments + 1:
		var f := float(i) / float(segments)
		var p := tail.lerp(head, f)
		var width := 0.34 * pow(f, 1.9)
		var fade := pow(f, 2.1)
		var col := Color(1.0, 0.88, 0.66, fade * 0.92)
		im.surface_set_color(col)
		im.surface_add_vertex(p - side * width)
		im.surface_set_color(Color(col.r, col.g, col.b, col.a * 0.15))
		im.surface_add_vertex(p + side * width)
	im.surface_end()
	_mesh.mesh = im
	_spark.position = head
	var tw := 1.2 + sin(Time.get_ticks_msec() * 0.02) * 0.2
	_spark.scale = Vector3.ONE * tw * (1.0 - _t * 0.35)

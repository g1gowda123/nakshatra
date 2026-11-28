extends CanvasLayer
## The Cassette Futurism tube.
##
## One autoload, every scene: a quiet CRT pass over the finished frame plus a
## physical bezel around the viewport. The shader is subtle enough that the
## lesson text stays readable; the bezel is the only "hardware" the player sees.

var _scan: ColorRect
var _bezel: Panel
var _hairline: Panel


func _ready() -> void:
	layer = 220
	_scan = ColorRect.new()
	_scan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/crt_futurism.gdshader")
	m.set_shader_parameter("scanline_strength", Design.SCANLINE_STRENGTH)
	m.set_shader_parameter("scanline_count", Design.SCANLINE_COUNT)
	m.set_shader_parameter("vignette_strength", Design.VIGNETTE_STRENGTH)
	m.set_shader_parameter("noise_strength", Design.NOISE_STRENGTH)
	m.set_shader_parameter("chromatic_split", Design.CHROMATIC_SPLIT)
	m.set_shader_parameter("phosphor_tint", Vector3(Design.PHOSPHOR.r, Design.PHOSPHOR.g, Design.PHOSPHOR.b))
	_scan.material = m
	add_child(_scan)

	_bezel = Panel.new()
	_bezel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Design.BEZEL
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(Design.BEZEL_CORNER)
	_bezel.add_theme_stylebox_override("panel", sb)
	add_child(_bezel)

	_hairline = Panel.new()
	_hairline.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hairline.offset_left = 6
	_hairline.offset_top = 6
	_hairline.offset_right = -6
	_hairline.offset_bottom = -6
	_hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb2 := StyleBoxFlat.new()
	sb2.draw_center = false
	sb2.bg_color = Color(0, 0, 0, 0)
	sb2.border_color = Color(Design.PHOSPHOR, 0.22)
	sb2.set_border_width_all(1)
	sb2.set_corner_radius_all(2)
	_hairline.add_theme_stylebox_override("panel", sb2)
	add_child(_hairline)
	if G.reduced_motion:
		set_reduced_motion(true)


func set_reduced_motion(reduced: bool) -> void:
	# Keep the language, lose the motion-heavy part of the tube.
	_scan.visible = not reduced
	_bezel.visible = true
	_hairline.visible = true

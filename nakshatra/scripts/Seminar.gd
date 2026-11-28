extends Node3D
## Seminar mode: a presenter-first walkthrough that lives inside the game.
##
## Twelve slides, real project numbers, speaker notes, a rehearsal timer,
## auto-advance for a hands-free attract loop, a pre-flight check and a
## one-click jump into any exhibit. Designed to be projected: large type,
## high contrast, and every control reachable from the keyboard.

const LAB_PATH := "res://scenes/Lab.tscn"
const DEFAULT_SECONDS := 50.0

var sky: SkyDome
var cam: Camera3D
var ui: Control
var content_root: Control
var slides: Array = []

var index := 0
var auto_play := false
var auto_left := DEFAULT_SECONDS
var auto_total := DEFAULT_SECONDS
var timer_running := true
var elapsed := 0.0
var _save_acc := 0.0
var notes_visible := false

var _portrait := false
var _compact := false
var _checking := false
var _checks_overlay: Control
var _figure_overlay: Control
var _notes_panel: PanelContainer
var _toast_seq := 0

# --- live UI references -------------------------------------------------
var kicker_lbl: Label
var title_lbl: Label
var subtitle_lbl: Label
var bullets_box: VBoxContainer
var stats_box: HFlowContainer
var image_art
var image_rect: TextureRect
var fig_btn: Button
var caption_lbl: Label
var counter_lbl: Label
var timer_lbl: Label
var auto_btn: Button
var notes_btn: Button
var lab_btn: Button
var home_btn: Button
var prev_btn: Button
var next_btn: Button
var auto_fill: ColorRect
var auto_track: Control
var dots_box: HBoxContainer
var notes_text: Label
var notes_time: Label
var cue_panel: PanelContainer
var cue_text: Label
var cue_visible := false
var dot_buttons: Array[Button] = []
# Portrait slides are taller than the phone: the note pane scrolls, so the
# bottom edge fades out and offers a scroll cue until the reader reaches it.
var portrait_scroll: ScrollContainer
var scroll_fade: TextureRect
var scroll_cue: Label

# --- small floating lights behind the deck ------------------------------
var _lanterns: Array[Node3D] = []
var _lantern_speeds: Array[float] = []


class ArtFrame:
	extends Control
	## A framed image that keeps its height proportional to its width.
	var ratio := 16.0 / 9.0
	var max_height := 0.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			var w := size.x
			if w > 1.0:
				var h := w / maxf(ratio, 0.1)
				if max_height > 0.0:
					h = minf(h, max_height)
				if absf(custom_minimum_size.y - h) > 0.5:
					custom_minimum_size.y = h


func _ready() -> void:
	_load_slides()
	elapsed = G.seminar_elapsed
	G.seminar_return = false
	var portrait_now := UI.is_portrait()
	if not portrait_now:
		_set_deck_canvas()
	_portrait = UI.is_portrait()
	_compact = UI.is_compact()
	_build_world()
	_build_ui()
	_apply_slide()
	var start: int = clampi(G.seminar_index, 0, maxi(slides.size() - 1, 0))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--slide="):
			start = int(a.get_slice("=", 1)) - 1
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('slide') || ''", true)
		if typeof(raw) == TYPE_STRING and str(raw).is_valid_int():
			start = int(str(raw)) - 1
	if start > 0:
		_go(start, false)
	if OS.get_cmdline_user_args().has("--cue"):
		_show_cue()
	if OS.get_cmdline_user_args().has("--notes"):
		_show_notes()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)


# ======================================================================
# Data
# ======================================================================

func _load_slides() -> void:
	var data: Dictionary = G.content.get("seminar", {})
	var raw: Array = data.get("slides", [])
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY:
			slides.append(_normalise_slide(item))
	if slides.is_empty():
		slides.append(_fallback_slide())
	for s in slides:
		_apply_tokens(s)


func _normalise_slide(src: Dictionary) -> Dictionary:
	var bullets: Array = []
	for b in src.get("bullets", []):
		bullets.append(str(b))
	var stats: Array = []
	for st in src.get("stats", []):
		stats.append(str(st))
	return {
		"kicker": str(src.get("kicker", "")),
		"title": str(src.get("title", "Untitled slide")),
		"subtitle": str(src.get("subtitle", "")),
		"bullets": bullets,
		"stats": stats,
		"note": str(src.get("note", "No speaker note for this slide.")),
		"image": str(src.get("image", "")),
		"caption": str(src.get("caption", "")),
		"lab": str(src.get("lab", "")),
		"lab_label": str(src.get("lab_label", "Open this exhibit")),
		"seconds": maxf(12.0, float(src.get("seconds", DEFAULT_SECONDS))),
		"sky": str(src.get("sky", "stars")),
	}


func _fallback_slide() -> Dictionary:
	return {
		"kicker": "SEMINAR MODE",
		"title": "Seminar content is missing",
		"subtitle": "The game is fine; data/content.json needs its 'seminar' chapter.",
		"bullets": [
			"Restore the seminar chapter in data/content.json.",
			"Or open the Sky Lab and show the exhibits directly.",
		],
		"stats": [],
		"note": "The presentation content could not be loaded. The rest of the game is unaffected.",
		"image": "",
		"caption": "",
		"lab": LAB_PATH,
		"lab_label": "Open the Sky Lab",
		"seconds": 30.0,
		"sky": "stars",
	}


func _apply_tokens(slide: Dictionary) -> void:
	for key in ["kicker", "title", "subtitle", "note", "caption", "lab_label"]:
		slide[key] = _tok(str(slide.get(key, "")))
	var bullets: Array = []
	for b in slide.get("bullets", []):
		bullets.append(_tok(str(b)))
	slide["bullets"] = bullets
	var stats: Array = []
	for st in slide.get("stats", []):
		stats.append(_tok(str(st)))
	slide["stats"] = stats


func _tok(text: String) -> String:
	return text \
		.replace("{stars}", _num(StarDB.hips.size())) \
		.replace("{constellations}", str(StarDB.constellations.size())) \
		.replace("{nakshatras}", str(StarDB.nakshatras.size())) \
		.replace("{quiz}", str((G.content.get("quiz", []) as Array).size())) \
		.replace("{wonders}", str((G.content.get("wonders", []) as Array).size())) \
		.replace("{modules}", str(G.MODULES.size())) \
		.replace("{version}", G.VERSION)


func _num(n: int) -> String:
	var raw := str(absi(n))
	if raw.length() <= 3:
		return ("-" if n < 0 else "") + raw
	var last := raw.substr(raw.length() - 3, 3)
	var head := raw.substr(0, raw.length() - 3)
	var groups := ""
	while head.length() > 2:
		groups = "," + head.substr(head.length() - 2, 2) + groups
		head = head.substr(0, head.length() - 2)
	if head != "":
		groups = head + groups
	return ("-" if n < 0 else "") + groups + "," + last


# ======================================================================
# World
# ======================================================================

func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 52.0
	cam.position = Vector3.ZERO
	cam.rotation_degrees = Vector3(-5.0, 0.0, 0.0)
	cam.current = true
	add_child(cam)

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 112.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_nakshatra_lines(false)
	sky.set_star_scale(1.35)
	sky.set_star_intensity(1.12)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.45

	_build_lanterns()


func _build_lanterns() -> void:
	for i in 9:
		var n := Node3D.new()
		n.position = Vector3(randf_range(-32.0, 32.0), randf_range(3.0, 22.0), randf_range(-95.0, -45.0))
		add_child(n)
		var body := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.32
		sm.height = 0.62
		body.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 0.72, 0.4, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.6, 0.26)
		mat.emission_energy_multiplier = 1.4
		body.material_override = mat
		n.add_child(body)
		var glow := Sprite3D.new()
		glow.texture = load("res://assets/fx/glow.png")
		glow.pixel_size = 0.012
		glow.scale = Vector3.ONE * randf_range(1.4, 2.4)
		glow.modulate = Color(1.0, 0.74, 0.42, 0.45)
		glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glow.shaded = false
		n.add_child(glow)
		_lanterns.append(n)
		_lantern_speeds.append(randf_range(0.08, 0.22))


func _apply_sky_mode(mode: String) -> void:
	if sky == null:
		return
	match mode:
		"lines":
			sky.set_modern_lines(true)
			sky.set_nakshatra_lines(false)
			if sky.modern_lines and sky.modern_lines.material_override:
				(sky.modern_lines.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.55)
			sky.set_star_intensity(1.0)
		"nakshatra":
			sky.set_modern_lines(false)
			sky.set_nakshatra_lines(true)
			if sky.nak_lines and sky.nak_lines.material_override:
				(sky.nak_lines.material_override as ShaderMaterial).set_shader_parameter("alpha", 0.7)
			sky.set_star_intensity(1.0)
		_:
			sky.set_modern_lines(false)
			sky.set_nakshatra_lines(false)
			sky.set_star_intensity(1.12)


# ======================================================================
# UI
# ======================================================================

func _build_ui() -> void:
	if ui:
		ui.queue_free()
	dot_buttons.clear()
	ui = null
	_checks_overlay = null
	_checking = false
	_figure_overlay = null

	ui = Control.new()
	ui.name = "SeminarUI"
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = UI.theme()
	add_child(ui)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui.add_child(vignette)

	ui.add_child(_readability_gradient())

	var outer := UI.margin(UI.pad(), 12, UI.pad(), 10)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(outer)
	var col := UI.vbox(0)
	outer.add_child(col)

	col.add_child(_top_bar())
	auto_track = _auto_track()
	col.add_child(auto_track)

	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(body)
	content_root = body
	if _portrait:
		_build_portrait_body(body)
	else:
		_build_landscape_body(body)

	col.add_child(_footer())

	_notes_panel = null
	if notes_visible:
		_show_notes()

	UI.fade_in(ui, 0.0, 0.35)


func _readability_gradient() -> TextureRect:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	var dark := Color(0.024, 0.039, 0.078, 1.0)
	if _portrait:
		grad.colors = PackedColorArray([Color(dark, 0.18), Color(dark, 0.55), Color(dark, 0.9)])
	else:
		grad.colors = PackedColorArray([Color(dark, 0.94), Color(dark, 0.70), Color(dark, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	if _portrait:
		tex.fill_from = Vector2(0.0, 0.0)
		tex.fill_to = Vector2(0.0, 1.0)
	else:
		tex.fill_from = Vector2(0.0, 0.0)
		tex.fill_to = Vector2(0.78, 0.0)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


func _top_bar() -> Control:
	var bar := UI.hbox(8)
	bar.custom_minimum_size.y = 44
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var brand_row := UI.hbox(8)
	brand_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(brand_row)
	brand_row.add_child(UI.brand_mark(18))
	var brand := UI.vbox(0)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	brand_row.add_child(brand)
	var title := UI.tracked("NAKSHATRA", 12 if not _compact else 11, Color(G.GOLD, 0.95), 3)
	brand.add_child(title)
	var sub_text := "SEMINAR EDITION  ·  REAL SKY AT 13° N" if not _compact else "SEMINAR  ·  13° N"
	var sub := UI.micro(sub_text, Color(G.MUTED, 0.85), 7)
	brand.add_child(sub)

	bar.add_child(UI.spacer())

	counter_lbl = UI.label("01 / 12", 12 if not _compact else 10, G.GOLD, "body_med")
	counter_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	counter_lbl.custom_minimum_size.x = 58 if not _compact else 46
	bar.add_child(counter_lbl)

	if not _compact:
		timer_lbl = UI.label("TIME 00:00", 11, Color(G.MUTED, 1.0), "body_med")
		timer_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
		timer_lbl.custom_minimum_size.x = 74
		bar.add_child(timer_lbl)

	if _compact:
		var menu := UI.ghost_button("Menu", 12)
		menu.custom_minimum_size = Vector2(68, 32)
		menu.pressed.connect(func():
			Sfx.play("click")
			_show_controls())
		bar.add_child(menu)
	else:
		notes_btn = _bar_button("Cue · N")
		notes_btn.tooltip_text = "One-sentence cue (Shift+N: full notes)"
		notes_btn.pressed.connect(_toggle_notes)
		bar.add_child(notes_btn)
		auto_btn = _bar_button("Auto · A")
		auto_btn.pressed.connect(_toggle_auto)
		bar.add_child(auto_btn)
		var checks := _bar_button("Checks · D")
		checks.pressed.connect(_open_checks)
		bar.add_child(checks)
		var full := _bar_button("Full · F")
		full.pressed.connect(_toggle_fullscreen)
		bar.add_child(full)
		var exit := _bar_button("Sky Lab")
		exit.pressed.connect(_exit)
		bar.add_child(exit)

	_update_auto_label()
	return bar


func _bar_button(text: String) -> Button:
	var b := UI.ghost_button(text, 11)
	b.custom_minimum_size = Vector2(0, 34)
	b.add_theme_constant_override("outline_size", 0)
	return b


func _auto_track() -> Control:
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 3)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color(G.GOLD, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(bg)
	auto_fill = ColorRect.new()
	auto_fill.color = Color(G.GOLD, 0.85)
	auto_fill.anchor_left = 0.0
	auto_fill.anchor_top = 0.0
	auto_fill.anchor_right = 0.0
	auto_fill.anchor_bottom = 1.0
	auto_fill.offset_left = 0
	auto_fill.offset_top = 0
	auto_fill.offset_right = 0
	auto_fill.offset_bottom = 0
	auto_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(auto_fill)
	return track


func _build_landscape_body(body: Control) -> void:
	var h := UI.hbox(56)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(h)

	var left := UI.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.14
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(left)
	var text_wrap := UI.margin(2, 0, 20, 0)
	text_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _compact:
		text_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var scroll := UI.scroll()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		left.add_child(scroll)
		scroll.add_child(text_wrap)
	else:
		left.add_child(text_wrap)
	_build_text_column(text_wrap, _compact)

	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.86
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(right)
	_build_visual_column(right)


func _build_portrait_body(body: Control) -> void:
	var v := UI.vbox(10)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(v)

	var visual := UI.vbox(4)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(visual)
	_build_visual_column(visual)

	var wrap := UI.vbox(0)
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(wrap)

	var holder := Control.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(holder)

	var scroll := UI.scroll()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(scroll)
	portrait_scroll = scroll
	var margin := UI.margin(2, 4, 2, 16)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# A ScrollContainer measures its child before it has a width of its own.
	# Without a floor the labels wrap one character per line, which makes the
	# content thousands of pixels tall and looks like clipped text.
	margin.custom_minimum_size.x = UI.viewport_size().x - 40
	scroll.add_child(margin)
	var text := UI.vbox(0)
	text.alignment = BoxContainer.ALIGNMENT_BEGIN
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.x = UI.viewport_size().x - 48
	margin.add_child(text)
	_build_text_column(text, true)

	# A paper fade at the fold plus a small cue. Without it the densest slides
	# look clipped rather than scrollable — the note is there, but nothing says so.
	var grad := Gradient.new()
	grad.set_color(0, Color(G.BG, 0.0))
	grad.set_color(1, Color(G.BG, 0.96))
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 8
	gtex.height = 64
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	scroll_fade = TextureRect.new()
	scroll_fade.texture = gtex
	scroll_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scroll_fade.stretch_mode = TextureRect.STRETCH_SCALE
	scroll_fade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	scroll_fade.offset_top = -30
	scroll_fade.offset_bottom = 0
	scroll_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(scroll_fade)
	scroll_cue = UI.tracked("SCROLL FOR MORE  ⌄", 8, Color(G.GOLD, 0.8), 2)
	scroll_cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_cue.custom_minimum_size.y = 14
	scroll_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(scroll_cue)
	scroll.get_v_scroll_bar().value_changed.connect(func(_v): _update_scroll_cue())
	holder.resized.connect(func(): _update_scroll_cue.call_deferred())
	_update_scroll_cue.call_deferred()


func _update_scroll_cue() -> void:
	if portrait_scroll == null or scroll_fade == null:
		return
	var bar := portrait_scroll.get_v_scroll_bar()
	var overflow := bar.max_value > bar.page + 2.0
	var at_end := bar.value >= bar.max_value - bar.page - 2.0
	var show := overflow and not at_end
	scroll_fade.visible = show
	if scroll_cue:
		scroll_cue.visible = show


func _build_text_column(parent: Control, scrollable: bool = false) -> void:
	var v := UI.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if scrollable else Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(v)

	kicker_lbl = UI.label("", 12, Color(G.TEAL, 0.95), "body_med")
	kicker_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	kicker_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(kicker_lbl)

	title_lbl = UI.label("", 54, G.GOLD, "display")
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_lbl.add_theme_constant_override("line_spacing", -2)
	if _portrait:
		title_lbl.custom_minimum_size.x = UI.viewport_size().x - 72
	v.add_child(title_lbl)

	subtitle_lbl = UI.label("", 17, Color(G.CREAM, 0.92))
	subtitle_lbl.add_theme_constant_override("line_spacing", 5)
	if _portrait:
		subtitle_lbl.custom_minimum_size.x = UI.viewport_size().x - 72
	v.add_child(subtitle_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)

	var rule := ColorRect.new()
	rule.color = Color(G.GOLD, 0.7)
	rule.custom_minimum_size = Vector2(56, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule)

	var gap := Control.new()
	gap.custom_minimum_size.y = 6
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)

	stats_box = HFlowContainer.new()
	stats_box.add_theme_constant_override("h_separation", 6)
	stats_box.add_theme_constant_override("v_separation", 6)
	stats_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_box.visible = false
	v.add_child(stats_box)

	bullets_box = UI.vbox(8)
	bullets_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bullets_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bullets_box)


func _build_visual_column(parent: Control) -> void:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _frame_style())
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(frame)

	var art: Control = ArtFrame.new()
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.clip_contents = true
	if _portrait:
		# On a phone the figure must not eat the note: cap it at 24% of the
		# screen and letterbox the plate inside the frame.
		art.max_height = UI.viewport_size().y * 0.24
		art.custom_minimum_size.y = art.max_height
	frame.add_child(art)
	image_art = art

	image_rect = TextureRect.new()
	image_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	image_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	image_rect.tooltip_text = "Click to enlarge this figure (I)"
	image_rect.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_show_figure())
	art.add_child(image_rect)

	var cap_row := UI.hbox(8)
	cap_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(cap_row)
	caption_lbl = UI.label("", 14, Color(G.CREAM, 0.9))
	caption_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _portrait:
		caption_lbl.custom_minimum_size.x = UI.viewport_size().x - 160
	caption_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_lbl.custom_minimum_size.y = 28
	cap_row.add_child(caption_lbl)

	fig_btn = UI.ghost_button("ENLARGE", 10)
	fig_btn.custom_minimum_size = Vector2(104, 38)
	fig_btn.add_theme_font_size_override("font_size", 10)
	fig_btn.tooltip_text = "Enlarge this figure (I)"
	fig_btn.pressed.connect(_show_figure)
	cap_row.add_child(fig_btn)


func _frame_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.055, 0.082, 0.145, 0.96)
	sb.border_color = Color(G.GOLD, 0.52)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 10)
	return sb


func _footer() -> Control:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 6)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	prev_btn = UI.ghost_button("‹  Back", 14)
	prev_btn.custom_minimum_size = Vector2(108, 46)
	prev_btn.add_theme_font_size_override("font_size", 14)
	prev_btn.pressed.connect(_prev)

	next_btn = UI.button("Next  ›", true, 16)
	next_btn.custom_minimum_size = Vector2(142, 46)
	next_btn.add_theme_font_size_override("font_size", 15)
	next_btn.pressed.connect(_next)

	lab_btn = UI.button("Open the exhibit  ›", false, 14)
	lab_btn.custom_minimum_size = Vector2(minf(250.0, UI.viewport_size().x * 0.28), 46)
	lab_btn.add_theme_font_size_override("font_size", 13)
	lab_btn.pressed.connect(_open_lab)

	var home := UI.ghost_button("Sky Lab", 13)
	home.custom_minimum_size = Vector2(96, 46)
	home.add_theme_font_size_override("font_size", 12)
	home.pressed.connect(_exit)
	home_btn = home

	if _compact:
		var nav := UI.hbox(8)
		nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(nav)
		prev_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(prev_btn)
		nav.add_child(next_btn)

		var actions := UI.hbox(8)
		actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(actions)
		lab_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(lab_btn)
		actions.add_child(home)

		var hint := UI.label("N notes  ·  A auto  ·  D checks", 9, Color(G.MUTED, 0.65))
		hint.autowrap_mode = TextServer.AUTOWRAP_OFF
		hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		wrap.add_child(hint)
		return wrap

	var row := UI.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(row)
	row.add_child(prev_btn)
	row.add_child(next_btn)
	row.add_child(UI.spacer())

	dots_box = HBoxContainer.new()
	dots_box.add_theme_constant_override("separation", 5)
	dots_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dots_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(dots_box)
	for i in slides.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(14, 14)
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "Slide %d" % (i + 1)
		var slide_i := i
		b.pressed.connect(func(): _go(slide_i, true))
		dots_box.add_child(b)
		dot_buttons.append(b)

	row.add_child(UI.spacer())
	row.add_child(lab_btn)
	row.add_child(home)
	return wrap


# ======================================================================
# Slide rendering
# ======================================================================

func _apply_slide() -> void:
	if slides.is_empty() or title_lbl == null:
		return
	var s: Dictionary = slides[index]

	kicker_lbl.text = str(s.get("kicker", ""))
	title_lbl.text = str(s.get("title", ""))
	title_lbl.add_theme_font_size_override("font_size", _title_size(str(s.get("title", ""))))
	subtitle_lbl.text = str(s.get("subtitle", ""))
	var short := UI.viewport_size().y < 520.0
	subtitle_lbl.add_theme_font_size_override("font_size", 13 if short else (15 if _compact else 18))

	for c in bullets_box.get_children():
		bullets_box.remove_child(c)
		c.queue_free()
	for b in s.get("bullets", []):
		bullets_box.add_child(_bullet_row(str(b)))
	if portrait_scroll:
		portrait_scroll.scroll_vertical = 0
	_update_scroll_cue.call_deferred()

	for c in stats_box.get_children():
		stats_box.remove_child(c)
		c.queue_free()
	var stats: Array = s.get("stats", [])
	stats_box.visible = not stats.is_empty()
	for st in stats:
		stats_box.add_child(UI.pill(str(st), G.TEAL, 14))

	var img := str(s.get("image", ""))
	if img != "" and ResourceLoader.exists(img):
		image_rect.texture = load(img)
		var tex := image_rect.texture
		if tex and image_art:
			image_art.ratio = float(tex.get_width()) / maxf(float(tex.get_height()), 1.0)
			image_art.update_minimum_size()
	else:
		image_rect.texture = null
	caption_lbl.text = str(s.get("caption", ""))

	var lab := str(s.get("lab", ""))
	lab_btn.visible = lab != "" and ResourceLoader.exists(lab)
	lab_btn.text = str(s.get("lab_label", "Open this exhibit"))
	if lab_btn.text == "":
		lab_btn.text = "Open this exhibit"
	if fig_btn:
		fig_btn.visible = image_rect.texture != null
	if home_btn:
		home_btn.visible = not lab_btn.visible
	if prev_btn:
		prev_btn.disabled = index == 0
	if next_btn:
		next_btn.disabled = index >= slides.size() - 1
		next_btn.text = "End" if index >= slides.size() - 1 else "Next  ›"

	counter_lbl.text = "%02d / %02d" % [index + 1, slides.size()]
	if notes_time:
		notes_time.text = "~%d SEC" % int(s.get("seconds", DEFAULT_SECONDS))
	if notes_visible and notes_text:
		notes_text.text = str(s.get("note", ""))
	if cue_visible and cue_text:
		cue_text.text = _cue_line(str(s.get("note", "")))

	auto_left = float(s.get("seconds", DEFAULT_SECONDS))
	auto_total = auto_left
	_apply_sky_mode(str(s.get("sky", "stars")))
	_update_dots()
	_update_auto_label()

	if content_root:
		content_root.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(content_root, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_SINE)


func _bullet_row(text: String) -> Control:
	var h := UI.hbox(9)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := UI.label("•", 22, Color(G.GOLD, 1.0), "body_med")
	dot.autowrap_mode = TextServer.AUTOWRAP_OFF
	dot.custom_minimum_size = Vector2(12, 0)
	dot.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(dot)
	var body := UI.label(text, 14 if UI.viewport_size().y < 520.0 else (15 if _compact else 18), Color(G.CREAM, 0.93))
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _portrait:
		body.custom_minimum_size.x = UI.viewport_size().x - 84
	body.add_theme_constant_override("line_spacing", 4)
	h.add_child(body)
	return h


func _title_size(text: String) -> int:
	var size := 54
	if _compact:
		size = 36
	if UI.viewport_size().y < 520.0:
		size = 28
	if _portrait:
		size = 31
	if text.length() > 46:
		size -= 5
	if text.length() > 62:
		size -= 5
	if text.length() > 78:
		size -= 4
	return clampi(size, 24, 58)


func _update_dots() -> void:
	for i in dot_buttons.size():
		var b := dot_buttons[i]
		var active := i == index
		var done := i < index
		var sb := StyleBoxFlat.new()
		sb.bg_color = G.GOLD if active else (Color(G.GOLD, 0.55) if done else Color(G.GOLD, 0.18))
		sb.border_color = Color(G.GOLD, 0.8) if active else Color(G.GOLD, 0.25)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(7)
		var hover := sb.duplicate() as StyleBoxFlat
		hover.bg_color = Color(G.GOLD, 0.75)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", hover)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _update_auto_label() -> void:
	if auto_btn:
		auto_btn.text = "Auto: on  A" if auto_play else "Auto  A"
	if auto_track:
		auto_track.modulate.a = 1.0 if auto_play else 0.0


func _go(target: int, manual: bool = true) -> void:
	_close_figure()
	var next_index := clampi(target, 0, maxi(slides.size() - 1, 0))
	if manual:
		auto_play = false
		_update_auto_label()
	index = next_index
	G.seminar_index = index
	G.save_game()
	_apply_slide()
	if auto_play and index >= slides.size() - 1:
		auto_play = false
		_update_auto_label()


func _next() -> void:
	Sfx.play("click")
	if index >= slides.size() - 1:
		# The closing slide is the frame to leave on; a clicker press should
		# not paint a toast across it.
		return
	_go(index + 1, true)


func _prev() -> void:
	Sfx.play("click")
	if index <= 0:
		return
	_go(index - 1, true)


func _open_lab() -> void:
	if slides.is_empty():
		return
	var s: Dictionary = slides[index]
	var path := str(s.get("lab", ""))
	if path != "" and ResourceLoader.exists(path):
		Sfx.play("lantern")
		G.seminar_elapsed = elapsed
		G.seminar_return = true
		G.save_game()
		G.refresh_content_scale()
		Router.go(path)
	else:
		_toast("No live exhibit is attached to this slide.")


func _exit() -> void:
	Sfx.play("click")
	G.seminar_elapsed = elapsed
	G.seminar_return = false
	G.save_game()
	G.refresh_content_scale()
	Router.go(LAB_PATH)


func _show_figure() -> void:
	if _figure_overlay:
		_close_figure()
		return
	if image_rect == null or image_rect.texture == null:
		return
	Sfx.play("click")
	var vp := UI.viewport_size()
	var overlay := _dim_overlay()
	_figure_overlay = overlay
	var dim := overlay.get_child(0) as ColorRect
	if dim:
		dim.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				_close_figure())

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 20
	center.offset_right = -20
	center.offset_top = 16
	center.offset_bottom = -16
	overlay.add_child(center)

	var panel := UI.panel(10, 0.98)
	panel.custom_minimum_size = Vector2(minf(vp.x - 50, 1180), 0)
	center.add_child(panel)
	var v := UI.vbox(6)
	panel.add_child(v)

	var head := UI.hbox(10)
	v.add_child(head)
	var cap := UI.label(str(slides[index].get("caption", "")) if not slides.is_empty() else "", 12, Color(G.CREAM, 0.85))
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cap)
	var close := UI.ghost_button("×  Close", 12)
	close.custom_minimum_size = Vector2(90, 34)
	close.pressed.connect(_close_figure)
	head.add_child(close)

	var tex := TextureRect.new()
	tex.texture = image_rect.texture
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.custom_minimum_size = Vector2(minf(vp.x - 90, 1120), minf(vp.y - 170, 660))
	tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tex)

	var hint := UI.label("Click the background, press I or Esc to close.", 10, Color(G.MUTED, 0.8))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	UI.fade_in(overlay, 0.0, 0.18)


func _close_figure() -> void:
	if _figure_overlay:
		_figure_overlay.queue_free()
		_figure_overlay = null


# ======================================================================
# Presenter tools
# ======================================================================

func _toggle_notes() -> void:
	if notes_visible:
		notes_visible = false
		_hide_notes()
	elif cue_visible:
		_hide_cue()
	else:
		_show_cue()
	Sfx.play("click")


func _show_cue() -> void:
	# A projected script is a credibility risk. N shows one sentence; Shift+N
	# opens the full notes for rehearsal on your own screen.
	if cue_panel or notes_visible or slides.is_empty():
		return
	var s: Dictionary = slides[index]
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.035, 0.07, 0.96)
	sb.border_color = Color(G.GOLD, 0.35)
	sb.set_border_width_all(1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if _portrait:
		# On a phone the bottom bar is already crowded; put the cue under the
		# header so it covers the figure, never the note or the scroll cue.
		panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		panel.offset_left = UI.pad()
		panel.offset_right = -UI.pad()
		panel.offset_top = 52
		panel.offset_bottom = 108
	else:
		panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		panel.offset_left = UI.pad()
		panel.offset_right = -UI.pad()
		panel.offset_bottom = -78
		panel.offset_top = panel.offset_bottom - 52
	ui.add_child(panel)
	cue_panel = panel
	var h := UI.hbox(8)
	panel.add_child(h)
	var tag := UI.micro("CUE", Color(G.GOLD, 0.9), 8)
	tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(tag)
	cue_text = UI.label(_cue_line(str(s.get("note", ""))), 13, Color(G.CREAM, 0.94))
	cue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cue_text.max_lines_visible = 2
	cue_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(cue_text)
	var full := UI.ghost_button("Full", 10)
	full.custom_minimum_size = Vector2(58, 30)
	full.pressed.connect(func(): _hide_cue(); _show_notes())
	h.add_child(full)
	cue_visible = true


func _hide_cue() -> void:
	if cue_panel:
		cue_panel.queue_free()
		cue_panel = null
		cue_text = null
	cue_visible = false


func _cue_line(note: String) -> String:
	var cut := note.find(". ")
	if cut > 0:
		return note.left(cut + 1)
	return note


func _show_notes() -> void:
	if _notes_panel:
		return
	if slides.is_empty():
		return
	if cue_visible:
		_hide_cue()
	notes_visible = true
	var s: Dictionary = slides[index]
	var vp := UI.viewport_size()
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.035, 0.07, 0.97)
	sb.border_color = Color(G.GOLD, 0.35)
	sb.border_width_left = 2
	sb.set_border_width_all(1)
	sb.border_width_left = 2
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 16
	panel.add_theme_stylebox_override("panel", sb)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = UI.pad()
	panel.offset_right = -UI.pad()
	panel.offset_bottom = -78 if not _portrait else -112
	panel.offset_top = panel.offset_bottom - (148 if not _portrait else 190)
	ui.add_child(panel)
	_notes_panel = panel

	var v := UI.vbox(5)
	panel.add_child(v)
	var head := UI.hbox(8)
	v.add_child(head)
	var label := UI.micro("SPEAKER NOTES", Color(G.GOLD, 0.9), 8)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(label)
	notes_time = UI.label("~%d SEC" % int(s.get("seconds", DEFAULT_SECONDS)), 10, Color(G.MUTED, 0.8), "body_med")
	notes_time.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(notes_time)
	head.add_child(UI.spacer())
	var close := UI.ghost_button("×", 15)
	close.custom_minimum_size = Vector2(38, 30)
	close.pressed.connect(_toggle_notes)
	head.add_child(close)

	var scroll := UI.scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(scroll)
	notes_text = UI.label(str(s.get("note", "")), 14, Color(G.CREAM, 0.92))
	notes_text.add_theme_constant_override("line_spacing", 4)
	notes_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(notes_text)


func _hide_notes() -> void:
	notes_visible = false
	if _notes_panel:
		_notes_panel.queue_free()
		_notes_panel = null
		notes_text = null
		notes_time = null


func _toggle_auto() -> void:
	auto_play = not auto_play
	if auto_play:
		auto_left = float(slides[index].get("seconds", DEFAULT_SECONDS)) if not slides.is_empty() else DEFAULT_SECONDS
		auto_total = auto_left
	Sfx.play("click")
	_update_auto_label()


func _show_controls() -> void:
	var overlay := _dim_overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := UI.panel(18, 0.98)
	panel.custom_minimum_size = Vector2(minf(330.0, UI.viewport_size().x - 36.0), 0)
	center.add_child(panel)
	var v := UI.vbox(8)
	panel.add_child(v)
	v.add_child(UI.heading("Presenter menu", 26))
	v.add_child(UI.divider())
	var items := [
		["Speaker notes", func(): _toggle_notes()],
		["Auto-play", func(): _toggle_auto()],
		["Checks & shortcuts", func(): _open_checks()],
		["Fullscreen", func(): _toggle_fullscreen()],
		["Sky Lab", func(): _exit()],
	]
	for item in items:
		var b := UI.button(str(item[0]), false, 15)
		var action: Callable = item[1]
		b.pressed.connect(func():
			overlay.queue_free()
			action.call())
		v.add_child(b)
	var close := UI.ghost_button("Close", 14)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)


func _toggle_fullscreen() -> void:
	Sfx.play("click")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
			"(function(){if(document.fullscreenElement){document.exitFullscreen();}else{document.documentElement.requestFullscreen();}})();",
			true)
	else:
		var mode := DisplayServer.window_get_mode()
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _open_checks() -> void:
	if _checking:
		return
	_checking = true
	Sfx.play("click")
	_checks_overlay = _dim_overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	center.offset_top = 14
	center.offset_bottom = -14
	_checks_overlay.add_child(center)

	var panel := UI.panel(18, 0.98)
	panel.custom_minimum_size = Vector2(minf(760.0, UI.viewport_size().x - 28.0), 0)
	center.add_child(panel)
	var v := UI.vbox(8)
	panel.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	var hv := UI.vbox(2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UI.micro("PRESENTER CHECKS", Color(G.GOLD, 0.9), 8))
	hv.add_child(UI.heading("Everything the demo needs", 26))
	var x := UI.ghost_button("×", 16)
	x.custom_minimum_size = Vector2(44, 40)
	x.pressed.connect(_close_checks)
	head.add_child(x)
	v.add_child(UI.label("Green means ready. If a row is red, fix it before the talk.", 12, G.MUTED))
	v.add_child(UI.divider())

	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.52, 390.0))
	v.add_child(scroll)
	var rows_box := UI.vbox(4)
	rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows_box)
	for row in preflight_results():
		rows_box.add_child(_check_row(row))

	v.add_child(UI.divider())
	v.add_child(UI.micro("KEYBOARD", Color(G.GOLD, 0.9), 8))
	var keys := UI.rich(
		"[b]› / Space[/b]  next      [b]←[/b]  back      [b]Home / End[/b]  first / last\n" +
		"[b]N[/b]  notes      [b]A[/b]  auto-play      [b]D[/b]  checks      [b]F[/b]  fullscreen\n" +
		"[b]L[/b]  open this exhibit      [b]P[/b]  pause timer      [b]Esc[/b]  back to the Sky Lab",
		12, G.CREAM)
	v.add_child(keys)

	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	v.add_child(actions)
	var unlock := UI.ghost_button("Set demo state", 12)
	unlock.tooltip_text = "Mark all seven lanterns complete and set the quiz best to 14."
	unlock.pressed.connect(_unlock_demo)
	actions.add_child(unlock)
	var finale := UI.ghost_button("Open the finale", 12)
	finale.pressed.connect(func():
		_close_checks()
		G.refresh_content_scale()
		Router.go("res://scenes/Finale.tscn"))
	actions.add_child(finale)
	var reset := UI.ghost_button("Reset progress", 12)
	reset.pressed.connect(_confirm_reset)
	actions.add_child(reset)
	var close := UI.button("Close", true, 14)
	close.custom_minimum_size = Vector2(110, 42)
	close.pressed.connect(_close_checks)
	actions.add_child(close)


func _check_row(row: Dictionary) -> Control:
	var h := UI.hbox(8)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ok := bool(row.get("ok", true))
	var mark := UI.label("OK" if ok else "!", 13, G.TEAL if ok else G.ROSE, "body_med")
	mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	mark.custom_minimum_size.x = 16
	h.add_child(mark)
	var name := UI.label(str(row.get("label", "")), 13, Color(G.CREAM, 0.92))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name)
	var value := UI.label(str(row.get("value", "")), 12, G.TEAL if ok else G.ROSE, "body_med")
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(value)
	return h


func preflight_results() -> Array:
	var rows: Array = []
	rows.append(_row("Star catalogue", "%s stars" % _num(StarDB.hips.size()), StarDB.hips.size() == 8879))
	rows.append(_row("Constellations", "%d IAU figures" % StarDB.constellations.size(), StarDB.constellations.size() == 88))
	rows.append(_row("Nakshatras", "%d figures" % StarDB.nakshatras.size(), StarDB.nakshatras.size() == 28))
	rows.append(_row("Lessons", "%d modules" % G.MODULES.size(), G.MODULES.size() == 7))

	var copy_ok := true
	for s in slides:
		if (s.get("stats", []) as Array).is_empty():
			copy_ok = false
		for b in s.get("bullets", []):
			if str(b).length() > 120:
				copy_ok = false
	rows.append(_row("Deck copy", "stats + short bullets", copy_ok))

	var image_ok := 0
	for s in slides:
		var img := str(s.get("image", ""))
		if img != "" and ResourceLoader.exists(img):
			image_ok += 1
	rows.append(_row("Slide images", "%d / %d" % [image_ok, slides.size()], image_ok == slides.size()))

	var labs: Dictionary = {}
	for s in slides:
		var lab := str(s.get("lab", ""))
		if lab != "":
			labs[lab] = true
	labs["res://scenes/Atlas.tscn"] = true
	labs["res://scenes/Finale.tscn"] = true
	var labs_ok := 0
	for path in labs.keys():
		if ResourceLoader.exists(str(path)):
			labs_ok += 1
	rows.append(_row("Live scenes", "%d / %d" % [labs_ok, labs.size()], labs_ok == labs.size()))

	var font_paths := [UI.FONT_DISPLAY_PATH, UI.FONT_SERIF_PATH, UI.FONT_BODY_PATH, UI.FONT_BODY_MED_PATH, UI.FONT_KANNADA_PATH]
	var fonts_ok := 0
	for path in font_paths:
		if ResourceLoader.exists(path):
			fonts_ok += 1
	rows.append(_row("Fonts", "%d / %d" % [fonts_ok, font_paths.size()], fonts_ok == font_paths.size()))

	var audio := ["click", "chime", "success", "soft_error", "lantern", "whoosh", "ambient"]
	var audio_ok := 0
	for name in audio:
		var path := "res://audio/%s.%s" % [name, "ogg" if name == "ambient" else "wav"]
		if ResourceLoader.exists(path):
			audio_ok += 1
	rows.append(_row("Audio cues", "%d / %d" % [audio_ok, audio.size()], audio_ok == audio.size()))

	var renderer := "Web · GL Compatibility"
	if not OS.has_feature("web"):
		renderer = str(RenderingServer.get_video_adapter_name())
		if renderer.strip_edges() == "":
			renderer = "OpenGL 3 · Compatibility"
	rows.append(_row("Renderer", renderer, true))

	var vp := UI.viewport_size()
	rows.append(_row("Viewport", "%d × %d" % [int(vp.x), int(vp.y)], vp.x >= 320 and vp.y >= 320))
	rows.append(_row("Save", "Local only · user://", true))
	rows.append(_row("Network", "No runtime calls", true))
	return rows


func _row(label: String, value: String, ok: bool) -> Dictionary:
	return {"label": label, "value": value, "ok": ok}


func _unlock_demo() -> void:
	G.unlock_all()
	Sfx.play("chime")
	_toast("Demo state ready — all seven lanterns lit, finale unlocked.")


func _confirm_reset() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Reset progress?"
	dlg.dialog_text = "Clear every lantern, quiz score and saved setting on this device?"
	dlg.ok_button_text = "Reset"
	dlg.cancel_button_text = "Keep"
	dlg.confirmed.connect(func():
		G.reset_progress()
		Sfx.play("whoosh")
		_toast("Progress cleared."))
	ui.add_child(dlg)
	dlg.popup_centered()


func _close_checks() -> void:
	if _checks_overlay:
		_checks_overlay.queue_free()
		_checks_overlay = null
	_checking = false


func _dim_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.006, 0.012, 0.03, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)
	return overlay


func _toast(message: String) -> void:
	_toast_seq += 1
	var seq := _toast_seq
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	center.offset_top = -162
	center.offset_bottom = -104
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center)
	var panel := UI.panel(12, 0.96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(panel)
	var label := UI.label(message, 12, G.CREAM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	center.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(center, "modulate:a", 1.0, 0.18)
	await get_tree().create_timer(2.6).timeout
	if seq != _toast_seq:
		return
	if not is_instance_valid(center):
		return
	var tw2 := create_tween()
	tw2.tween_property(center, "modulate:a", 0.0, 0.3)
	await tw2.finished
	center.queue_free()


# ======================================================================
# Process, input, resize
# ======================================================================

func _process(delta: float) -> void:
	if timer_running:
		elapsed += delta
		_save_acc += delta
		if _save_acc >= 5.0:
			_save_acc = 0.0
			G.seminar_elapsed = elapsed
			G.save_game()
	if timer_lbl:
		timer_lbl.text = "TIME " + _clock(elapsed)
		timer_lbl.add_theme_color_override("font_color", G.VERMILION if elapsed > 510.0 else Color(G.MUTED, 1.0))

	if sky and not G.reduced_motion:
		sky.set_sidereal(sky.sidereal_deg + delta * 0.22)

	for i in _lanterns.size():
		var n := _lanterns[i]
		n.position.y += _lantern_speeds[i] * delta
		if n.position.y > 26.0:
			n.position.y = 2.0
			n.position.x = randf_range(-32.0, 32.0)

	if auto_play and not slides.is_empty():
		auto_left -= delta
		if auto_fill:
			var t: float = clampf(1.0 - auto_left / maxf(auto_total, 0.01), 0.0, 1.0)
			auto_fill.anchor_right = t
		if auto_left <= 0.0:
			if index < slides.size() - 1:
				index += 1
				_apply_slide()
			else:
				auto_play = false
				_update_auto_label()
				_toast("End of the deck.")


func _clock(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	match key.keycode:
		KEY_RIGHT, KEY_SPACE, KEY_PAGEDOWN:
			_next()
		KEY_LEFT, KEY_PAGEUP:
			_prev()
		KEY_HOME:
			elapsed = 0.0
			G.seminar_elapsed = 0.0
			_go(0, true)
		KEY_END:
			_go(slides.size() - 1, true)
		KEY_A:
			_toggle_auto()
		KEY_N:
			if key.shift_pressed:
				if cue_visible:
					_hide_cue()
				_show_notes()
			else:
				_toggle_notes()
		KEY_D:
			_open_checks()
		KEY_F:
			_toggle_fullscreen()
		KEY_L:
			_open_lab()
		KEY_I:
			_show_figure()
		KEY_P:
			timer_running = not timer_running
			_toast("Timer %s." % ("running" if timer_running else "paused"))
		KEY_ESCAPE:
			if _figure_overlay:
				_close_figure()
				return
			if _checks_overlay:
				_close_checks()
				return
			if OS.has_feature("web") and bool(JavaScriptBridge.eval("!!document.fullscreenElement", true)):
				return
			if index >= slides.size() - 1:
				G.seminar_elapsed = elapsed
				G.seminar_return = false
				G.save_game()
				G.refresh_content_scale()
				Router.go("res://scenes/Boot.tscn")
				return
			_exit()


func _on_resize() -> void:
	var css_portrait := UI.is_portrait()
	if not css_portrait:
		_set_deck_canvas()
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_build_ui()
		_apply_slide()


func _set_deck_canvas() -> void:
	# A presentation should keep its 16:9 stage at every window size. The game
	# scenes are responsive; the deck is a slide, so scale the whole 1280×720
	# canvas instead of reflowing a 780px window into a cramped layout.
	var root := get_tree().root
	if root.content_scale_size != Vector2i(1280, 720) or root.content_scale_aspect != Window.CONTENT_SCALE_ASPECT_KEEP:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = Vector2i(1280, 720)

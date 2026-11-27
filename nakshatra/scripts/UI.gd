class_name UI
extends RefCounted
## The Nakshatra visual language: a printed sky almanac.
## Ink-dark ground, paper cream, leaf gold hairlines, one vermilion accent.
## All type is Cormorant Garamond (display) + Noto Sans (text); the UI is
## built from rules and plates, not glowing pills.

const FONT_DISPLAY_PATH := "res://assets/fonts/CormorantGaramond-Variable.ttf"
const FONT_SERIF_PATH := "res://assets/fonts/NotoSerif-Bold.ttf"
const FONT_BODY_PATH := "res://assets/fonts/NotoSans-Regular.ttf"
const FONT_BODY_MED_PATH := "res://assets/fonts/NotoSans-Medium.ttf"
const FONT_KANNADA_PATH := "res://assets/fonts/NotoSansKannada-Regular.ttf"
const GRAIN_PATH := "res://assets/fx/grain.png"

static var _theme: Theme
static var _display: Font
static var _serif: Font
static var _body: Font
static var _body_med: Font
static var _kannada: Font
static var _grabber: Texture2D


static func _load_font(path: String) -> Font:
	if not ResourceLoader.exists(path):
		return ThemeDB.fallback_font
	var f := load(path) as Font
	if f is FontFile:
		var ff := f as FontFile
		ff.multichannel_signed_distance_field = false
		ff.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		if path != FONT_KANNADA_PATH:
			ff.fallbacks = [kannada_font()]
	return f


static func _variant(base: Font, weight: int, tracking: int = 0) -> Font:
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	fv.spacing_glyph = tracking
	return fv


static func display_font() -> Font:
	if _display == null:
		_display = _variant(_load_font(FONT_DISPLAY_PATH), 500)
	return _display


static func serif_font() -> Font:
	if _serif == null:
		_serif = _variant(_load_font(FONT_DISPLAY_PATH), 600)
	return _serif


static func body_font() -> Font:
	if _body == null:
		_body = _load_font(FONT_BODY_PATH)
	return _body


static func body_med_font() -> Font:
	if _body_med == null:
		_body_med = _load_font(FONT_BODY_MED_PATH)
	return _body_med


static func kannada_font() -> Font:
	if _kannada == null:
		_kannada = _load_font(FONT_KANNADA_PATH)
	return _kannada


static func tracked_font(size_kind: String, tracking: int) -> Font:
	match size_kind:
		"serif":
			return _variant(serif_font(), 600, tracking)
		"display":
			return _variant(display_font(), 500, tracking)
		_:
			return _variant(body_med_font(), 500, tracking)


static func _grabber_texture() -> Texture2D:
	if _grabber:
		return _grabber
	var img := Image.create(18, 18, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 18:
		for x in 18:
			var d := Vector2(x - 8.5, y - 8.5).length()
			if d <= 5.0:
				img.set_pixel(x, y, G.GOLD)
			elif d <= 6.4:
				img.set_pixel(x, y, Color(G.GOLD, 0.35))
	_grabber = ImageTexture.create_from_image(img)
	return _grabber


static func theme() -> Theme:
	if _theme:
		return _theme
	var th := Theme.new()
	th.default_font = body_font()
	th.default_font_size = 17
	th.set_color("font_color", "Label", G.CREAM)
	th.set_color("font_color", "RichTextLabel", G.CREAM)
	th.set_color("default_color", "RichTextLabel", G.CREAM)
	th.set_constant("line_spacing", "Label", 5)
	th.set_constant("line_spacing", "RichTextLabel", 5)
	th.set_font("font", "Label", body_font())

	# Slider: a hairline track with a small gold bead.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(G.GOLD, 0.22)
	track.set_corner_radius_all(1)
	track.content_margin_top = 1
	track.content_margin_bottom = 1
	th.set_stylebox("slider", "HSlider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(G.GOLD, 0.55)
	fill.set_corner_radius_all(1)
	fill.content_margin_top = 1
	fill.content_margin_bottom = 1
	th.set_stylebox("grabber_area", "HSlider", fill)
	th.set_stylebox("grabber_area_highlight", "HSlider", fill)
	th.set_icon("grabber", "HSlider", _grabber_texture())
	th.set_icon("grabber_highlight", "HSlider", _grabber_texture())
	th.set_icon("grabber_disabled", "HSlider", _grabber_texture())

	# Scrollbars: thin, quiet, printed.
	for bar in ["VScrollBar", "HScrollBar"]:
		var a := StyleBoxFlat.new()
		a.bg_color = Color(G.CREAM, 0.04)
		a.content_margin_left = 2
		a.content_margin_right = 2
		th.set_stylebox("scroll", bar, a)
		var b := StyleBoxFlat.new()
		b.bg_color = Color(G.GOLD, 0.28)
		b.set_corner_radius_all(2)
		th.set_stylebox("grabber", bar, b)
		var c := StyleBoxFlat.new()
		c.bg_color = Color(G.GOLD, 0.5)
		c.set_corner_radius_all(2)
		th.set_stylebox("grabber_highlight", bar, c)
		th.set_stylebox("grabber_pressed", bar, c)
		th.set_constant("minimum_grabber_size", bar, 28)
	_theme = th
	return th


static func viewport_size() -> Vector2:
	var loop := Engine.get_main_loop() as SceneTree
	if loop and loop.root:
		return loop.root.get_visible_rect().size
	return Vector2(1280, 720)


static func is_portrait() -> bool:
	var s := viewport_size()
	return s.y > s.x


static func is_compact() -> bool:
	var s := viewport_size()
	return s.x < 780.0 or s.y < 560.0


static func pad() -> int:
	var s := viewport_size()
	if s.x < 780.0:
		return 18
	return 34


static func vbox(sep: int = 10) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b


static func hbox(sep: int = 12) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	return b


static func spacer(expand_h: bool = true, expand_v: bool = false) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand_h:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand_v:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func label(text: String, size: int = 18, color: Color = G.CREAM, font_kind: String = "body") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	match font_kind:
		"display":
			l.add_theme_font_override("font", display_font())
		"serif":
			l.add_theme_font_override("font", serif_font())
		"body_med":
			l.add_theme_font_override("font", body_med_font())
		"kannada":
			l.add_theme_font_override("font", kannada_font())
			l.add_theme_constant_override("line_spacing", 4)
			l.custom_minimum_size.y = int(float(size) * 1.6)
		_:
			l.add_theme_font_override("font", body_font())
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func micro(text: String, color: Color = G.GOLD, size: int = 11) -> Label:
	var l := label(text.to_upper(), size, color, "body_med")
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_override("font", tracked_font("body", 2))
	return l


static func tracked(text: String, size: int, color: Color, tracking: int) -> Label:
	var l := label(text, size, color, "body")
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.add_theme_font_override("font", tracked_font("body", tracking))
	return l


static func rich(text: String, size: int = 18, color: Color = G.CREAM) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = text
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_font_override("normal_font", body_font())
	r.add_theme_font_override("bold_font", body_med_font())
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func heading(text: String, size: int = 40, color: Color = G.CREAM) -> Label:
	var l := label(text, size, color, "serif")
	l.add_theme_constant_override("line_spacing", 0)
	return l


static func display(text: String, size: int = 64, color: Color = G.CREAM) -> Label:
	var l := label(text, size, color, "display")
	l.add_theme_constant_override("line_spacing", -2)
	return l


static func rule(color: Color = Color(G.GOLD, 0.24), height: int = 1) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, height)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func divider() -> ColorRect:
	return rule()


static func panel(pad: int = 20, alpha: float = 0.9) -> PanelContainer:
	if _theme == null:
		theme()
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.031, 0.047, 0.078, alpha)
	sb.border_color = Color(0.851, 0.702, 0.424, 0.16)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 8)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


static func paper(pad: int = 22) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = G.PAPER
	sb.border_color = Color(0.322, 0.231, 0.11, 0.35)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 12)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


static func plate_bg(alpha: float = 0.92) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.052, 0.085, alpha)
	sb.border_color = Color(0.851, 0.702, 0.424, 0.2)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	return sb


static func focus_ring() -> StyleBoxFlat:
	## A visible keyboard focus ring. Buttons used to opt out of focus entirely,
	## which made the whole game unreachable with Tab on a laptop.
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_color = Color(1.0, 0.86, 0.55, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	return sb


static func button(text: String, primary: bool = false, size: int = 19) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", maxi(12, size - 5))
	b.add_theme_font_override("font", tracked_font("body", 1))
	b.custom_minimum_size = Vector2(0, 46)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal := StyleBoxFlat.new()
	normal.bg_color = G.CREAM if primary else Color(0.043, 0.062, 0.098, 0.72)
	normal.border_color = G.CREAM if primary else Color(G.GOLD, 0.26)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 22
	normal.content_margin_right = 22
	normal.content_margin_top = 11
	normal.content_margin_bottom = 11

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("ffffff") if primary else Color(0.075, 0.105, 0.16, 0.9)
	hover.border_color = G.CREAM if primary else Color(G.GOLD, 0.6)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("e6d8be") if primary else Color(0.028, 0.042, 0.07, 0.95)
	pressed.border_color = G.CREAM if primary else Color(G.GOLD, 0.4)

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.06, 0.075, 0.1, 0.6)
	disabled.border_color = Color(1, 1, 1, 0.08)

	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("disabled", disabled)
	b.add_theme_stylebox_override("focus", focus_ring())
	b.add_theme_color_override("font_color", G.INK if primary else G.CREAM)
	b.add_theme_color_override("font_hover_color", G.INK if primary else Color.WHITE)
	b.add_theme_color_override("font_pressed_color", G.INK if primary else G.GOLD)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	return b


static func ink_button(text: String, primary: bool = true, size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", maxi(11, size - 4))
	b.add_theme_font_override("font", tracked_font("body", 1))
	b.custom_minimum_size = Vector2(0, 44)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = G.INK if primary else Color(1, 1, 1, 0.25)
	normal.border_color = G.INK if primary else Color(G.INK, 0.4)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("26314a") if primary else Color(1, 1, 1, 0.55)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("090d16") if primary else Color(1, 1, 1, 0.15)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus_ring())
	b.add_theme_color_override("font_color", G.PAPER if primary else G.INK)
	b.add_theme_color_override("font_hover_color", Color.WHITE if primary else G.INK)
	b.add_theme_color_override("font_pressed_color", G.GOLD if primary else G.INK)
	return b


static func ghost_button(text: String, size: int = 17) -> Button:
	var b := button(text, false, size)
	b.custom_minimum_size = Vector2(0, 44 if is_compact() else 38)
	b.add_theme_font_size_override("font_size", maxi(11, size - 5))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.032, 0.058, 0.25)
	sb.border_color = Color(G.GOLD, 0.14)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 7
	sb.content_margin_bottom = 7
	var hover := sb.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.06, 0.09, 0.14, 0.6)
	hover.border_color = Color(G.GOLD, 0.45)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", focus_ring())
	return b


static func link_button(text: String, size: int = 11, color: Color = G.CREAM) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_font_override("font", tracked_font("body", 1))
	b.add_theme_color_override("font_color", Color(color, 0.82))
	b.add_theme_color_override("font_hover_color", G.GOLD)
	b.add_theme_color_override("font_pressed_color", G.GOLD)
	b.custom_minimum_size = Vector2(44, 44) if is_compact() else Vector2(0, 30)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("hover", empty)
	b.add_theme_stylebox_override("pressed", empty)
	b.add_theme_stylebox_override("focus", focus_ring())
	return b


static func back_button() -> Button:
	var b := ghost_button("‹", 20)
	b.custom_minimum_size = Vector2(40, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return b


static func pill(text: String, color: Color = G.TEAL, size: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.08)
	sb.border_color = Color(color, 0.32)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	var pl := micro(text, color, maxi(9, size - 3))
	pl.autowrap_mode = TextServer.AUTOWRAP_OFF
	p.add_child(pl)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func kstars(n: int, total: int = 5, size: int = 18) -> HBoxContainer:
	var h := hbox(3)
	for i in total:
		var p := StarPip.new()
		p.setup(i < n, G.GOLD if i < n else Color(G.GOLD, 0.5), float(size))
		h.add_child(p)
	return h


static func pip_row(states: Array, size: float = 13.0, current_color: Color = G.VERMILION) -> HBoxContainer:
	var h := hbox(5)
	for st in states:
		var p := StarPip.new()
		var v := int(st)
		var col := G.GOLD if v == 2 else (current_color if v == 1 else Color(G.GOLD, 0.5))
		p.setup(v > 0, col, size)
		h.add_child(p)
	return h


## Seven small diamonds that read as lanterns being lit.
static func progress_pips(done: int, total: int = 7, px: float = 9.0) -> HBoxContainer:
	var h := hbox(5)
	for i in total:
		var p := ProgressPip.new()
		p.setup(i < done, i == done, G.GOLD, px)
		h.add_child(p)
	return h


static func brand_mark(px: float = 26.0) -> Control:
	var m := BrandMark.new()
	m.custom_minimum_size = Vector2(px, px)
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return m


static func app_bar(title: String, subtitle: String = "", back_route: String = "res://scenes/Lab.tscn", actions: Array = [], progress: Vector2i = Vector2i(-1, -1), back_label: String = "The Sky Lab", status: Label = null) -> Control:
	var compact := UI.is_compact()
	var wrap := vbox(9)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := hbox(14)
	wrap.add_child(row)

	var back := link_button("‹" + ("   " + back_label if back_label != "" and not compact else ("  LAB" if compact else "")), 11)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size = Vector2(56, 44) if compact else Vector2(0, 32)
	if back_route != "":
		back.pressed.connect(func():
			Sfx.play("click")
			Router.go(back_route))
	row.add_child(back)

	var sep := ColorRect.new()
	sep.color = Color(G.GOLD, 0.22)
	sep.custom_minimum_size = Vector2(1, 26)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(sep)

	var tv := vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(tv)
	var t := heading(title, 22 if compact else 24)
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tv.add_child(t)
	if subtitle != "" and not compact:
		tv.add_child(micro(subtitle, Color(G.MUTED, 0.95), 9))

	if progress.x >= 0:
		var pv := hbox(6)
		pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var pv_wrap := PanelContainer.new()
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.012, 0.022, 0.042, 0.62)
		psb.border_color = Color(G.GOLD, 0.18)
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(2)
		psb.content_margin_left = 7
		psb.content_margin_right = 7
		psb.content_margin_top = 3
		psb.content_margin_bottom = 3
		pv_wrap.add_theme_stylebox_override("panel", psb)
		pv_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pv_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv_wrap.add_child(pv)
		row.add_child(pv_wrap)
		var pips := hbox(4)
		pips.add_theme_constant_override("separation", 4)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if not compact:
			for i in progress.y:
				var pip := ProgressPip.new()
				pip.setup(i < progress.x, i == progress.x, G.GOLD, 8.0)
				pips.add_child(pip)
			pv.add_child(pips)
		var pl := micro("%d/%d" % [progress.x, progress.y], Color(G.GOLD, 0.9), 8)
		pl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pv.add_child(pl)

	if status != null and not compact:
		status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(status)

	# When a slide opens a live exhibit, the walk back must be one key, not a
	# trip through the hub. Backspace does the same from anywhere in a lab.
	if G.seminar_return:
		var deck := link_button("PRESENT  ·  DECK", 11)
		deck.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		deck.custom_minimum_size = Vector2(44 if compact else 0, 44 if compact else 32)
		deck.add_theme_color_override("font_color", G.GOLD)
		deck.pressed.connect(func(): Router.go("res://scenes/Seminar.tscn"))
		row.add_child(deck)

	for a in actions:
		var d: Dictionary = a
		var b := link_button(str(d.get("text", "")), 11)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.custom_minimum_size = Vector2(0, 32)
		if d.has("fn"):
			b.pressed.connect(d["fn"])
		row.add_child(b)

	wrap.add_child(rule(Color(G.GOLD, 0.2), 1))
	return wrap


## A full-screen printed frame: two hairlines, inset from the canvas edge.
static func print_frame(inset: int = 14) -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.offset_left = inset
	c.offset_top = inset
	c.offset_right = -inset
	c.offset_bottom = -inset
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outer := Panel.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Color(G.GOLD, 0.22)
	sb.set_border_width_all(1)
	outer.add_theme_stylebox_override("panel", sb)
	c.add_child(outer)
	var inner := Panel.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 4
	inner.offset_top = 4
	inner.offset_right = -4
	inner.offset_bottom = -4
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = Color(0, 0, 0, 0)
	sb2.border_color = Color(G.GOLD, 0.1)
	sb2.set_border_width_all(1)
	inner.add_theme_stylebox_override("panel", sb2)
	c.add_child(inner)
	return c


static func grain(alpha: float = 0.05) -> Control:
	if not ResourceLoader.exists(GRAIN_PATH):
		return Control.new()
	var t := TextureRect.new()
	t.texture = load(GRAIN_PATH)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.modulate = Color(1, 1, 1, alpha)
	return t


static func scrim(from_top: bool = true, height: int = 150, strength: float = 0.88) -> Control:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(0.024, 0.039, 0.078, strength),
		Color(0.024, 0.039, 0.078, strength * 0.45),
		Color(0.024, 0.039, 0.078, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 4
	tex.height = 64
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if from_top else Control.PRESET_BOTTOM_WIDE)
	if from_top:
		tr.offset_bottom = height
	else:
		tr.offset_top = -height
		if not from_top:
			tr.flip_v = true
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr


static func fade_in(node: CanvasItem, delay: float = 0.0, dur: float = 0.5) -> void:
	node.modulate.a = 0.0
	var tw := node.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, dur).set_trans(Tween.TRANS_SINE)


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func scroll() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s


static func margin(l: int, t: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


## A framed image plate: cream mat, hairline, image window, optional caption.
static func image_plate(tex: Texture2D, height: float, caption: String = "", rotate_deg: float = 0.0) -> Control:
	var wrap := vbox(7)
	var frame := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe4cf")
	sb.border_color = Color(0.2, 0.14, 0.06, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 22
	sb.shadow_offset = Vector2(0, 10)
	frame.add_theme_stylebox_override("panel", sb)
	frame.custom_minimum_size = Vector2(0, height)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(frame)

	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.offset_left = 9
	img.offset_top = 9
	img.offset_right = -9
	img.offset_bottom = -9
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(img)
	if rotate_deg != 0.0:
		frame.pivot_offset = Vector2(0, height * 0.5)
		frame.rotation = deg_to_rad(rotate_deg)
	if caption != "":
		var cap := micro(caption, Color(G.MUTED, 0.95), 9)
		cap.autowrap_mode = TextServer.AUTOWRAP_OFF
		cap.clip_text = true
		cap.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cap.custom_minimum_size = Vector2(0, 0)
		wrap.add_child(cap)
	return wrap

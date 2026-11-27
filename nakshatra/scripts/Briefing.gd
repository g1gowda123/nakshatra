class_name Briefing
extends RefCounted
## The written lesson that opens every exhibit. A full reading page on warm
## paper, not a cramped modal: the explanation comes before the interaction.

const PAPER := G.PAPER
const PAPER_DEEP := G.PAPER_DEEP
const INK := G.INK
const INK_SOFT := G.INK_SOFT
const GOLD_DARK := Color("6f5228")


static func show(host: Node, id: String, on_start: Callable = Callable()) -> Control:
	var info: Dictionary = G.module_info(id)
	var lesson: Dictionary = info.get("lesson", {})
	var vp := UI.viewport_size()
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	host.add_child(overlay)

	var bg := ColorRect.new()
	bg.color = PAPER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 8
	center.offset_right = -8
	center.offset_top = 8
	center.offset_bottom = -8
	overlay.add_child(center)

	var page := UI.vbox(0)
	page.custom_minimum_size = Vector2(minf(900.0, vp.x - 16.0), vp.y - 16.0)
	center.add_child(page)

	# ---- header -------------------------------------------------------
	var head := UI.margin(26 if not UI.is_compact() else 16, 16, 26 if not UI.is_compact() else 16, 0)
	page.add_child(head)
	var hv := UI.vbox(4)
	head.add_child(hv)

	var idx := G.MODULES.find(id)
	var top_row := UI.hbox(8)
	hv.add_child(top_row)
	var kicker := UI.micro("SKY NOTE %02d  ·  %s" % [idx + 1, str(info.get("tag", ""))], GOLD_DARK, 9)
	kicker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kicker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kicker.clip_text = true
	kicker.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	top_row.add_child(kicker)
	top_row.add_child(UI.micro("%02d  /  %02d" % [idx + 1, G.MODULES.size()], INK_SOFT, 8))

	var title_row := UI.hbox(10)
	hv.add_child(title_row)
	var tv := UI.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(tv)
	tv.add_child(UI.label(str(info.get("title", "")), 40 if not UI.is_compact() else 30, INK, "display"))
	var kn := str(info.get("kannada", ""))
	if kn != "":
		tv.add_child(UI.label(kn, 15, INK_SOFT, "kannada"))
	var close := _paper_button("Close  ×", false)
	close.custom_minimum_size = Vector2(96, 38)
	close.add_theme_font_size_override("font_size", 11)
	close.pressed.connect(func(): overlay.queue_free())
	title_row.add_child(close)

	page.add_child(_rule())

	# ---- scrollable note ---------------------------------------------
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 0)
	page.add_child(scroll)
	var body := UI.vbox(0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	var art_path := str(info.get("art", ""))
	var v: VBoxContainer
	var text_w: float
	if UI.is_compact() or UI.is_portrait():
		if art_path != "" and ResourceLoader.exists(art_path):
			body.add_child(_art_plate(art_path, info, Vector2(0, 170)))
		var content := UI.margin(16, 12, 16, 10)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(content)
		v = UI.vbox(8)
		content.add_child(v)
		text_w = minf(560.0, vp.x - 52.0)
	else:
		var spread := UI.hbox(24)
		spread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(spread)
		if art_path != "" and ResourceLoader.exists(art_path):
			spread.add_child(_art_plate(art_path, info, Vector2(268, 330)))
		var content := UI.margin(26, 14, 26, 10)
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spread.add_child(content)
		v = UI.vbox(8)
		content.add_child(v)
		text_w = minf(560.0, vp.x - 70.0)
	v.add_child(_para(str(lesson.get("big_idea", info.get("objective", ""))), 19 if not UI.is_compact() else 17, INK, text_w, "serif"))

	# Goal before detail: a Class 6 reader should know what they will do
	# before the page asks them to hold five paragraphs in their head.
	var do_text := str(lesson.get("what_you_do", ""))
	if do_text != "":
		var box := PanelContainer.new()
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color("eadcc2")
		bsb.border_color = Color(GOLD_DARK, 0.35)
		bsb.set_border_width_all(0)
		bsb.border_width_left = 2
		bsb.set_corner_radius_all(1)
		bsb.content_margin_left = 14
		bsb.content_margin_right = 14
		bsb.content_margin_top = 10
		bsb.content_margin_bottom = 10
		box.add_theme_stylebox_override("panel", bsb)
		v.add_child(box)
		var bv := UI.vbox(3)
		box.add_child(bv)
		bv.add_child(UI.label("WHAT YOU'LL DO", 10, GOLD_DARK, "body_med"))
		bv.add_child(_para(do_text, 14, INK, text_w - 30.0))

	for para in lesson.get("paragraphs", []):
		v.add_child(_para(str(para), 15, INK_SOFT, text_w))

	var terms: Array = lesson.get("terms", [])
	if terms.size() > 0:
		v.add_child(_rule())
		v.add_child(UI.label("KEY WORDS", 10, GOLD_DARK, "body_med"))
		var wrap := HFlowContainer.new()
		wrap.add_theme_constant_override("h_separation", 6)
		wrap.add_theme_constant_override("v_separation", 6)
		v.add_child(wrap)
		for t in terms:
			wrap.add_child(_chip(str(t)))

	var credit := str(info.get("art_credit", ""))
	if credit != "":
		v.add_child(_para(credit, 9, INK_SOFT, text_w))

	var facts: Array = info.get("facts", [])
	if facts.size() > 0:
		v.add_child(_rule())
		v.add_child(UI.label("FIELD NOTES", 10, GOLD_DARK, "body_med"))
		for f in facts:
			v.add_child(_para("•  " + str(f), 13, INK_SOFT, text_w))

	# ---- footer -------------------------------------------------------
	var footer := UI.margin(26 if not UI.is_compact() else 16, 6, 26 if not UI.is_compact() else 16, 14)
	page.add_child(footer)
	var fv := UI.vbox(6)
	footer.add_child(fv)
	fv.add_child(_rule())
	var row := UI.hbox(10)
	fv.add_child(row)
	var later := _paper_button("Read later", false)
	later.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	later.pressed.connect(func(): overlay.queue_free())
	row.add_child(later)
	var start := _paper_button("Start the lesson  ›", true)
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.pressed.connect(func(): overlay.queue_free())
	row.add_child(start)

	overlay.add_child(UI.grain(0.05))
	UI.fade_in(overlay, 0.0, 0.22)
	return overlay


static func _art_plate(path: String, info: Dictionary, size: Vector2) -> Control:
	var wrap := UI.vbox(6)
	var art_wrap := PanelContainer.new()
	var asb := StyleBoxFlat.new()
	asb.bg_color = Color("0b0c12")
	asb.border_color = Color(GOLD_DARK, 0.55)
	asb.set_border_width_all(1)
	asb.content_margin_left = 4
	asb.content_margin_right = 4
	asb.content_margin_top = 4
	asb.content_margin_bottom = 4
	art_wrap.add_theme_stylebox_override("panel", asb)
	art_wrap.custom_minimum_size = size
	art_wrap.clip_contents = true
	wrap.add_child(art_wrap)
	var art := TextureRect.new()
	art.texture = load(path)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_wrap.add_child(art)
	var cap := UI.micro(str(info.get("art_credit", "PLATE  ·  " + str(info.get("title", "")))), INK_SOFT, 8)
	cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(cap)
	return wrap


static func _para(text: String, size: int, color: Color, width: float, font_kind: String = "body") -> Label:
	var l := UI.label(text, size, color, font_kind)
	var cpl := maxi(24, int(width / (float(size) * 0.54)))
	var lines := maxi(1, int(ceil(float(text.length()) / float(cpl))))
	l.custom_minimum_size = Vector2(0, lines * int(float(size) * 1.5) + 5)
	l.add_theme_constant_override("line_spacing", 6)
	return l


static func _title(text: String, size: int) -> Label:
	var l := UI.label(text, size, INK, "display")
	l.add_theme_constant_override("outline_size", 0)
	return l


static func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(GOLD_DARK, 0.25)
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func _chip(text: String) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe3cc")
	sb.border_color = Color(GOLD_DARK, 0.3)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 9
	sb.content_margin_right = 9
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(UI.micro(text, INK, 10))
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func _paper_button(text: String, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(0, 46)
	b.text = text.to_upper()
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_font_override("font", UI.display_font())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = INK if primary else Color(1, 1, 1, 0.3)
	normal.border_color = INK
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(0)
	normal.shadow_color = Color(0, 0, 0, 0.45)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(4, 4)
	normal.content_margin_left = 20
	normal.content_margin_right = 20
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = G.VERMILION if primary else G.GOLD
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("090d16") if primary else Color(1, 1, 1, 0.2)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", UI.focus_ring())
	b.add_theme_color_override("font_color", PAPER if primary else INK)
	b.add_theme_color_override("font_hover_color", G.CREAM if primary else INK)
	b.add_theme_color_override("font_pressed_color", G.CREAM if primary else INK)
	UI.juice_button(b)
	return b

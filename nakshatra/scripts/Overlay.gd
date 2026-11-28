class_name Overlay
extends RefCounted
## One calm modal, reused by every lab for explanations and results.

static func info(host: Control, title: String, kicker: String, paragraphs: Array, facts: Array = [], art_path: String = "", close_text: String = "Close") -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	host.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.030, 0.028, 0.024, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 14
	center.offset_right = -14
	center.offset_top = 14
	center.offset_bottom = -14
	overlay.add_child(center)

	var panel := UI.panel(int(clampf(UI.viewport_size().x * 0.035, 14.0, 26.0)), 0.98)
	panel.custom_minimum_size = Vector2(minf(660, UI.viewport_size().x - 28), 0)
	center.add_child(panel)

	var v := UI.vbox(9)
	panel.add_child(v)

	if art_path != "" and ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.custom_minimum_size = Vector2(0, 118 if UI.is_compact() else 150)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(art)

	var bar := UI.hbox(8)
	v.add_child(bar)
	var tv := UI.vbox(2)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(tv)
	if kicker != "":
		var kl := UI.micro(kicker, Color(G.GOLD, 0.9), 9)
		kl.autowrap_mode = TextServer.AUTOWRAP_OFF
		tv.add_child(kl)
	var h := UI.heading(title, 28 if UI.is_compact() else 34)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tv.add_child(h)
	var x := UI.ghost_button("×", 18)
	x.custom_minimum_size = Vector2(48, 48)
	x.pressed.connect(func(): overlay.queue_free())
	bar.add_child(x)

	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y * 0.56, 460))
	v.add_child(scroll)
	var body := UI.vbox(9)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

	for p in paragraphs:
		var l := UI.label(str(p), 16 if not UI.is_compact() else 15)
		body.add_child(l)

	if facts.size() > 0:
		body.add_child(UI.divider())
		for f in facts:
			body.add_child(UI.label("•  " + str(f), 14, G.MUTED))

	v.add_child(UI.spacer(false, false))
	var close := UI.button(close_text, true, 17)
	close.pressed.connect(func(): overlay.queue_free())
	v.add_child(close)
	UI.fade_in(overlay, 0.0, 0.22)
	return overlay

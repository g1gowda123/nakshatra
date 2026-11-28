class_name FieldGuide
extends RefCounted
## A browsable, written guide to the ideas that do not need a whole exhibit:
## nebulae, supernovae, pulsars, galaxies, gravitational waves, exoplanets.

const PAPER := G.PAPER
const INK := G.INK
const INK_SOFT := G.INK_SOFT
const GOLD_DARK := Color("8a6a3c")


static func show(host: Node) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	host.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.006, 0.012, 0.03, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 10
	center.offset_right = -10
	center.offset_top = 10
	center.offset_bottom = -10
	overlay.add_child(center)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = Color(GOLD_DARK, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 12)
	panel.add_theme_stylebox_override("panel", sb)
	panel.custom_minimum_size = Vector2(minf(820.0, UI.viewport_size().x - 24.0), 0)
	center.add_child(panel)

	var col := UI.vbox(0)
	panel.add_child(col)

	var head := UI.margin(24, 20, 24, 8)
	col.add_child(head)
	var hv := UI.vbox(4)
	head.add_child(hv)
	hv.add_child(UI.micro("BEYOND THE SEVEN SKY NOTES", GOLD_DARK, 9))
	hv.add_child(UI.label("Field Guide to the Universe", 36, INK, "display"))
	hv.add_child(UI.label("Short, real explanations of the extremes — read any card, in any order.", 14, INK_SOFT))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, minf(UI.viewport_size().y - 320.0, 560.0))
	col.add_child(scroll)
	var body := UI.vbox(0)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	var inner := UI.margin(24, 4, 24, 40)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(inner)
	var v := UI.vbox(10)
	inner.add_child(v)

	var wonders: Array = G.content.get("wonders", [])
	for i in wonders.size():
		var w: Dictionary = wonders[i]
		var card := PanelContainer.new()
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color("efe3cc")
		csb.border_color = Color(GOLD_DARK, 0.22)
		csb.set_border_width_all(0)
		csb.border_width_left = 2
		csb.set_corner_radius_all(1)
		csb.content_margin_left = 16
		csb.content_margin_right = 16
		csb.content_margin_top = 12
		csb.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", csb)
		v.add_child(card)
		var cv := UI.vbox(4)
		card.add_child(cv)
		var cat := UI.micro(str(w.get("category", "")), GOLD_DARK, 9)
		cv.add_child(cat)
		cv.add_child(UI.label(str(w.get("title", "")), 24, INK, "serif"))
		var kn := str(w.get("kannada", ""))
		if kn != "":
			cv.add_child(UI.label(kn, 14, INK_SOFT, "kannada"))
		var t := UI.label(str(w.get("text", "")), 14, INK_SOFT)
		t.add_theme_constant_override("line_spacing", 5)
		cv.add_child(t)
		var link := str(w.get("link", ""))
		if link != "":
			var b := Button.new()
			b.text = "Open the lab  ›"
			b.focus_mode = Control.FOCUS_ALL
			b.text = "OPEN THE LAB  ›"
			b.custom_minimum_size = Vector2(0, 40)
			b.add_theme_font_size_override("font_size", 13)
			b.add_theme_font_override("font", UI.display_font())
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = G.INK
			bsb.border_color = G.INK
			bsb.set_border_width_all(2)
			bsb.set_corner_radius_all(0)
			bsb.shadow_color = Color(0, 0, 0, 0.35)
			bsb.shadow_size = 1
			bsb.shadow_offset = Vector2(3, 3)
			bsb.content_margin_left = 16
			bsb.content_margin_right = 16
			var bhov := bsb.duplicate() as StyleBoxFlat
			bhov.bg_color = G.VERMILION
			bhov.border_color = G.INK
			var bpress := bsb.duplicate() as StyleBoxFlat
			bpress.bg_color = G.GOLD
			bpress.shadow_offset = Vector2(1, 1)
			b.add_theme_stylebox_override("normal", bsb)
			b.add_theme_stylebox_override("hover", bhov)
			b.add_theme_stylebox_override("pressed", bpress)
			b.add_theme_stylebox_override("focus", UI.focus_ring())
			b.add_theme_color_override("font_color", G.PAPER)
			b.add_theme_color_override("font_hover_color", G.INK)
			var path := "res://scenes/MoonLab.tscn"
			if link == "flares":
				path = "res://scenes/SolarLab.tscn"
			elif link == "blackhole":
				path = "res://scenes/BlackHoleLab.tscn"
			elif link == "eclipse":
				path = "res://scenes/EclipseLab.tscn"
			b.pressed.connect(func():
				overlay.queue_free()
				Router.go(path))
			UI.juice_button(b)
			cv.add_child(b)

	var footer := UI.margin(24, 8, 24, 18)
	col.add_child(footer)
	var close := Briefing._paper_button("Close the field guide", true)
	close.pressed.connect(func(): overlay.queue_free())
	footer.add_child(close)

	overlay.add_child(UI.grain(0.05))
	UI.fade_in(overlay, 0.0, 0.22)
	return overlay

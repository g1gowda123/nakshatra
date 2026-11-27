extends Node3D
## Title screen: a real star field, a paper postcard, and one clear invitation.

var sky: SkyDome
var ui_root: Control
var content_root: Control
var overlay: Control
var _portrait := false
var _compact := false
var _rebuilding := false
var _t := 0.0


func _ready() -> void:
	_build_world()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	G.language_changed.connect(_on_language_changed)
	set_process(true)
	_check_debug_route.call_deferred()


func _check_debug_route() -> void:
	# Hidden QA route: --screen=lab / moon / stars / scale / seasons / quiz / atlas / finale
	var scene_key := ""
	if OS.get_cmdline_user_args().has("--skip-briefing"):
		for id in G.MODULES:
			G.briefing_seen[id] = true
	# QA capture helper: --modal=story|teacher|credits opens a title modal.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modal="):
			match a.get_slice("=", 1):
				"story": _show_story.call_deferred()
				"teacher": _show_teacher.call_deferred()
				"credits": _show_credits.call_deferred()
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String:
			scene_key = _query_value(q, "scene")
			if _query_value(q, "demo") == "1":
				G.unlock_all()
	elif OS.get_cmdline_user_args().size() > 0:
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--screen="):
				scene_key = a.get_slice("=", 1)
			elif not a.begins_with("--"):
				scene_key = str(a)
	var routes := {
		"lab": "res://scenes/Lab.tscn", "moon": "res://scenes/MoonLab.tscn",
		"stars": "res://scenes/StarLab.tscn", "scale": "res://scenes/ScaleLab.tscn",
		"seasons": "res://scenes/SeasonLab.tscn", "flares": "res://scenes/SolarLab.tscn",
		"blackhole": "res://scenes/BlackHoleLab.tscn", "quiz": "res://scenes/QuizLab.tscn",
		"atlas": "res://scenes/Atlas.tscn", "finale": "res://scenes/Finale.tscn",
		"seminar": "res://scenes/Seminar.tscn", "present": "res://scenes/Seminar.tscn",
	}
	if scene_key == "guide":
		G.pending_guide = true
		Router.quick_go("res://scenes/Lab.tscn")
		return
	if routes.has(scene_key) and ResourceLoader.exists(routes[scene_key]):
		Router.quick_go(routes[scene_key])


func _query_value(query: String, key: String) -> String:
	for pair in query.trim_prefix("?").split("&"):
		var kv := pair.split("=")
		if kv.size() == 2 and kv[0] == key:
			return kv[1]
	return ""


func _build_world() -> void:
	var cam := Camera3D.new()
	cam.name = "BootCamera"
	cam.fov = 62.0
	cam.position = Vector3(0, 7.0, 26.0)
	cam.rotation_degrees = Vector3(-12.0, 0, 0)
	cam.current = true
	add_child(cam)

	sky = SkyDome.new()
	sky.name = "Sky"
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 112.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_nakshatra_lines(false)
	# The title is read first; keep the sky rich but let the type win.
	sky.set_star_scale(1.18)
	sky.set_star_intensity(1.02)

	var ground := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 420.0
	cyl.bottom_radius = 420.0
	cyl.height = 1.0
	ground.mesh = cyl
	ground.position = Vector3(0, -2.0, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color("05080f")
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = gm
	add_child(ground)

	var meteors := ShootingStarField.new()
	meteors.name = "Meteors"
	add_child(meteors)

	# A whisper of gold dust in the air, so the title breathes.
	var dust := CPUParticles3D.new()
	dust.amount = 26
	dust.lifetime = 14.0
	dust.preprocess = 6.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(10, 5, 5)
	dust.position = Vector3(0, 4.0, 8.0)
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 55.0
	dust.gravity = Vector3(0, 0.02, 0)
	dust.initial_velocity_min = 0.01
	dust.initial_velocity_max = 0.06
	dust.scale_amount_min = 0.02
	dust.scale_amount_max = 0.06
	dust.color = Color(1.0, 0.78, 0.46, 0.55)
	var dq := QuadMesh.new()
	dq.size = Vector2(1, 1)
	dust.mesh = dq
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dmat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dmat.albedo_texture = load("res://assets/fx/glow.png")
	dmat.vertex_color_use_as_albedo = true
	dmat.disable_receive_shadows = true
	dust.material_override = dmat
	add_child(dust)


func _process(delta: float) -> void:
	_t += delta
	if sky:
		sky.sidereal_deg = fmod(sky.sidereal_deg + delta * 0.35, 360.0)
		sky.set_sidereal(sky.sidereal_deg)
	var cam := get_node_or_null("BootCamera") as Camera3D
	if cam:
		cam.position = Vector3(sin(_t * 0.07) * 0.22, 7.0 + sin(_t * 0.11) * 0.10, 26.0)
		cam.rotation_degrees.x = -12.0 + sin(_t * 0.09) * 0.12


func _build_ui() -> void:
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
	ui_root.name = "UI"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.theme()
	add_child(ui_root)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui_root.add_child(vignette)
	ui_root.add_child(UI.scrim(true, 156, 0.72))

	content_root = Control.new()
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(content_root)

	content_root.add_child(UI.print_frame(16))

	var outer := UI.margin(UI.pad() + 6, 24, UI.pad() + 6, 16)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(outer)

	var col := UI.vbox(0)
	outer.add_child(col)

	col.add_child(_top_bar())

	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(body)

	_portrait = UI.is_portrait()
	if _portrait:
		_build_portrait_body(body)
	else:
		_build_landscape_body(body)

	col.add_child(_footer())

	ui_root.add_child(UI.grain(0.05))
	UI.fade_in(content_root, 0.05, 0.9)



func _top_bar() -> Control:
	var wrap := UI.vbox(11)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := UI.hbox(12)
	row.add_child(UI.brand_mark(24))

	var brand := UI.tracked("NAKSHATRA", 12, Color(G.GOLD, 0.95), 4)
	brand.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(brand)

	if not UI.is_compact():
		var sep := ColorRect.new()
		sep.color = Color(G.GOLD, 0.3)
		sep.custom_minimum_size = Vector2(1, 14)
		sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sep)

		var kicker := UI.tracked("A SKY ALMANAC", 9, Color(G.MUTED, 0.85), 3)
		kicker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(kicker)
	row.add_child(UI.spacer())

	var lang := UI.link_button("ಕನ್ನಡ" if G.lang == "en" else "English", 13)
	if G.lang == "kn":
		lang.add_theme_font_override("font", UI.body_med_font())
	lang.pressed.connect(func():
		Sfx.play("click")
		G.set_lang("kn" if G.lang == "en" else "en"))
	row.add_child(lang)

	var dot := UI.label("·", 13, Color(G.MUTED, 0.5))
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot)

	var snd := UI.link_button("SOUND ON" if G.sound_on else "SOUND OFF", 10)
	snd.pressed.connect(func():
		G.sound_on = not G.sound_on
		G.save_game()
		Sfx.play("click")
		_rebuild())
	row.add_child(snd)

	wrap.add_child(row)
	wrap.add_child(UI.rule(Color(G.GOLD, 0.2), 1))
	return wrap


func _build_landscape_body(body: Control) -> void:
	var h := UI.hbox(40)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(h)

	var compact := UI.is_compact()
	var left := UI.vbox(0 if compact else 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(left)
	_add_title_block(left, 48 if compact else 88)

	var right := UI.vbox(8)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right.custom_minimum_size = Vector2(320 if compact else 430, 0)
	h.add_child(right)
	_add_postcard(right, Vector2(320, 236) if compact else Vector2(430, 330), true)


func _build_portrait_body(body: Control) -> void:
	var v := UI.vbox(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(v)

	var art_wrap := Control.new()
	art_wrap.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y * 0.22, 150.0, 250.0))
	art_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	art_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art_wrap)
	_add_postcard(art_wrap, Vector2(0, art_wrap.custom_minimum_size.y), false)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)

	var left := UI.vbox(0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(left)
	_add_title_block(left, 60)


func _add_title_block(parent: VBoxContainer, title_size: int) -> void:
	var compact_land := UI.is_compact() and not UI.is_portrait()
	var col := UI.vbox(7)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(col)

	var kicker := UI.tracked("A FREE-CHOICE SKY LAB   ·   CLASSES 6–9", 9 if compact_land else 10, Color(G.GOLD_SOFT, 0.95), 2)
	col.add_child(kicker)

	var title := UI.display("Nakshatra", title_size, G.CREAM)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size.y = title_size * 0.82
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	col.add_child(title)

	var sub := UI.tracked("THE SKY WEAVERS", int(clampf(title_size * 0.18, 11, 15)), Color(G.GOLD, 0.95), 6)
	col.add_child(sub)

	var kannada := UI.label("ನಕ್ಷತ್ರ  ·  ಆಕಾಶ ನೇಯುವವರು", int(clampf(title_size * 0.22, 14, 19)), Color(G.GOLD, 0.62), "kannada")
	col.add_child(kannada)

	var gap := UI.rule(Color(G.GOLD, 0.18), 1)
	gap.custom_minimum_size = Vector2(0, 1)
	col.add_child(gap)

	var tag := UI.label("Seven lanterns on a hill. One real sky. Choose any path.", int(clampf(title_size * 0.22, 15, 19)), G.CREAM)
	col.add_child(tag)

	var tag2 := UI.label("A free-choice night lab for middle school — at home on a phone, or on the classroom wall.", 14, Color(G.MUTED, 0.95))
	if not compact_land:
		col.add_child(tag2)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 5)
	gap2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(gap2)

	var buttons := UI.vbox(12)
	col.add_child(buttons)

	var begin := UI.button("Begin the night   ›", true, 20)
	begin.custom_minimum_size = Vector2(250 if not compact_land else 220, 48)
	begin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	begin.pressed.connect(func():
		Sfx.play("lantern")
		Router.go("res://scenes/Lab.tscn"))
	buttons.add_child(begin)

	var links := UI.hbox(6)
	buttons.add_child(links)
	var seminar := UI.link_button("Seminar mode   ›", 11, G.GOLD)
	seminar.pressed.connect(func():
		Sfx.play("chime")
		G.seminar_index = 0
		Router.go("res://scenes/Seminar.tscn"))
	links.add_child(seminar)
	var dot0 := UI.label("·", 12, Color(G.MUTED, 0.5))
	dot0.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	links.add_child(dot0)
	var atlas := UI.link_button("Sky Atlas   ›", 11)
	atlas.pressed.connect(func():
		Sfx.play("click")
		Router.go("res://scenes/Atlas.tscn"))
	links.add_child(atlas)
	var dot := UI.label("·", 12, Color(G.MUTED, 0.5))
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	links.add_child(dot)
	var story := UI.link_button("The Story   ›", 11)
	story.pressed.connect(func():
		Sfx.play("click")
		_show_story())
	links.add_child(story)


func _add_postcard(parent: Control, size: Vector2, rotate: bool) -> void:
	var tex: Texture2D = null
	if ResourceLoader.exists("res://assets/art/plates/plate_title.webp"):
		tex = load("res://assets/art/plates/plate_title.webp")
	var plate := UI.image_plate(tex, size.y, "PLATE I  ·  THE LANTERN HILL  ·  13° N", -1.2 if rotate else 0.0)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent is Control and not (parent is VBoxContainer):
		plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		plate.offset_left = 6
		plate.offset_right = -6
		plate.offset_top = 4
		plate.offset_bottom = -4
	parent.add_child(plate)
	# A slow, barely-there sway: the plate is handled paper, not a billboard.
	plate.pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	var base_rot := plate.rotation
	var tw := plate.create_tween().set_loops()
	tw.tween_property(plate, "rotation", base_rot + deg_to_rad(0.55), 5.2).set_trans(Tween.TRANS_SINE)
	tw.tween_property(plate, "rotation", base_rot - deg_to_rad(0.55), 5.2).set_trans(Tween.TRANS_SINE)


func _footer() -> Control:
	var wrap := UI.vbox(9)
	var row := UI.hbox(6)
	var teacher := UI.link_button("FOR TEACHERS", 9)
	teacher.pressed.connect(func():
		Sfx.play("click")
		_show_teacher())
	row.add_child(teacher)
	var dot1 := UI.label("·", 11, Color(G.MUTED, 0.5))
	dot1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot1)
	var guide := UI.link_button("FIELD GUIDE", 9)
	guide.pressed.connect(func():
		Sfx.play("click")
		G.show_field_guide())
	row.add_child(guide)
	var dot2 := UI.label("·", 11, Color(G.MUTED, 0.5))
	dot2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(dot2)
	var credits := UI.link_button("CREDITS", 9)
	credits.pressed.connect(func():
		Sfx.play("click")
		_show_credits())
	row.add_child(credits)
	row.add_child(UI.spacer())
	var note := UI.tracked("CHANDRAGIRI  ·  13° N  ·  V 1.2.1", 8, Color(G.MUTED, 0.6), 2)
	note.autowrap_mode = TextServer.AUTOWRAP_OFF
	note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(note)
	wrap.add_child(UI.rule(Color(G.GOLD, 0.14), 1))
	wrap.add_child(row)
	return wrap


func _rebuild() -> void:
	if _rebuilding:
		return
	_rebuilding = true
	await get_tree().process_frame
	_build_ui()
	_rebuilding = false


func _on_resize() -> void:
	var p := UI.is_portrait()
	var c := UI.is_compact()
	if p != _portrait or c != _compact:
		_portrait = p
		_compact = c
		_rebuild()


func _on_language_changed() -> void:
	_rebuild()


func _show_story() -> void:
	var paras: Array = G.content.get("story", [])
	var body := UI.vbox(12)
	body.add_child(UI.label("A story you can skip — the sky lab is always open.", 13, G.INK_SOFT))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	for p in paras:
		body.add_child(UI.label(str(p), 16, G.INK))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	var go := UI.ink_button("Explore the lab   ›", true, 16)
	go.pressed.connect(func():
		_clear_overlay()
		Router.go("res://scenes/Lab.tscn"))
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal("The Lantern Festival", body, "res://assets/art/story_festival.webp", "PLATE II  ·  THE FESTIVAL ON THE HILL", go)


func _show_teacher() -> void:
	var body := UI.vbox(12)
	body.add_child(UI.label("A note you can read in a minute.", 13, G.INK_SOFT))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	body.add_child(UI.label(str(G.content.get("teacher_note", "")), 16, G.INK))
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 6)
	body.add_child(chips)
	for topic in ["Moon phases", "Nakshatras", "Scale", "Seasons", "Assessment"]:
		chips.add_child(UI.pill(topic, G.INK_SOFT, 12))
	body.add_child(UI.label("Suggested flow: five minutes of free exploration › the Sky Riddles as a pre-test › two exhibits › the same riddles as a post-test › a five-minute sky walk outside.", 14, G.INK_SOFT))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	var row := UI.hbox(10)
	var close := UI.ink_button("Close", true, 15)
	close.pressed.connect(_clear_overlay)
	row.add_child(close)
	var reset := UI.ink_button("Reset all progress", false, 13)
	reset.pressed.connect(_confirm_reset)
	row.add_child(reset)
	_modal("For teachers", body, "", "", row)


func _confirm_reset() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Clear every lantern, quiz score and saved setting on this device?"
	dlg.title = "Reset progress?"
	dlg.ok_button_text = "Reset"
	dlg.cancel_button_text = "Keep"
	dlg.confirmed.connect(func():
		G.reset_progress()
		Sfx.play("whoosh")
		_clear_overlay())
	ui_root.add_child(dlg)
	dlg.popup_centered()


func _show_credits() -> void:
	var body := UI.vbox(11)
	body.add_child(UI.label("Made with care for curious sky-watchers.", 13, G.INK_SOFT))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	body.add_child(UI.rich("[b]Sky data[/b]\nHYG Database v3 (David Nash, astronomynexus.com), CC BY-SA 4.0. Constellation and nakshatra line data from Stellarium skycultures (GPL v2), used with gratitude.", 14, G.INK_SOFT))
	body.add_child(UI.rich("[b]Illustrations[/b]\nOriginal papercut-style art made for this project. No stock images, no external assets.", 14, G.INK_SOFT))
	body.add_child(UI.rich("[b]Type[/b]\nCormorant Garamond, Noto Serif, Noto Sans and Noto Sans Kannada — SIL Open Font License.", 14, G.INK_SOFT))
	body.add_child(UI.rich("[b]Everything else[/b]\nCode, design, star shaders and audio are original and offline. Schools may copy and share the game freely.", 14, G.INK_SOFT))
	body.add_child(UI.label("A note on scale: planet sizes and distances are exaggerated or compressed so they can share a screen. The numbers are real; the drawing is a diagram.", 13, G.INK_SOFT))
	body.add_child(UI.rule(Color(G.INK, 0.18), 1))
	var close := UI.ink_button("Close", true, 15)
	close.pressed.connect(_clear_overlay)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_modal("Credits & sources", body, "res://assets/art/plates/plate_atlas.webp", "PLATE III  ·  THE SKY ATLAS", close)


func _modal(title: String, body: Control, art_path: String = "", caption: String = "", footer: Control = null) -> void:
	_clear_overlay()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.012, 0.008, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			_clear_overlay())
	overlay.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	center.offset_top = 16
	center.offset_bottom = -16
	overlay.add_child(center)

	var sheet := UI.paper(UI.pad())
	sheet.custom_minimum_size = Vector2(minf(660, UI.viewport_size().x - 32), 0)
	sheet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(sheet)

	var v := UI.vbox(12)
	sheet.add_child(v)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var top := UI.hbox(10)
	v.add_child(top)
	var kicker := UI.micro("NAKSHATRA  ·  A NOTE", Color("8a6a3c"), 9)
	kicker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(kicker)
	top.add_child(UI.spacer())
	var x := UI.link_button("CLOSE  ×", 10, G.INK)
	x.pressed.connect(_clear_overlay)
	top.add_child(x)

	v.add_child(UI.heading(title, 30, G.INK))
	v.add_child(UI.rule(Color(G.INK, 0.25), 1))

	if art_path != "" and ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.custom_minimum_size = Vector2(0, 132 if UI.viewport_size().y >= 680 else 96)
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(art)
		if caption != "":
			v.add_child(UI.micro(caption, Color("8a6a3c"), 8))

	var scroll := UI.scroll()
	scroll.custom_minimum_size = Vector2(0, clampf(UI.viewport_size().y - 440.0, 180.0, 360.0))
	scroll.add_child(body)
	v.add_child(scroll)
	if footer:
		v.add_child(footer)
	UI.fade_in(overlay, 0.0, 0.25)


func _clear_overlay() -> void:
	if overlay:
		overlay.queue_free()
		overlay = null

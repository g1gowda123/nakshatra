extends Node3D
## Find real constellations in a real star field. Tap three stars to thread them.

var sky: SkyDome
var cam: Camera3D
var ui_root: Control
var marker_layer: Control
var hunts: Array = []
var hunt_index := 0
var found_hips: Array[int] = []
var hint_hips: Array[int] = []
var target_hips: Array = []
var hint_until := 0.0
var feedback := ""
var feedback_color := G.GOLD
var completed := false
var story_open := false
var round_complete := false
var _pressed := false
var _looked := false
var _press_pos := Vector2.ZERO
var _last_pos := Vector2.ZERO
var _drag_accum := 0.0

var title_label: Label
var progress_label: Label
var hint_label: Label
var pips: HBoxContainer
var feedback_label: Label
var next_btn: Button
var _idle := 0.0
var _t := 0.0
var _facing_t := 0.0
var polaris_hip := -1
var _target_glows: Array[Node3D] = []

## The classic seven-star figures, used for the hunt so the clue matches the sky.
## HIP identifiers are from the Hipparcos catalogue.
const MAIN_STARS := {
	"UMa": [54061, 53910, 58001, 59774, 62956, 65378, 67301],
	"Ori": [27989, 25336, 26727, 26311, 25930, 27366, 24436],
	"Cas": [3179, 746, 4427, 6686, 8886],
	"Sco": [80763, 85927, 86228, 78401, 78820, 80112, 84143],
	"Cyg": [102098, 100453, 102488, 97165, 95947, 94779, 99848],
}


func _ready() -> void:
	hunts = G.content.get("star_hunts", [])
	_build_world()
	_build_ui()
	_guide_to_current()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)
	G.maybe_briefing(ui_root, "stars")
	if OS.get_cmdline_user_args().has("--stars-reveal"):
		await get_tree().process_frame
		_reveal()
	elif OS.get_cmdline_user_args().has("--stars-hint"):
		await get_tree().process_frame
		_show_hint()


func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 100.0
	cam.near = 0.1
	cam.far = 2000.0
	cam.current = true
	add_child(cam)

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_nakshatra_lines(false)
	sky.set_star_scale(1.9)
	sky.set_star_intensity(1.15)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.46

	var meteors := ShootingStarField.new()
	meteors.name = "Meteors"
	add_child(meteors)


func _guide_to_current() -> void:
	if hunt_index >= hunts.size():
		return
	var id := str(hunts[hunt_index].get("id", ""))
	cam.rotation = Vector3.ZERO
	var framed = sky.guided_to_constellation(id)
	sky.guided_to_ra_dec(float(framed.get("ra", 0.0)), float(framed.get("dec", 0.0)), Vector3(0, 0.28, -1.0))
	sky.clear_highlight()
	found_hips.clear()
	hint_hips.clear()
	target_hips = _target_stars()
	polaris_hip = 11767 if id == "UMa" else -1
	feedback = ""
	round_complete = false
	_update_ui()
	_refresh_target_glows()


func _refresh_target_glows() -> void:
	for g in _target_glows:
		if is_instance_valid(g):
			g.queue_free()
	_target_glows.clear()
	for hip in target_hips:
		var idx := StarDB.star_index_by_hip(int(hip))
		if idx < 0:
			continue
		var halo := Sprite3D.new()
		halo.texture = load("res://assets/fx/glow.png")
		halo.pixel_size = 0.16
		halo.scale = Vector3.ONE * 1.15
		halo.modulate = Color(1.0, 0.79, 0.46, 0.58)
		halo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		halo.shaded = false
		halo.no_depth_test = true
		halo.render_priority = 2
		halo.position = sky.star_positions[idx]
		halo.set_meta("base_alpha", 0.58)
		halo.set_meta("pulse", 0.10)
		sky.add_child(halo)
		_target_glows.append(halo)

		var core := Sprite3D.new()
		core.texture = load("res://assets/fx/glow.png")
		core.pixel_size = 0.06
		core.scale = Vector3.ONE * 0.62
		core.modulate = Color(1.0, 0.86, 0.58, 1.0)
		core.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		core.shaded = false
		core.no_depth_test = true
		core.render_priority = 3
		core.position = sky.star_positions[idx]
		core.set_meta("base_alpha", 1.0)
		core.set_meta("pulse", 0.0)
		sky.add_child(core)
		_target_glows.append(core)
	# For the Saptarishi hunt, name Dhruva: the clue's pointer star.
	var hunt_id := str(hunts[hunt_index].get("id", "")) if hunt_index < hunts.size() else ""
	if hunt_id == "UMa":
		var pidx := StarDB.star_index_by_hip(11767)
		if pidx >= 0 and not UI.is_compact():
			var pl := Label3D.new()
			pl.text = "Dhruva  ·  Polaris"
			pl.font = UI.body_med_font()
			pl.font_size = 76
			pl.pixel_size = 0.52
			pl.modulate = Color(G.GOLD, 0.95)
			pl.outline_size = 12
			pl.outline_modulate = Color(0.01, 0.02, 0.05, 0.98)
			pl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			pl.no_depth_test = true
			pl.render_priority = 4
			pl.position = sky.star_positions[pidx] + Vector3(0, 16, 0)
			sky.add_child(pl)
			_target_glows.append(pl)


func _target_stars() -> Array:
	if hunt_index >= hunts.size():
		return []
	var hunt_id := str(hunts[hunt_index].get("id", ""))
	if MAIN_STARS.has(hunt_id):
		return (MAIN_STARS[hunt_id] as Array).duplicate()
	var c = StarDB.constellation(hunt_id)
	return c.get("stars", [])


func _marker_stars() -> Array[int]:
	var stars: Array = target_hips
	var sorted := stars.duplicate()
	sorted.sort_custom(func(a, b):
		var sa := StarDB.hip_star(int(a))
		var sb := StarDB.hip_star(int(b))
		return float(sa.get("mag", 9.0)) < float(sb.get("mag", 9.0)))
	var out: Array[int] = []
	for h in sorted:
		if out.size() >= 7:
			break
		out.append(int(h))
	return out


func _hint_stars() -> Array[int]:
	var stars: Array = target_hips
	var out: Array[int] = []
	var sorted := stars.duplicate()
	sorted.sort_custom(func(a, b):
		var sa := StarDB.hip_star(int(a))
		var sb := StarDB.hip_star(int(b))
		return float(sa.get("mag", 9.0)) < float(sb.get("mag", 9.0)))
	for h in sorted:
		if out.size() >= 3:
			break
		out.append(int(h))
	return out


func _build_ui() -> void:
	if marker_layer:
		if marker_layer.draw.is_connected(_draw_markers):
			marker_layer.draw.disconnect(_draw_markers)
		marker_layer.queue_free()
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.theme()
	add_child(ui_root)

	marker_layer = Control.new()
	marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_layer.draw.connect(_draw_markers)
	ui_root.add_child(marker_layer)

	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.material = ShaderMaterial.new()
	vignette.material.shader = load("res://shaders/vignette.gdshader")
	ui_root.add_child(vignette)
	ui_root.add_child(UI.scrim(true, 156, 0.72))

	var outer := UI.margin(UI.pad(), 12, UI.pad(), 12)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(outer)
	var col := UI.vbox(10)
	outer.add_child(col)
	col.add_child(_top_bar())
	col.add_child(UI.spacer(false, true))
	var bottom := _bottom_panel()
	bottom.custom_minimum_size = Vector2(0, 0)
	col.add_child(bottom)

	UI.fade_in(ui_root, 0.05, 0.6)


func _top_bar() -> Control:
	progress_label = UI.micro("", Color(G.GOLD, 0.9), 9)
	var acts: Array = [{"text": "LESSON", "fn": func(): _show_learn()}]
	if not UI.is_compact():
		acts.append({"text": "SKY ATLAS", "fn": func(): Router.go("res://scenes/Atlas.tscn")})
	return UI.app_bar("Thread the Stars", "CONSTELLATIONS  ·  A REAL SKY HUNT", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB", progress_label)


func _bottom_panel() -> Control:
	var panel := UI.panel(16, 0.9)
	var v := UI.vbox(6)
	panel.add_child(v)

	var head := UI.hbox(8)
	v.add_child(head)
	title_label = UI.label("", 24, G.CREAM, "serif")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	head.add_child(title_label)
	var kan := UI.label("", 14, Color(G.GOLD, 0.85), "kannada")
	kan.name = "Kannada"
	head.add_child(kan)

	v.add_child(UI.micro("TAP THREE OF ITS STARS  ·  DRAG TO LOOK AROUND", Color(G.GOLD, 0.75), 8))
	hint_label = UI.label("", 13, G.MUTED)
	if UI.is_compact():
		hint_label.max_lines_visible = 5
		hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(hint_label)
	pips = UI.hbox(4)
	v.add_child(pips)
	feedback_label = UI.label("", 13, G.GOLD)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(feedback_label)
	var row := UI.hbox(8)
	v.add_child(row)
	var hint_btn := UI.ghost_button("Hint: show me 3 stars", 14)
	hint_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_btn.pressed.connect(_show_hint)
	row.add_child(hint_btn)
	var reveal := UI.ghost_button("Pattern" if UI.is_compact() else "Draw the pattern", 14)
	reveal.custom_minimum_size = Vector2(110 if UI.is_compact() else 190, 42)
	reveal.pressed.connect(_reveal)
	row.add_child(reveal)
	next_btn = UI.button("Next constellation  ›", true, 16)
	next_btn.visible = false
	next_btn.pressed.connect(_go_next)
	v.add_child(next_btn)
	return panel


func _update_ui() -> void:
	if hunts.is_empty():
		return
	var h: Dictionary = hunts[clampi(hunt_index, 0, hunts.size() - 1)]
	title_label.text = "%s  ·  %s" % [str(h.get("name", "")), str(h.get("western", ""))]
	title_label.add_theme_font_size_override("font_size", 20 if UI.is_compact() else 24)
	var kn_text := str(h.get("kannada", ""))
	hint_label.text = str(h.get("hint", "")) + ("\n" + kn_text if kn_text != "" else "")
	progress_label.text = "%d / %d" % [mini(hunt_index + 1, hunts.size()), hunts.size()]
	for c in pips.get_children():
		c.queue_free()
	var states := []
	for i in 3:
		states.append(2 if i < found_hips.size() else 0)
	pips.add_child(UI.pip_row(states, 12.0, G.GOLD))
	feedback_label.text = feedback
	feedback_label.add_theme_color_override("font_color", feedback_color)
	if next_btn:
		next_btn.visible = round_complete
		next_btn.text = "Finish the hunt  ›" if hunt_index >= hunts.size() - 1 else "Next constellation  ›"


func _show_hint() -> void:
	_idle = 0.0
	hint_hips = _hint_stars()
	hint_until = Time.get_ticks_msec() / 1000.0 + 6.0
	feedback = "Three of them are glowing teal for a moment. Tap those stars."
	feedback_color = G.TEAL
	Sfx.play("chime")
	_update_ui()


func _reveal() -> void:
	var h: Dictionary = hunts[hunt_index]
	sky.set_highlight(str(h.get("id", "")), Color(G.GOLD))
	feedback = "Here is the pattern. Tap any three of its stars to keep it."
	feedback_color = G.GOLD
	Sfx.play("chime")


func _draw_markers() -> void:
	if hunts.is_empty() or sky == null or cam == null:
		return
	for hip in found_hips:
		var idx := StarDB.star_index_by_hip(hip)
		if idx < 0:
			continue
		var w := sky.star_world(idx)
		if cam.is_position_behind(w):
			continue
		var sp := cam.unproject_position(w)
		marker_layer.draw_arc(sp, 17, 0, TAU, 28, Color(G.GOLD, 0.9), 2.0, true)
		marker_layer.draw_arc(sp, 23, 0, TAU, 28, Color(G.GOLD, 0.25), 1.0, true)
	# Thread the stars the player has already found, in tap order.
	if found_hips.size() > 1:
		var pts := PackedVector2Array()
		for hip in found_hips:
			var fi := StarDB.star_index_by_hip(hip)
			if fi < 0:
				continue
			var fw := sky.star_world(fi)
			if cam.is_position_behind(fw):
				continue
			pts.append(cam.unproject_position(fw))
		if pts.size() > 1:
			marker_layer.draw_polyline(pts, Color(G.GOLD, 0.55), 3.0, true)
			marker_layer.draw_polyline(pts, Color(G.GOLD, 0.95), 1.2, true)
	if polaris_hip >= 0:
		var pidx := StarDB.star_index_by_hip(polaris_hip)
		if pidx >= 0:
			var pw := sky.star_world(pidx)
			if not cam.is_position_behind(pw):
				var psp := cam.unproject_position(pw)
				marker_layer.draw_arc(psp, 11, 0, TAU, 24, Color(G.GOLD, 0.55), 1.2, true)
				marker_layer.draw_line(psp + Vector2(-16, 0), psp + Vector2(-6, 0), Color(G.GOLD, 0.55), 1.0)
				marker_layer.draw_line(psp + Vector2(6, 0), psp + Vector2(16, 0), Color(G.GOLD, 0.55), 1.0)
	if Time.get_ticks_msec() / 1000.0 < hint_until:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.15
		for hip in hint_hips:
			var idx := StarDB.star_index_by_hip(hip)
			if idx < 0:
				continue
			var w := sky.star_world(idx)
			if cam.is_position_behind(w):
				continue
			var sp := cam.unproject_position(w)
			marker_layer.draw_arc(sp, 22 * pulse, 0, TAU, 32, Color(G.TEAL, 0.9), 2.0, true)


func _process(delta: float) -> void:
	_t += delta
	if marker_layer:
		marker_layer.queue_redraw()
	if story_open or completed or hunts.is_empty():
		return
	_idle += delta
	for i in _target_glows.size():
		var g := _target_glows[i]
		if g is Sprite3D and is_instance_valid(g):
			var base := float(g.get_meta("base_alpha", 0.5))
			var amp := float(g.get_meta("pulse", 0.0))
			g.modulate.a = clampf(base + amp * sin(_t * 1.6 + i * 0.8), 0.0, 1.0)
	_facing_t += delta
	if _facing_t > 0.25:
		_facing_t = 0.0
		if progress_label and not hunts.is_empty():
			progress_label.text = "%d / %d  ·  %s" % [mini(hunt_index + 1, hunts.size()), hunts.size(), _facing_text()]
	if _idle > 16.0 and hint_hips.is_empty() and not round_complete:
		_show_hint()


func _facing_text() -> String:
	var yaw := -rad_to_deg(cam.rotation.y + sky.rotation.y)
	var dirs := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
	var idx := int(round(fposmod(yaw, 360.0) / 45.0)) % 8
	return dirs[idx]


func _pick_at(pos: Vector2) -> void:
	_idle = 0.0
	if story_open or completed or hunts.is_empty():
		return
	var target: Array = target_hips
	# First, give priority to the pattern itself: tap near any of its stars.
	var best_h := -1
	var best_d := 55.0 * 55.0
	for h in target:
		var idx := StarDB.star_index_by_hip(int(h))
		if idx < 0:
			continue
		var w := sky.star_world(idx)
		if cam.is_position_behind(w):
			continue
		var sp := cam.unproject_position(w)
		var d := sp.distance_squared_to(pos)
		if d < best_d:
			best_d = d
			best_h = int(h)
	if best_h >= 0:
		if best_h in found_hips:
			feedback = "That one is already threaded."
			feedback_color = G.MUTED
			_update_ui()
			return
		found_hips.append(best_h)
		Sfx.play("chime")
		feedback = "%d of 3 stars threaded." % found_hips.size()
		feedback_color = G.TEAL
		_update_ui()
		if found_hips.size() >= 3:
			_success()
		return

	var pick := sky.pick_star(pos, cam, 44.0 if DisplayServer.is_touchscreen_available() else 36.0)
	if pick.is_empty():
		feedback = "No star there. Tap closer to a bright dot."
		feedback_color = G.MUTED
		_update_ui()
		return
	var info := StarDB.hip_star(int(pick["hip"]))
	var con := str(info.get("con", ""))
	Sfx.play("soft_error")
	if con != "" and con != str(hunts[hunt_index].get("id", "")):
		feedback = "That star is in %s. %s" % [con, str(hunts[hunt_index].get("hint", ""))]
	else:
		feedback = "A real star — but not one of this pattern. Follow the hint."
	feedback_color = G.ROSE
	_update_ui()


func _go_next() -> void:
	hunt_index += 1
	if hunt_index >= hunts.size():
		_complete()
	else:
		_guide_to_current()


func _success() -> void:
	round_complete = true
	var h: Dictionary = hunts[hunt_index]
	sky.set_highlight(str(h.get("id", "")), Color(G.GOLD))
	Sfx.play("success")
	feedback = "You found %s." % str(h.get("name", ""))
	feedback_color = G.TEAL
	_update_ui()
	await get_tree().create_timer(0.9).timeout
	_show_story(h)


func _show_story(h: Dictionary) -> void:
	story_open = true
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.85)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	overlay.add_child(center)
	var panel := UI.panel(UI.pad(), 0.98)
	panel.custom_minimum_size = Vector2(minf(640, UI.viewport_size().x - 32), 0)
	center.add_child(panel)
	var v := UI.vbox(10)
	panel.add_child(v)
	var art := TextureRect.new()
	art.texture = load("res://assets/art/card_stars.webp")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size = Vector2(0, 120)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(art)
	v.add_child(UI.label(str(h.get("name", "")) + "  ·  " + str(h.get("western", "")), 12, G.TEAL, "body_med"))
	v.add_child(UI.heading(str(h.get("name", "")), 30))
	v.add_child(UI.label(str(h.get("kannada", "")), 15, G.GOLD, "kannada"))
	v.add_child(UI.label(str(h.get("story", "")), 15))
	v.add_child(UI.label(str(h.get("science", "")), 14, G.MUTED))
	var nak := UI.label(str(h.get("nakshatra", "")), 13, Color(G.GOLD, 0.85))
	nak.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nak.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(nak)
	v.add_child(UI.spacer(false, false))
	var row := UI.hbox(8)
	v.add_child(row)
	var next := UI.button("Next constellation  ›" if hunt_index < hunts.size() - 1 else "Finish the hunt  ›", true, 17)
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next.pressed.connect(func():
		overlay.queue_free()
		story_open = false
		_go_next())
	row.add_child(next)
	var close := UI.ghost_button("Stay here", 14)
	close.pressed.connect(func():
		overlay.queue_free()
		story_open = false)
	row.add_child(close)


func _complete() -> void:
	completed = true
	G.complete("stars")
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.theme = UI.theme()
	ui_root.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_left = 16
	center.offset_right = -16
	overlay.add_child(center)
	var panel := UI.panel(UI.pad(), 0.98)
	panel.custom_minimum_size = Vector2(minf(600, UI.viewport_size().x - 32), 0)
	center.add_child(panel)
	var v := UI.vbox(10)
	panel.add_child(v)
	v.add_child(UI.micro("SKY CARTOGRAPHER", Color(G.GOLD, 0.9), 8))
	v.add_child(UI.heading("Five patterns, one real sky.", 28))
	v.add_child(UI.label("You found Saptarishi, Mriga, Sharmishtha, Vrishchika and Hamsa — names that have been read in this sky for thousands of years.", 15))
	v.add_child(UI.divider())
	for h in hunts:
		v.add_child(UI.label("•  %s  ·  %s" % [str(h.get("name", "")), str(h.get("western", ""))], 14, G.MUTED))
	v.add_child(UI.spacer(false, false))
	var row := UI.hbox(8)
	v.add_child(row)
	var back := UI.button("Back to the lab", true, 17)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(func(): Router.go("res://scenes/Lab.tscn"))
	row.add_child(back)
	var atlas := UI.ghost_button("Free sky", 15)
	atlas.pressed.connect(func(): Router.go("res://scenes/Atlas.tscn"))
	row.add_child(atlas)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			_pressed = true
			_looked = false
			_press_pos = mb.position
			_last_pos = mb.position
		else:
			if _pressed and not _looked:
				_pick_at(mb.position)
			_pressed = false
	elif event is InputEventMouseMotion and _pressed:
		var mm := event as InputEventMouseMotion
		if not _looked and mm.position.distance_to(_press_pos) > 8.0:
			_looked = true
		if _looked:
			cam.rotation.y -= mm.relative.x * 0.004
			cam.rotation.x = clampf(cam.rotation.x - mm.relative.y * 0.004, -1.1, 1.1)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			_pressed = true
			_looked = false
			_press_pos = st.position
			_last_pos = st.position
		else:
			if _pressed and not _looked:
				_pick_at(st.position)
			_pressed = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if not _looked and sd.position.distance_to(_press_pos) > 10.0:
			_looked = true
		if _looked:
			cam.rotation.y -= sd.relative.x * 0.004
			cam.rotation.x = clampf(cam.rotation.x - sd.relative.y * 0.004, -1.1, 1.1)


func _show_learn() -> void:
	G.show_briefing("stars")


func _on_resize() -> void:
	_build_ui()
	_update_ui()
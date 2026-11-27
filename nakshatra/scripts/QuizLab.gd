extends Node3D
## Sky Riddles: fourteen questions, no timer, an explanation for every answer.

var sky: SkyDome
var cam: Camera3D
var ui_root: Control
var questions: Array = []
var index := 0
var score := 0
var answered := false
var chosen := -1
var started := false
var finished := false
var wrong: Array = []
var answers: Array = []
# Which exhibit each riddle belongs to. A wrong answer offers a one-tap route
# back to the exact lesson that explains it — assessment that closes the loop.
const QUIZ_TOPICS := [
	"moon", "scale", "scale", "stars", "seasons", "moon", "scale",
	"stars", "scale", "moon", "flares", "blackhole", "flares", "blackhole",
]
const TOPIC_SCENES := {
	"moon": "res://scenes/MoonLab.tscn",
	"stars": "res://scenes/StarLab.tscn",
	"scale": "res://scenes/ScaleLab.tscn",
	"seasons": "res://scenes/SeasonLab.tscn",
	"flares": "res://scenes/SolarLab.tscn",
	"blackhole": "res://scenes/BlackHoleLab.tscn",
}
var content_box: VBoxContainer
var panel: PanelContainer
var progress_label: Label
var page_scroll: ScrollContainer
# Options are shuffled at render time. A fixed key — even a balanced A,B,C,D
# cycle — is learnable in one pass and turns the check into a pattern game.
var _order: Array[int] = []
var _correct_display := -1
var _order_index := -1
var _shuffle_gen := 0
var _order_gen := -1


func _ready() -> void:
	questions = G.content.get("quiz", [])
	_build_world()
	_build_ui()
	_render()
	get_viewport().size_changed.connect(_on_resize)
	set_process(true)
	G.maybe_briefing(ui_root, "quiz")
	var args := OS.get_cmdline_user_args()
	if args.has("--quiz-autostart") or args.has("--quiz-answer"):
		started = true
		_render()
	if args.has("--quiz-answer"):
		_choose(_correct_display)
	if args.has("--quiz-result"):
		started = true
		finished = true
		score = questions.size()
		index = maxi(0, questions.size() - 1)
		_render()
	if args.has("--quiz-review"):
		_load_review_state()
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		if typeof(search) == TYPE_STRING and str(search).contains("quiz=review"):
			_load_review_state()


func _load_review_state() -> void:
	# QA/demo helper: renders the second look with four wrong answers.
	started = true
	finished = true
	score = questions.size() - 4
	index = maxi(0, questions.size() - 1)
	answers.clear()
	wrong.clear()
	for i in questions.size():
		var q: Dictionary = questions[i]
		var opts: Array = q.get("options", [])
		var correct := int(q.get("answer", 0))
		var ok := i >= 4
		var chosen := correct if ok else (correct + 1) % maxi(opts.size(), 1)
		answers.append({
			"n": i + 1,
			"q": str(q.get("q", "")),
			"chosen": str(opts[chosen]) if chosen < opts.size() else "",
			"correct": str(opts[correct]) if correct < opts.size() else "",
			"ok": ok,
			"why": str(q.get("why", "")),
			"topic": str(QUIZ_TOPICS[i]) if i < QUIZ_TOPICS.size() else "",
		})
		if not ok:
			wrong.append({
				"q": str(q.get("q", "")),
				"answer": str(opts[correct]),
				"why": str(q.get("why", "")),
				"topic": str(QUIZ_TOPICS[i]) if i < QUIZ_TOPICS.size() else "",
			})
	_render()


func _build_world() -> void:
	cam = Camera3D.new()
	cam.fov = 60.0
	cam.current = true
	add_child(cam)
	cam.position = Vector3(0, 2, 10)
	cam.look_at(Vector3(0, 3.0, 0), Vector3.UP)

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 104.0
	add_child(sky)
	sky.set_modern_lines(true)
	sky.set_nakshatra_lines(false)
	var lm := sky.modern_lines.material_override as ShaderMaterial
	if lm:
		lm.set_shader_parameter("alpha", 0.35)
	if sky.env and sky.env.environment:
		sky.env.environment.ambient_light_energy = 0.35


func _build_ui() -> void:
	if ui_root:
		ui_root.queue_free()
	ui_root = Control.new()
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

	ui_root.add_child(UI.print_frame(16))

	var outer := UI.margin(UI.pad() + 4, 22, UI.pad() + 4, 14)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(outer)
	var col := UI.vbox(0)
	outer.add_child(col)
	col.add_child(_top_bar())

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	page_scroll = scroll

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(center)
	panel = UI.panel(int(clampf(UI.viewport_size().x * 0.035, 18.0, 30.0)), 0.94)
	panel.custom_minimum_size = Vector2(minf(820, UI.viewport_size().x - UI.pad() * 2 - 8), 0)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(panel)
	content_box = UI.vbox(11)
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(content_box)
	ui_root.add_child(UI.grain(0.045))
	_render()


func _top_bar() -> Control:
	progress_label = UI.micro("", Color(G.GOLD, 0.9), 9)
	var acts: Array = []
	if not UI.is_compact():
		acts.append({"text": "LESSON", "fn": func(): G.show_briefing("quiz")})
		acts.append({"text": "SKY ATLAS", "fn": func(): Router.go("res://scenes/Atlas.tscn")})
	return UI.app_bar("Sky Riddles", "ASSESSMENT  ·  NO TIMER", "res://scenes/Lab.tscn", acts, Vector2i(-1, -1), "THE SKY LAB", progress_label)


func _segments(done: int, total: int, current: int = -1, on_paper: bool = false) -> HBoxContainer:
	var h := UI.hbox(3)
	h.add_theme_constant_override("separation", 3)
	for i in total:
		var seg := ColorRect.new()
		var full := (G.INK if on_paper else G.GOLD)
		var col := Color(full, 0.8) if i < done else (G.VERMILION if i == current else Color(full, 0.28))
		seg.color = col
		seg.custom_minimum_size = Vector2(0, 3)
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(seg)
	return h


func _render() -> void:
	if content_box == null:
		return
	for c in content_box.get_children():
		c.queue_free()
	if not started:
		_render_intro()
	elif not finished:
		_render_question()
	else:
		_render_results()
	if progress_label:
		if not started:
			progress_label.text = ""
		elif UI.is_compact():
			progress_label.text = "%d/%d" % [mini(index + 1, questions.size()), questions.size()]
		else:
			progress_label.text = "%02d / %02d" % [mini(index + 1, questions.size()), questions.size()]
	if page_scroll:
		page_scroll.set_deferred("scroll_vertical", 0)


func _render_intro() -> void:
	content_box.add_child(UI.micro("SKY NOTE 07  ·  A FRIENDLY CHECK", Color(G.GOLD, 0.9), 9))

	var cols := UI.hbox(26)
	content_box.add_child(cols)
	var left := UI.vbox(10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	left.add_child(UI.heading("%d riddles about the sky." % questions.size(), 40))
	left.add_child(UI.label("No timer. Every answer is explained — so a wrong guess becomes a lesson.", 16, Color(G.MUTED, 0.95)))
	left.add_child(UI.label("Use the same %d questions before and after a lesson to see how much has changed. This is a learning check, not an exam." % questions.size(), 15, G.CREAM))
	if G.quiz_best > 0:
		left.add_child(UI.label("Your best so far: %d / %d" % [G.quiz_best, questions.size()], 14, G.GOLD, "body_med"))

	var right := UI.vbox(0)
	right.custom_minimum_size = Vector2(196, 0)
	right.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	cols.add_child(right)
	var slip := UI.paper(16)
	slip.custom_minimum_size = Vector2(196, 0)
	right.add_child(slip)
	var sv := UI.vbox(6)
	slip.add_child(sv)
	sv.add_child(UI.micro("SKY NOTE 07", Color("8a6a3c"), 8))
	var big := UI.display("%d" % questions.size(), 58, G.INK)
	big.custom_minimum_size.y = 58
	sv.add_child(big)
	sv.add_child(UI.micro("RIDDLES", G.INK_SOFT, 9))
	sv.add_child(_segments(maxi(G.quiz_best, 0), questions.size(), -1, true))
	sv.add_child(UI.rule(Color(G.INK, 0.2), 1))
	sv.add_child(UI.micro("NO TIMER", G.INK_SOFT, 8))
	sv.add_child(UI.micro("EVERY ANSWER EXPLAINED", G.INK_SOFT, 8))
	sv.add_child(UI.micro("PRE- AND POST-TEST", G.INK_SOFT, 8))
	sv.add_child(UI.micro("CLASS 6–9", Color("8a6a3c"), 8))

	content_box.add_child(UI.rule(Color(G.GOLD, 0.22), 1))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_child(gap)

	var row := UI.hbox(14)
	content_box.add_child(row)
	var start := UI.button("Start the riddles   ›", true, 17)
	start.custom_minimum_size = Vector2(240, 46)
	start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	start.pressed.connect(func():
		Sfx.play("lantern")
		started = true
		index = 0
		score = 0
		wrong.clear()
		answers.clear()
		answered = false
		chosen = -1
		_shuffle_gen += 1
		_render())
	row.add_child(start)
	var lesson := UI.link_button("READ THE LESSON FIRST", 10)
	lesson.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lesson.pressed.connect(func(): G.show_briefing("quiz"))
	row.add_child(lesson)

	content_box.add_child(UI.micro("THE EXHIBITS ARE ALWAYS OPEN — IF A QUESTION SURPRISES YOU, VISIT THE MATCHING LAB AFTERWARDS", Color(G.MUTED, 0.82), 8))


func _render_question() -> void:
	if index >= questions.size():
		_render_results()
		return
	var q: Dictionary = questions[index]
	var head := UI.hbox(8)
	content_box.add_child(head)
	head.add_child(UI.micro("QUESTION %02d" % (index + 1), Color(G.GOLD, 0.9), 9))
	head.add_child(UI.spacer())
	head.add_child(UI.micro("%d CORRECT" % score, Color(G.MUTED, 0.8), 8))
	content_box.add_child(_segments(index, questions.size(), index))

	var ql := UI.heading(str(q.get("q", "")), 30 if not UI.is_compact() else 24)
	content_box.add_child(ql)
	var gap_q := Control.new()
	gap_q.custom_minimum_size = Vector2(0, 3)
	gap_q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_child(gap_q)
	content_box.add_child(UI.rule(Color(G.GOLD, 0.18), 1))
	content_box.add_child(UI.micro("CHOOSE ONE ANSWER", Color(G.MUTED, 0.9), 8))

	var letters := ["A", "B", "C", "D"]
	var options: Array = q.get("options", [])
	if _order_index != index or _order_gen != _shuffle_gen or _order.size() != options.size():
		_order.clear()
		for i in options.size():
			_order.append(i)
		_order.shuffle()
		_order_index = index
		_order_gen = _shuffle_gen
		_correct_display = _order.find(int(q.get("answer", 0)))
	for i in _order.size():
		var b := UI.button("%s      %s" % [letters[i], str(options[_order[i]])], false, 16)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(0, 50)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var osb := StyleBoxFlat.new()
		osb.bg_color = Color(0.05, 0.04, 0.085, 0.92)
		osb.border_color = Color(G.CREAM, 0.35)
		osb.set_border_width_all(2)
		osb.set_corner_radius_all(0)
		osb.content_margin_left = 20
		osb.content_margin_right = 20
		osb.content_margin_top = 10
		osb.content_margin_bottom = 10
		osb.shadow_color = Color(0, 0, 0, 0.4)
		osb.shadow_size = 1
		osb.shadow_offset = Vector2(3, 3)
		var ohov := osb.duplicate() as StyleBoxFlat
		ohov.bg_color = G.GOLD
		ohov.border_color = G.INK
		ohov.shadow_offset = Vector2(5, 5)
		var opress := osb.duplicate() as StyleBoxFlat
		opress.bg_color = G.VERMILION
		opress.border_color = G.INK
		opress.shadow_offset = Vector2(1, 1)
		b.add_theme_stylebox_override("normal", osb)
		b.add_theme_stylebox_override("hover", ohov)
		b.add_theme_stylebox_override("pressed", opress)
		b.add_theme_stylebox_override("focus", UI.focus_ring())
		b.add_theme_color_override("font_hover_color", G.INK)
		b.add_theme_color_override("font_pressed_color", G.CREAM)
		b.pressed.connect(_choose.bind(i))
		if answered:
			b.disabled = true
			if i == _correct_display:
				_style_answer(b, G.TEAL)
			elif i == chosen:
				_style_answer(b, G.ROSE)
		content_box.add_child(b)

	if answered:
		var correct := _correct_display == chosen
		var verdict_box := PanelContainer.new()
		var vsb := StyleBoxFlat.new()
		vsb.bg_color = Color((G.TEAL if correct else G.VERMILION), 0.08)
		vsb.border_color = Color((G.TEAL if correct else G.VERMILION), 0.55)
		vsb.set_border_width_all(0)
		vsb.border_width_left = 3
		vsb.set_corner_radius_all(1)
		vsb.content_margin_left = 14
		vsb.content_margin_right = 14
		vsb.content_margin_top = 12
		vsb.content_margin_bottom = 12
		verdict_box.add_theme_stylebox_override("panel", vsb)
		content_box.add_child(verdict_box)
		var vv := UI.vbox(5)
		verdict_box.add_child(vv)
		vv.add_child(UI.label("That's right." if correct else "Not quite — here is the idea.", 16, G.TEAL if correct else G.ROSE, "body_med"))
		vv.add_child(UI.rich(str(q.get("why", "")), 15, G.CREAM))
		var next := UI.button("Final score   ›" if index >= questions.size() - 1 else "Next riddle   ›", true, 16)
		next.custom_minimum_size = Vector2(210, 44)
		next.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		next.pressed.connect(_next)
		content_box.add_child(next)
	else:
		pass


func _style_answer(b: Button, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.1)
	sb.border_color = Color(color, 0.7)
	sb.set_border_width_all(1)
	sb.border_width_left = 4
	sb.set_corner_radius_all(1)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_color_override("font_disabled_color", color)


func _choose(i: int) -> void:
	if answered:
		return
	answered = true
	chosen = i
	var q: Dictionary = questions[index]
	var opts: Array = q.get("options", [])
	var correct_original := int(q.get("answer", -1))
	var picked_original := int(_order[i]) if i >= 0 and i < _order.size() else -1
	var picked_text := str(opts[picked_original]) if picked_original >= 0 and picked_original < opts.size() else ""
	var correct_text := str(opts[correct_original]) if correct_original >= 0 and correct_original < opts.size() else ""
	var topic := str(QUIZ_TOPICS[index]) if index < QUIZ_TOPICS.size() else ""
	answers.append({
		"n": index + 1,
		"q": str(q.get("q", "")),
		"chosen": picked_text,
		"correct": correct_text,
		"ok": picked_original == correct_original,
		"why": str(q.get("why", "")),
		"topic": topic,
	})
	if picked_original == correct_original:
		score += 1
		Sfx.play("success")
		Juice.stamp("CORRECT", G.TEAL)
	else:
		Sfx.play("soft_error")
		Juice.stamp("NOT QUITE — READ ON", G.VERMILION, G.CREAM)
		wrong.append({
			"q": str(q.get("q", "")),
			"answer": correct_text,
			"why": str(q.get("why", "")),
			"topic": topic,
		})
	_render()


func _next() -> void:
	if index >= questions.size() - 1:
		finished = true
		G.record_quiz(score, questions.size())
		Sfx.play("chime")
		_render()
		return
	index += 1
	answered = false
	chosen = -1
	_render()


func _render_results() -> void:
	var total := questions.size()
	var pct := int(round(100.0 * score / maxf(total, 1)))
	content_box.add_child(UI.micro("YOUR SKY  ·  RESULT", Color(G.GOLD, 0.9), 9))
	var score_row := UI.hbox(8)
	content_box.add_child(score_row)
	var big := UI.label("%d" % score, 60, G.CREAM, "body_med")
	big.custom_minimum_size.y = 70
	big.autowrap_mode = TextServer.AUTOWRAP_OFF
	score_row.add_child(big)
	var of := UI.heading("/ %d" % total, 24, Color(G.MUTED, 0.8))
	of.autowrap_mode = TextServer.AUTOWRAP_OFF
	of.size_flags_vertical = Control.SIZE_SHRINK_END
	of.custom_minimum_size.y = 34
	score_row.add_child(of)
	content_box.add_child(_segments(score, total))
	content_box.add_child(UI.label("%d%%  ·  %s" % [pct, _message(pct)], 16, G.CREAM))
	if G.quiz_prev >= 0 and G.quiz_attempts > 1:
		# Pre-test / post-test is a classroom promise; show the change, not just
		# the score. A student who took it before the lesson can see the gain.
		var delta := score - G.quiz_prev
		var change := "no change"
		if delta > 0:
			change = "+%d since last attempt" % delta
		elif delta < 0:
			change = "%d since last attempt" % delta
		var line := UI.label("Previous: %d / %d  ·  %s" % [G.quiz_prev, total, change], 13, Color(G.TEAL if delta >= 0 else G.GOLD, 0.95))
		content_box.add_child(line)
	if pct >= 60:
		content_box.add_child(UI.pill("Passed  ·  Sky Keeper", G.TEAL, 12))
	else:
		content_box.add_child(UI.pill("Not yet — visit a lab and try again", G.GOLD, 12))
	if answers.size() > 0:
		# Assessment should name the exhibit to revisit, not just the score.
		var by_topic := {}
		for a in answers:
			var t := str(a.get("topic", ""))
			if t == "":
				continue
			if not by_topic.has(t):
				by_topic[t] = [0, 0]
			by_topic[t][1] += 1
			if bool(a.get("ok", false)):
				by_topic[t][0] += 1
		if not by_topic.is_empty():
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 6)
			flow.add_theme_constant_override("v_separation", 6)
			content_box.add_child(flow)
			flow.add_child(UI.micro("BY EXHIBIT", Color(G.GOLD, 0.85), 8))
			for t in by_topic:
				var got: int = int(by_topic[t][0])
				var n: int = int(by_topic[t][1])
				var label := str(G.module_info(t).get("title", t))
				var col := G.TEAL if got == n else (G.GOLD if got * 2 >= n else G.VERMILION)
				flow.add_child(UI.pill("%s  %d/%d" % [label, got, n], col, 11))
	content_box.add_child(UI.rule(Color(G.GOLD, 0.2), 1))
	var save := UI.ghost_button("Save this attempt  ↓", 12)
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save.custom_minimum_size = Vector2(0, 38)
	save.pressed.connect(_save_results_csv)
	content_box.add_child(save)
	var note := UI.micro("CSV  ·  OPENS IN EXCEL OR SHEETS  ·  STAYS ON THIS DEVICE", Color(G.MUTED, 0.7), 8)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_box.add_child(note)

	if wrong.size() > 0:
		var rev := UI.vbox(8)
		content_box.add_child(rev)
		rev.add_child(UI.micro("A SECOND LOOK", Color(G.VERMILION, 0.95), 9))
		for w in wrong:
			var box := UI.vbox(3)
			rev.add_child(box)
			box.add_child(UI.label(str(w["q"]), 14, G.CREAM))
			box.add_child(UI.label("Answer: " + str(w["answer"]), 12, G.TEAL, "body_med"))
			box.add_child(UI.label(str(w["why"]), 13, G.MUTED))
			var topic := str(w.get("topic", ""))
			if TOPIC_SCENES.has(topic):
				var title := str(G.module_info(topic).get("title", topic))
				var go := UI.ghost_button("Revise: " + title + "  ›", 11)
				go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
				go.pressed.connect(func():
					Sfx.play("click")
					Router.go(TOPIC_SCENES[topic]))
				box.add_child(go)
			rev.add_child(UI.rule(Color(G.GOLD, 0.12), 1))
	else:
		content_box.add_child(UI.label("Every answer correct. That is a sky well read.", 15, G.TEAL))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 4)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_box.add_child(gap)
	var compact := UI.is_compact()
	var row: BoxContainer = UI.vbox(8) if compact else UI.hbox(10)
	content_box.add_child(row)
	var again := UI.button("Try again", false, 15)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	again.custom_minimum_size = Vector2(0 if compact else 150, 44)
	again.pressed.connect(func():
		started = false
		finished = false
		index = 0
		score = 0
		wrong.clear()
		answers.clear()
		answered = false
		chosen = -1
		_shuffle_gen += 1
		_render())
	row.add_child(again)
	var back := UI.button("Back to the lab   ›", true, 15)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	back.custom_minimum_size = Vector2(0 if compact else 210, 44)
	back.pressed.connect(func(): Router.go("res://scenes/Lab.tscn"))
	row.add_child(back)



func _csv_cell(value: String) -> String:
	return "\"" + value.replace("\"", "\"\"") + "\""


func _save_results_csv() -> void:
	# A teacher can keep the attempt without an account or a server: one row per
	# riddle, with the chosen answer, the correct one, and the explanation.
	var total := questions.size()
	var lines: Array[String] = [
		"Nakshatra — Sky Riddles",
		"Name," + _csv_cell(G.player_name),
		"Date," + _csv_cell(Time.get_datetime_string_from_system(false, true)),
		"Score,%d,%d" % [score, total],
		"",
		"#," + ",".join(PackedStringArray(["Question", "Your answer", "Correct answer", "Result", "Explanation", "Revise"])),
	]
	for a in answers:
		lines.append("%d,%s,%s,%s,%s,%s,%s" % [
			int(a.get("n", 0)),
			_csv_cell(str(a.get("q", ""))),
			_csv_cell(str(a.get("chosen", ""))),
			_csv_cell(str(a.get("correct", ""))),
			_csv_cell("correct" if bool(a.get("ok", false)) else "wrong"),
			_csv_cell(str(a.get("why", ""))),
			_csv_cell(str(a.get("topic", ""))),
		])
	var csv := "\n".join(PackedStringArray(lines)) + "\n"
	var fname := "nakshatra-riddles.csv"
	if OS.has_feature("web"):
		var b64 := Marshalls.raw_to_base64(csv.to_utf8_buffer())
		var js := "(function(){var s=atob('%s');var a=new Uint8Array(s.length);for(var i=0;i<s.length;i++)a[i]=s.charCodeAt(i);var b=new Blob([a],{type:'text/csv;charset=utf-8'});var u=URL.createObjectURL(b);var e=document.createElement('a');e.href=u;e.download='%s';document.body.appendChild(e);e.click();e.remove();setTimeout(function(){URL.revokeObjectURL(u);},1000);})()" % [b64, fname]
		JavaScriptBridge.eval(js, true)
	else:
		var path := "user://" + fname
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f:
			f.store_string(csv)
			f.close()
			if DisplayServer.get_name() != "headless":
				OS.shell_open(ProjectSettings.globalize_path(path))
	Sfx.play("chime")
	var toast := UI.micro("RESULTS SAVED", G.TEAL, 9)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_box.add_child(toast)
	toast.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.6)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(toast.queue_free)


func _message(pct: int) -> String:
	if pct >= 90:
		return "A sky keeper in the making."
	if pct >= 70:
		return "Strong — a few ideas to revisit."
	if pct >= 50:
		return "A good start. The labs will fill the gaps."
	return "Every wrong answer is a door. Try a lab, then come back."


func _process(delta: float) -> void:
	if G.reduced_motion:
		return
	if sky:
		sky.sidereal_deg = fmod(sky.sidereal_deg + delta * 0.4, 360.0)
		sky.set_sidereal(sky.sidereal_deg)


func _on_resize() -> void:
	_build_ui()
	_render()

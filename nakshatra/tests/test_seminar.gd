extends Node
## Headless contract test for the seminar deck. Run:
##   godot --headless --path . tests/TestSeminar.tscn

var _failures: Array[String] = []


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok  ", message)
	else:
		_failures.append(message)
		print("  FAIL  ", message)


func _ready() -> void:
	var packed := load("res://scenes/Seminar.tscn")
	_check(packed != null, "Seminar scene loads")
	if packed == null:
		get_tree().quit(1)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	_check(scene.slides.size() >= 10, "has at least 10 slides (got %d)" % scene.slides.size())
	_check(scene.slides.size() == 12, "has the expected 12 slides")

	var required := ["kicker", "title", "subtitle", "bullets", "note", "image", "seconds"]
	var images_ok := true
	var labs_ok := true
	var notes_ok := true
	var bullets_ok := true
	for i in scene.slides.size():
		var s: Dictionary = scene.slides[i]
		for key in required:
			_check(s.has(key), "slide %d has %s" % [i + 1, key])
		var img := str(s.get("image", ""))
		_check(img != "" and ResourceLoader.exists(img), "slide %d image exists" % (i + 1))
		if not (img != "" and ResourceLoader.exists(img)):
			images_ok = false
		var lab := str(s.get("lab", ""))
		if lab != "" and not ResourceLoader.exists(lab):
			labs_ok = false
			print("  missing lab: ", lab)
		if str(s.get("note", "")).length() < 80:
			notes_ok = false
		if (s.get("bullets", []) as Array).size() < 3:
			bullets_ok = false

	_check(images_ok, "every slide image resolves")
	_check(labs_ok, "every attached live scene resolves")
	_check(notes_ok, "every slide has a substantive speaker note")
	_check(bullets_ok, "every slide has at least three talking points")

	var title: String = str(scene.slides[0].get("title", ""))
	_check(title == "Nakshatra", "slides begin with the title slide")
	_check(str(scene.slides[scene.slides.size() - 1].get("title", "")) != "", "closing slide has a title")

	scene._go(3, true)
	await get_tree().process_frame
	_check(scene.index == 3, "keyboard/go_to lands on slide 4")
	_check(scene.title_lbl.text == str(scene.slides[3].get("title", "")), "title label follows the slide")

	scene._go(11, true)
	await get_tree().process_frame
	_check(scene.index == 11, "can reach the final slide")

	var checks: Array = scene.preflight_results()
	var failed := 0
	for row in checks:
		if not bool(row.get("ok", true)):
			failed += 1
			print("  preflight:", row.get("label", "?"), "=", row.get("value", "?"))
	_check(failed == 0, "all presenter preflight rows are green (%d rows)" % checks.size())
	_check(checks.size() >= 10, "preflight reports a full checklist")

	scene._toggle_notes()
	await get_tree().process_frame
	_check(scene.cue_panel != null and scene.cue_visible, "N opens a one-sentence cue")
	scene._toggle_notes()
	await get_tree().process_frame
	_check(scene.cue_panel == null, "N closes the cue")
	scene._show_notes()
	await get_tree().process_frame
	_check(scene._notes_panel != null and scene.notes_visible, "Shift+N opens the full speaker notes")
	scene._hide_notes()
	await get_tree().process_frame
	_check(scene._notes_panel == null, "full speaker notes close")

	scene._go(10, true)
	await get_tree().process_frame
	scene._show_figure()
	await get_tree().process_frame
	_check(scene._figure_overlay != null, "figure enlarges on I / click")
	scene._close_figure()
	await get_tree().process_frame
	_check(scene._figure_overlay == null, "figure overlay closes")

	_check(scene._num(8879) == "8,879", "number formatting uses Indian-style grouping")
	_check(scene._num(100000) == "1,00,000", "number formatting handles lakhs")

	if _failures.is_empty():
		print("TEST PASS seminar slides=%d" % scene.slides.size())
		get_tree().quit(0)
	else:
		print("TEST FAIL seminar failures=%d" % _failures.size())
		get_tree().quit(1)

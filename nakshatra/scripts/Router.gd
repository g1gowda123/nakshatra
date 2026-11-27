extends CanvasLayer
## Fade-to-black scene router that survives scene changes.
##
## The scene swap itself is synchronous inside Godot, but the first build of the
## hill compiles shaders and can take several seconds on a school laptop. The
## fade is therefore also a status card: "Opening the Sky Lab", not a black void.

var _fade: ColorRect
var _title: Label
var _sub: Label
var _busy := false

signal scene_changed


func _ready() -> void:
	layer = 128
	_fade = ColorRect.new()
	_fade.color = Color(0.016, 0.024, 0.051, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.modulate.a = 0.0
	_fade.visible = false
	add_child(_fade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.add_child(center)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)

	var mark := Label.new()
	mark.text = "◈"
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.add_theme_font_size_override("font_size", 28)
	mark.add_theme_color_override("font_color", Color(0.85, 0.70, 0.42))
	box.add_child(mark)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 18)
	_title.add_theme_color_override("font_color", Color(0.95, 0.91, 0.84))
	box.add_child(_title)

	_sub = Label.new()
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.add_theme_font_size_override("font_size", 11)
	_sub.add_theme_color_override("font_color", Color(0.60, 0.65, 0.75))
	box.add_child(_sub)


func _title_for(path: String) -> String:
	var file := path.get_file().get_basename()
	var names := {
		"Lab": "OPENING THE SKY LAB",
		"MoonLab": "OPENING THE MOON'S MASK",
		"StarLab": "OPENING THREAD THE STARS",
		"ScaleLab": "OPENING THE LONG ROAD",
		"SeasonLab": "OPENING THE TURNING YEAR",
		"SolarLab": "OPENING THE SOLAR STORM LAB",
		"BlackHoleLab": "OPENING THE BLACK HOLE LAB",
		"QuizLab": "OPENING SKY RIDDLES",
		"Atlas": "OPENING THE SKY ATLAS",
		"Finale": "OPENING THE LANTERN FESTIVAL",
		"Seminar": "OPENING THE SEMINAR DECK",
	}
	return str(names.get(file, "OPENING " + file.to_upper()))


func _show_status(path: String) -> void:
	_title.text = _title_for(path)
	_sub.text = "First visit can take a few seconds while the sky compiles."
	_title.modulate.a = 0.0
	_sub.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_title, "modulate:a", 1.0, 0.35)
	tw.tween_property(_sub, "modulate:a", 1.0, 0.35).set_delay(0.08)


func go(path: String, hold: float = 0.0) -> void:
	if _busy:
		return
	_busy = true
	_fade.visible = true
	_show_status(path)
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Router: could not open %s (error %d)" % [path, err])
		_title.text = "COULD NOT OPEN THIS ROOM"
		_sub.text = "Press Escape to return. The deck and the labs are still in the pack."
		_busy = false
		return
	await get_tree().process_frame
	# change_scene_to_file is deferred; on a slow school laptop the new scene's
	# _ready (shader compile, hill build) can take a moment. Keep the status card
	# up until the scene reports ready, with a hard cap so a broken scene cannot
	# leave the presenter stranded on a black screen.
	var deadline := Time.get_ticks_msec() + 8000
	while Time.get_ticks_msec() < deadline:
		var scene := get_tree().current_scene
		if scene != null and scene.is_node_ready():
			break
		await get_tree().process_frame
	await get_tree().process_frame
	scene_changed.emit()
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	_fade.visible = false
	_busy = false


func quick_go(path: String) -> void:
	_busy = true
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Router: could not open %s (error %d)" % [path, err])
		_busy = false
		return
	await get_tree().process_frame
	_busy = false
	scene_changed.emit()

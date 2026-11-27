extends Node
## Dev-only capture harness for the Seminar deck's figures.
## Loads a scene, optionally prepares a demo state, waits for the renderer and
## saves a PNG. Never exported.
##
##   godot --path . tests/DeckCapture.tscn -- res://scenes/Lab.tscn out.png 3 1280 720 --skip-briefing
##   godot --path . tests/DeckCapture.tscn -- res://scenes/Finale.tscn out.png 3 1280 720 --demo
##   godot --path . tests/DeckCapture.tscn -- res://scenes/SolarLab.tscn out.png 3 1280 720 --flare
##   godot --path . tests/DeckCapture.tscn -- res://scenes/QuizLab.tscn out.png 3 1280 720 --quiz

var _target := ""
var _out := ""
var _wait := 3.0
var _size := Vector2i(1280, 720)
var _demo := false
var _flare := false
var _quiz := false
var _skip_briefing := false
var _reset := false
var _reset_only := false
var _demo_only := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_reset = args.has("--reset")
	_reset_only = args.has("--reset-only")
	_demo_only = args.has("--demo-only")
	if _reset or _reset_only:
		G.reset_progress()
	if _demo_only:
		G.unlock_all()
		print("[DeckCapture] demo state ready")
		get_tree().quit(0)
		return
	if _reset_only:
		print("[DeckCapture] progress reset")
		get_tree().quit(0)
		return
	if args.size() < 2:
		push_error("DeckCapture: need scene and output path")
		get_tree().quit(2)
		return
	_target = str(args[0])
	_out = str(args[1])
	if args.size() >= 3:
		_wait = float(args[2])
	if args.size() >= 5:
		_size = Vector2i(int(args[3]), int(args[4]))
	_demo = args.has("--demo")
	_flare = args.has("--flare")
	_quiz = args.has("--quiz")
	_skip_briefing = args.has("--skip-briefing")

	if _skip_briefing or _demo:
		for id in G.MODULES:
			G.briefing_seen[id] = true
	if _demo:
		G.unlock_all()

	if _size.x > 0 and _size.y > 0:
		DisplayServer.window_set_size(_size)
		get_window().size = _size
		get_tree().root.content_scale_size = _size

	var packed := load(_target)
	if packed == null:
		push_error("DeckCapture: cannot load " + _target)
		get_tree().quit(3)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)

	# The compositor may re-tile the window after the first resize; re-assert it
	# for a few seconds, exactly like tests/Capture.gd.
	var t := 0.0
	while t < minf(_wait, 4.0):
		await get_tree().create_timer(0.5).timeout
		t += 0.5
		if _size.x > 0 and _size.y > 0:
			DisplayServer.window_set_size(_size)
			get_window().size = _size
			get_tree().root.content_scale_size = _size

	if _flare and scene.has_method("_trigger_flare"):
		scene.stress = 80.0
		scene._trigger_flare()
		await get_tree().create_timer(0.9).timeout
	if _quiz and scene.has_method("_render"):
		scene.started = true
		scene.index = 0
		scene.answered = false
		scene._render()

	await get_tree().create_timer(0.35).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(_out)
	print("[DeckCapture] %s %s -> %s (err=%d)" % [_target, str(img.get_size()), _out, err])
	get_tree().quit(0)

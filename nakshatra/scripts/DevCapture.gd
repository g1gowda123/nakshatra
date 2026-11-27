extends Node
## Dev-only screenshot probe. No-ops unless --capture is passed on the command line.
## Usage:
##   godot --path . -- --screen=lab --capture --capture-name=hub \
##         --capture-size=1280x720 --capture-delay=2.0 --capture-out=/abs/path.png

var _armed := false
var _out := ""
var _delay := 2.0
var _size := Vector2i.ZERO
var _screen := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.has("--capture"):
		return
	_armed = true
	for a in args:
		if a.begins_with("--capture-name="):
			var name := a.get_slice("=", 1)
			_out = "/tmp/nakshatra_%s.png" % name
		elif a.begins_with("--capture-out="):
			_out = a.get_slice("=", 1)
		elif a.begins_with("--capture-delay="):
			_delay = float(a.get_slice("=", 1))
		elif a.begins_with("--capture-size="):
			var parts := a.get_slice("=", 1).split("x")
			if parts.size() == 2:
				_size = Vector2i(int(parts[0]), int(parts[1]))
		elif a.begins_with("--screen="):
			_screen = a.get_slice("=", 1)
	if _size != Vector2i.ZERO:
		DisplayServer.window_set_size(_size)
		get_tree().root.content_scale_size = _size
		await get_tree().process_frame
	_capture()


func _capture() -> void:
	await get_tree().create_timer(maxf(_delay, 0.1)).timeout
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := _out if _out != "" else "/tmp/nakshatra_capture.png"
	var err := img.save_png(path)
	print("[Capture] screen=%s size=%s -> %s (err=%d)" % [_screen, str(img.get_size()), path, err])
	get_tree().quit()

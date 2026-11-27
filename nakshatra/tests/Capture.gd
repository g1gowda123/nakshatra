extends Node
## Dev-only visual capture harness.
## Usage:
##   godot --path . tests/Capture.tscn -- res://scenes/Boot.tscn /abs/out.png [wait_seconds] [w] [h]
## Loads the target scene directly (bypassing Boot's route arg handling), waits for
## the renderer, then saves the viewport. Never exported with the game.

var _target := ""
var _out := ""
var _wait := 1.2


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2:
		_target = str(args[0])
		_out = str(args[1])
	if args.size() >= 3:
		_wait = float(args[2])
	if args.size() >= 5:
		var w := int(args[3])
		var h := int(args[4])
		DisplayServer.window_set_size(Vector2i(w, h))
		get_window().size = Vector2i(w, h)
	if _target == "" or _out == "":
		push_error("Capture: need scene path and output path")
		get_tree().quit(2)
		return
	var packed := load(_target)
	if packed == null:
		push_error("Capture: cannot load " + _target)
		get_tree().quit(3)
		return
	var scene: Node = packed.instantiate()
	add_child(scene)
	# The compositor may re-tile the window; re-assert the requested size late.
	if args.size() >= 5:
		var w := int(args[3])
		var h := int(args[4])
		var t := 0.0
		while t < minf(_wait, 4.0):
			await get_tree().create_timer(0.5).timeout
			t += 0.5
			DisplayServer.window_set_size(Vector2i(w, h))
			get_window().size = Vector2i(w, h)
	await get_tree().create_timer(maxf(_wait - 4.0, 0.2)).timeout
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_out)
	print("CAPTURE ", _out, " ", img.get_width(), "x", img.get_height())
	get_tree().quit()

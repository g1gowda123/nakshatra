extends CanvasLayer
## Fade-to-black scene router that survives scene changes.

var _fade: ColorRect
var _busy := false

signal scene_changed


func _ready() -> void:
	layer = 128
	_fade = ColorRect.new()
	_fade.color = Color(0.016, 0.024, 0.051, 1.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	_fade.visible = false
	add_child(_fade)


func go(path: String, hold: float = 0.0) -> void:
	if _busy:
		return
	_busy = true
	_fade.visible = true
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_SINE)
	await tw.finished
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	scene_changed.emit()
	var tw2 := create_tween()
	tw2.tween_property(_fade, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	await tw2.finished
	_fade.visible = false
	_busy = false


func quick_go(path: String) -> void:
	_busy = true
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	_busy = false
	scene_changed.emit()

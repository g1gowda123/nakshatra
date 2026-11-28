extends Node
## Locks the eclipse model: a tilted orbit misses; an aligned one hits;
## solar and lunar modes use the same threshold and the same content.

var _fail := 0


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		_fail += 1
		print("  FAIL  ", msg)


func _ready() -> void:
	var scene: Control = load("res://scenes/EclipseLab.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.35).timeout

	_check(scene.mode == "solar", "opens on the solar eclipse")
	scene.tilt = 4.0
	scene._update_state()
	_check(not scene._hit(), "a 4° tilt misses Earth")
	scene.tilt = 0.0
	scene._update_state()
	_check(scene._hit(), "an aligned orbit lands the umbra")

	scene._set_mode("lunar")
	await get_tree().process_frame
	_check(scene.mode == "lunar", "lunar mode switches")
	_check(scene.tilt == 4.0, "switching resets the tilt to the everyday miss")
	scene.tilt = 0.0
	scene._update_state()
	_check(scene._hit(), "the lunar shadow also needs alignment")

	var e: Dictionary = G.content.get("eclipse", {})
	_check(not str(e.get("big_idea", "")).is_empty(), "eclipse big idea exists")
	_check(not str(e.get("solar", "")).is_empty(), "solar explanation exists")
	_check(not str(e.get("lunar", "")).is_empty(), "lunar explanation exists")

	if _fail == 0:
		print("TEST PASS eclipse")
	else:
		print("TEST FAIL eclipse failures=", _fail)
	get_tree().quit(0 if _fail == 0 else 1)

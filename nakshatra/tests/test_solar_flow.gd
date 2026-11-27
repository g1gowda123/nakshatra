extends Node
## Headless contract test for the Solar Storm Lab sequence.
## Run: godot --headless --path . tests/TestSolarFlow.tscn

var _fail := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fail += 1
		print("  FAIL  ", msg)


func _ready() -> void:
	var scene = load("res://scenes/SolarLab.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.5).timeout

	scene.stress = 80.0
	scene._trigger_flare()
	await get_tree().create_timer(4.2).timeout
	print("TEST1 stage=", scene.stage, " active=", scene.flare_active, " fb=", scene.feedback)
	_check(scene.stage == 1, "unshielded flare reaches stage 1")
	_check(not scene.flare_active, "flare animation finishes")
	_check(str(scene.feedback).to_lower().contains("shield"), "feedback asks for the shield")

	scene.shield_on = true
	scene.shield_mesh.visible = true
	scene._trigger_flare()
	await get_tree().create_timer(4.2).timeout
	print("TEST2 stage=", scene.stage, " active=", scene.flare_active, " fb=", scene.feedback, " options=", scene.options_box.get_child_count())
	_check(scene.stage == 2, "shielded flare reaches stage 2")
	_check(not scene.flare_active, "shielded flare animation finishes")
	_check(scene.options_box.get_child_count() > 0, "challenge options appear")

	await get_tree().create_timer(0.5).timeout
	print("TEST3 stage=", scene.stage, " options=", scene.options_box.get_child_count())
	_check(scene.stage == 2, "stage stays stable after the animation")

	if _fail == 0:
		print("TEST PASS solar")
		get_tree().quit(0)
	else:
		print("TEST FAIL solar failures=%d" % _fail)
		get_tree().quit(1)

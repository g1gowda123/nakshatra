extends Node
## Headless contract test for the Moon Lab's phase model and feedback.
## Run: godot --headless --path . tests/TestMoonFlow.tscn

var _fail := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fail += 1
		print("  FAIL  ", msg)


func _ready() -> void:
	var scene = load("res://scenes/MoonLab.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.4).timeout

	var expected := {
		0.0: "Full Moon",
		90.0: "First Quarter",
		140.0: "Waxing Crescent",
		180.0: "New Moon",
		220.0: "Waning Crescent",
	}
	for deg in expected:
		scene._set_angle(float(deg))
		var p: Dictionary = scene._phase()
		print("ANGLE ", deg, " -> ", p["name"], " illum=", p["illum"], " waxing=", p["waxing"])
		_check(str(p["name"]) == str(expected[deg]), "phase at %d is %s" % [deg, expected[deg]])

	# Travelling "later" must move from waning, through new, into waxing, with
	# the lit fraction rising after new moon. This is the defect the audit found.
	scene.challenge_index = 0
	var last_illum := -1.0
	var monotonic := true
	for i in 9:
		scene._set_angle(200.0 - i * 10.0)
		var p: Dictionary = scene._phase()
		if i > 3 and float(p["illum"]) < last_illum - 0.001:
			monotonic = false
		last_illum = float(p["illum"])
		if i == 4:
			_check(bool(p["waxing"]), "waxing begins after new moon when stepping later")
	_check(monotonic, "lit fraction rises after new moon")

	# Challenge feedback must use the actual geometry note, not the fallback.
	scene._set_angle(140.0)
	scene.challenge_index = 0
	scene._check()
	await get_tree().create_timer(1.2).timeout
	print("CHECK feedback=", scene.feedback_label.text)
	_check(scene.challenge_index == 1, "waxing crescent advances the challenge")
	_check(scene.feedback_label.text.contains("growing"), "correct answer explains the geometry")
	_check(scene.feedback_label.text.contains("fallback") == false, "no generic fallback on correct answer")
	_check(scene._why("full") != "", "full moon has an explanation")
	_check(scene._phase_note("Waning Crescent").to_lower().contains("sunrise"), "waning crescent note teaches rise time")
	_check(scene.phase_label.text == "—", "phase name is hidden while a challenge is active")

	if _fail == 0:
		print("TEST PASS moon")
		get_tree().quit(0)
	else:
		print("TEST FAIL moon failures=%d" % _fail)
		get_tree().quit(1)

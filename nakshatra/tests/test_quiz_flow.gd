extends Node
## Headless contract test for the quiz: shuffled options, correct mapping,
## the revise-topic table, and the pre/post comparison.
## Run: godot --headless --path . tests/TestQuizFlow.tscn

var _fail := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fail += 1
		print("  FAIL  ", msg)


func _ready() -> void:
	var scene = load("res://scenes/QuizLab.tscn").instantiate()
	add_child(scene)
	await get_tree().create_timer(0.4).timeout
	scene.started = true
	scene.finished = false
	scene.index = 0
	scene.score = 0
	scene.wrong.clear()
	scene._render()
	await get_tree().process_frame

	var q: Dictionary = scene.questions[0]
	var opts: Array = q.get("options", [])
	var correct_text := str(opts[int(q.get("answer", 0))])
	_check(scene._order.size() == opts.size(), "option order covers every option")
	_check(scene._correct_display == scene._order.find(int(q.get("answer", 0))), "correct display index is remapped")
	_check(str(opts[scene._order[scene._correct_display]]) == correct_text, "displayed correct option keeps its text")

	var seen := {}
	for i in 30:
		scene._shuffle_gen += 1
		scene._order_index = -1
		scene._render_question()
		await get_tree().process_frame
		seen[scene._correct_display] = true
		_check(scene._correct_display == scene._order.find(int(q.get("answer", 0))), "mapping stays correct on reshuffle %d" % i)
	_check(seen.size() >= 2, "the correct answer moves between positions")
	print("  positions seen=", seen.keys())

	scene._shuffle_gen += 1
	scene._order_index = -1
	scene._render_question()
	await get_tree().process_frame
	scene.answered = false
	scene.chosen = -1
	scene.score = 0
	scene._choose(scene._correct_display)
	_check(scene.score == 1, "choosing the mapped correct option scores")
	_check(scene.wrong.is_empty(), "correct choice adds no wrong entry")
	_check(scene.answers.size() == 1, "every answer is recorded for the CSV report")
	if not scene.answers.is_empty():
		_check(str(scene.answers[0]["correct"]) == correct_text, "CSV row stores the correct answer")
		_check(bool(scene.answers[0]["ok"]), "CSV row marks the correct attempt")

	scene.wrong.clear()
	scene.answered = false
	scene.chosen = -1
	scene._shuffle_gen += 1
	scene._order_index = -1
	scene._render_question()
	await get_tree().process_frame
	var wrong_pick: int = (int(scene._correct_display) + 1) % int(scene._order.size())
	scene._choose(wrong_pick)
	_check(scene.score == 1, "wrong choice does not add a point")
	_check(scene.wrong.size() == 1, "wrong choice is recorded once")
	_check(scene.answers.size() == 2, "wrong choice is also added to the CSV report")
	if scene.answers.size() >= 2:
		_check(not bool(scene.answers[1]["ok"]), "CSV row marks the wrong attempt")
	if not scene.wrong.is_empty():
		_check(str(scene.wrong[0]["answer"]) == correct_text, "review stores the real correct answer")
		_check(str(scene.wrong[0]["topic"]) == str(scene.QUIZ_TOPICS[0]), "review stores the exhibit topic")
	_check(scene.QUIZ_TOPICS.size() == scene.questions.size(), "every riddle has a revise topic")

	if _fail == 0:
		print("TEST PASS quiz")
		get_tree().quit(0)
	else:
		print("TEST FAIL quiz failures=%d" % _fail)
		get_tree().quit(1)

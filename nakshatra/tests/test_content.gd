extends Node
## Headless contract test for data/content.json and the sky data.
## Run: godot --headless --path . tests/TestContent.tscn

var _fail: Array[String] = []


func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok  ", msg)
	else:
		_fail.append(msg)
		print("  FAIL  ", msg)


func _ready() -> void:
	var f := FileAccess.open("res://data/content.json", FileAccess.READ)
	_ok(f != null, "content.json exists")
	if f == null:
		get_tree().quit(1)
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	_ok(typeof(d) == TYPE_DICTIONARY, "content.json parses")
	if typeof(d) != TYPE_DICTIONARY:
		get_tree().quit(1)
		return

	var modules: Dictionary = d.get("modules", {})
	_ok(modules.size() == 7, "7 learning modules")
	for id in ["moon", "stars", "scale", "seasons", "flares", "blackhole", "quiz"]:
		var m: Dictionary = modules.get(id, {})
		_ok(not m.is_empty(), "module '%s' exists" % id)
		_ok(str(m.get("title", "")) != "", "module '%s' has a title" % id)
		var lesson: Dictionary = m.get("lesson", {})
		_ok(str(lesson.get("big_idea", "")) != "", "module '%s' has a big idea" % id)
		_ok((lesson.get("paragraphs", []) as Array).size() >= 2, "module '%s' has lesson paragraphs" % id)
		var art := str(m.get("art", ""))
		_ok(art != "" and ResourceLoader.exists(art), "module '%s' art resolves" % id)

	var quiz: Array = d.get("quiz", [])
	_ok(quiz.size() == 14, "14 Sky Riddles")
	var seen := {}
	for i in quiz.size():
		var q: Dictionary = quiz[i]
		var text := str(q.get("q", ""))
		_ok(text != "" and not seen.has(text), "question %d is unique and non-empty" % (i + 1))
		seen[text] = true
		var opts: Array = q.get("options", [])
		_ok(opts.size() >= 3, "question %d has options" % (i + 1))
		var ans := int(q.get("answer", -1))
		_ok(ans >= 0 and ans < opts.size(), "question %d answer index is valid" % (i + 1))
		_ok(str(q.get("why", "")) != "", "question %d has an explanation" % (i + 1))

	_ok((d.get("planets", []) as Array).size() == 8, "8 planet fact sheets")
	_ok((d.get("wonders", []) as Array).size() == 10, "10 Field Guide cards")
	_ok(not str((d.get("eclipse", {}) as Dictionary).get("big_idea", "")).is_empty(), "eclipse bonus note has content")
	_ok((d.get("star_hunts", []) as Array).size() == 5, "5 constellation hunts")
	_ok((d.get("scale_riddles", []) as Array).size() == 4, "4 scale riddles")
	_ok((d.get("story", []) as Array).size() == 4, "4 story panels")

	var seminar: Dictionary = d.get("seminar", {})
	var slides: Array = seminar.get("slides", [])
	_ok(slides.size() == 12, "12 seminar slides")
	for i in slides.size():
		var s: Dictionary = slides[i]
		_ok(str(s.get("title", "")) != "", "slide %d title" % (i + 1))
		_ok((s.get("bullets", []) as Array).size() >= 3, "slide %d has 3+ bullets" % (i + 1))
		_ok(str(s.get("note", "")).length() >= 80, "slide %d note is substantial" % (i + 1))
		var img := str(s.get("image", ""))
		_ok(img != "" and ResourceLoader.exists(img), "slide %d image resolves" % (i + 1))
		var lab := str(s.get("lab", ""))
		if lab != "":
			_ok(ResourceLoader.exists(lab), "slide %d lab resolves" % (i + 1))

	var stars = JSON.parse_string(FileAccess.get_file_as_string("res://data/sky/stars.json"))
	_ok(typeof(stars) == TYPE_DICTIONARY and (stars.get("hips", []) as Array).size() == 8879, "8,879 stars in the compact catalogue")
	var cons = JSON.parse_string(FileAccess.get_file_as_string("res://data/sky/constellations.json"))
	_ok(typeof(cons) == TYPE_ARRAY and (cons as Array).size() == 88, "88 constellation figures")
	var naks = JSON.parse_string(FileAccess.get_file_as_string("res://data/sky/nakshatras.json"))
	_ok(typeof(naks) == TYPE_ARRAY and (naks as Array).size() == 28, "28 nakshatra figures")

	if _fail.is_empty():
		print("TEST PASS content")
		get_tree().quit(0)
	else:
		print("TEST FAIL content failures=%d" % _fail.size())
		get_tree().quit(1)

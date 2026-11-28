extends Node
## Global state: language, learning progress, quiz results, small save file.

signal progress_changed
signal language_changed

const MODULES := ["moon", "stars", "scale", "seasons", "flares", "blackhole", "quiz"]

const BG := Color("050505")
const BG_SOFT := Color("101010")
const PANEL := Color(0.025, 0.025, 0.025, 0.94)
const GOLD := Color("c6ff00")
const GOLD_SOFT := Color("9ecb00")
const CREAM := Color("f2f2ee")
const MUTED := Color("8c8c88")
const TEAL := Color("c6ff00")
const ROSE := Color("ff3b30")
const VERMILION := Color("ff3b30")
const LINE := Color(0.949, 0.949, 0.933, 0.16)
const PAPER := Color("f2f2ee")
const PAPER_DEEP := Color("d8d8d2")
const INK := Color("080808")
const INK_SOFT := Color("5a5a56")
const PAPER_ACCENT := Color("3d4a00")

const SAVE_PATH := "user://nakshatra_save.json"

const VERSION := "1.7.1"
const EDITION := "Studio edition"

var visited: Dictionary = {}
var quiz_best: int = 0
var quiz_last: int = 0
var quiz_prev: int = -1
var quiz_attempts: int = 0
var lang: String = "en"          # "en" or "kn"
var story_seen: bool = false
var player_name: String = ""
var sound_on: bool = true
var reduced_motion: bool = false
var briefing_seen: Dictionary = {}
var pending_guide := false
var content: Dictionary = {}
var seminar_index: int = 0
var seminar_elapsed: float = 0.0
var seminar_return: bool = false
# The exhibit that just finished, consumed by the hub for its light-up beat.
var last_completed := ""

## Kannada key terms (UI shows these under English labels in Kannada mode).
const KANNADA := {
	"moon": "ಚಂದ್ರ", "stars": "ನಕ್ಷತ್ರಗಳು", "scale": "ಸೌರಮಂಡಲ", "seasons": "ಋತುಗಳು",
	"quiz": "ಪ್ರಶ್ನೆಗಳು", "flares": "ಸೌರ ಚಂಡಮಾರುತ", "blackhole": "ಕಪ್ಪು ಕುಳಿ",
	"sky": "ಆಕಾಶ", "earth": "ಭೂಮಿ", "sun": "ಸೂರ್ಯ",
	"new_moon": "ಅಮಾವಾಸ್ಯೆ", "full_moon": "ಹುಣ್ಣಿಮೆ", "quarter": "ಅರ್ಧ ಚಂದ್ರ",
	"crescent": "ಅರ್ಧಚಂದ್ರಾಕೃತಿ", "gibbous": "ಪೂರ್ಣಕ್ಕಿಂತ ಕಡಿಮೆ",
	"constellation": "ನಕ್ಷತ್ರಪುಂಜ", "planet": "ಗ್ರಹ", "orbit": "ಕಕ್ಷೆ",
	"light_minute": "ಬೆಳಕಿನ ನಿಮಿಷ", "tilt": "ಅಕ್ಷದ ಓರೆ", "solstice": "ಅಯನಾಂತ",
	"equinox": "ವಿಷುವತ್ ಸಂಕ್ರಾಂತಿ", "day": "ಹಗಲು", "night": "ರಾತ್ರಿ",
	"telescope": "ದೂರದರ್ಶಕ", "lantern": "ಕೈದೀಪ", "sky_keeper": "ಆಕಾಶ ರಕ್ಷಕ",
	"flare": "ಸೌರ ಜ್ವಾಲೆ", "event_horizon": "ಘಟನೆ ಕ್ಷಿತಿಜ", "aurora": "ಧ್ರುವ ಜ್ಯೋತಿ",
}


func _ready() -> void:
	load_game()
	if OS.has_feature("web"):
		var prefers = JavaScriptBridge.eval("window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches", true)
		if prefers is bool and bool(prefers):
			reduced_motion = true
	load_content()
	_apply_content_scale()
	get_tree().root.size_changed.connect(_apply_content_scale)


var _last_css := Vector2.ZERO


func _css_size() -> Vector2:
	if OS.has_feature("web"):
		var w = JavaScriptBridge.eval("window.innerWidth || 0", true)
		var h = JavaScriptBridge.eval("window.innerHeight || 0", true)
		if float(w) > 0.0 and float(h) > 0.0:
			return Vector2(float(w), float(h))
	var win := DisplayServer.window_get_size()
	return Vector2(maxi(win.x, 1), maxi(win.y, 1))


func _apply_content_scale() -> void:
	var css := _css_size()
	if css.x < 100.0 or css.y < 100.0:
		return
	if css.distance_to(_last_css) < 1.0:
		return
	_last_css = css
	var logical_w: float
	if css.y > css.x:
		logical_w = clampf(css.x, 360.0, 600.0)   # phones and tablets, portrait
	else:
		logical_w = clampf(css.x, 360.0, 1600.0)  # laptop / projector / phone landscape
	var logical_h := logical_w * css.y / css.x
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(int(round(logical_w)), int(round(logical_h)))
	print("[Scale] css=", css, " logical=", root.content_scale_size)


func refresh_content_scale() -> void:
	# Scenes that fix their own canvas (the seminar deck) call this before
	# leaving, so the next scene gets the responsive game scale back.
	_last_css = Vector2.ZERO
	_apply_content_scale()


func _unhandled_input(event: InputEvent) -> void:
	# Godot will not start keyboard navigation from "nothing focused", so a
	# laptop user pressing Tab on a fresh screen got no response at all. Seed
	# focus on the first Tab; after that the engine owns the focus chain.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		if get_viewport().gui_get_focus_owner() == null:
			focus_first()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_BACKSPACE:
		if seminar_return:
			var owner := get_viewport().gui_get_focus_owner()
			if owner is LineEdit or owner is TextEdit:
				return
			get_viewport().set_input_as_handled()
			Router.go("res://scenes/Seminar.tscn")


func focus_first(scene: Node = null) -> void:
	var root: Node = scene if scene != null else get_tree().current_scene
	if root == null:
		return
	var controls := root.find_children("*", "Button", true, false)
	for c in controls:
		var b := c as Button
		if b and b.is_visible_in_tree() and not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus()
			return


func load_content() -> void:
	var f := FileAccess.open("res://data/content.json", FileAccess.READ)
	if f:
		var parsed = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) == TYPE_DICTIONARY:
			content = parsed


func ui_host() -> Node:
	## The full-screen Control that overlays the current scene. Prefer it over
	## the Router canvas layer: a Control parented to a CanvasLayer does not
	## inherit the viewport rect, so modals anchored inside it collapse to zero.
	var scene := get_tree().current_scene
	if scene:
		for c in scene.get_children():
			if c is Control and c.size.x > 100.0 and c.size.y > 100.0:
				return c
	return get_tree().root


func show_briefing(id: String, on_start: Callable = Callable()) -> void:
	Briefing.show(ui_host(), id, on_start)


func maybe_briefing(host: Node, id: String) -> void:
	if briefing_seen.has(id):
		return
	briefing_seen[id] = true
	if host is Control and host.size.x > 100.0:
		Briefing.show(host, id)
	else:
		show_briefing(id)


func show_field_guide() -> void:
	FieldGuide.show(ui_host())


func module_info(id: String) -> Dictionary:
	return content.get("modules", {}).get(id, {})


func t(en: String, kn: String) -> String:
	return kn if lang == "kn" else en


func kn_term(key: String) -> String:
	return KANNADA.get(key, "")


func set_lang(value: String) -> void:
	lang = value if value in ["en", "kn"] else "en"
	save_game()
	language_changed.emit()


func complete(id: String) -> void:
	if not visited.get(id, false):
		visited[id] = true
		last_completed = id
		save_game()
		progress_changed.emit()


func is_done(id: String) -> bool:
	return visited.get(id, false)


func done_count() -> int:
	var n := 0
	for id in MODULES:
		if visited.get(id, false):
			n += 1
	return n


func all_done() -> bool:
	return done_count() == MODULES.size()


func reset_progress() -> void:
	visited.clear()
	quiz_best = 0
	quiz_last = 0
	quiz_prev = -1
	quiz_attempts = 0
	seminar_index = 0
	seminar_elapsed = 0.0
	save_game()
	progress_changed.emit()


func unlock_all() -> void:
	## Presenter helper: light every lantern and set the quiz best to the full
	## paper count, so the finale and certificate are ready for a live demo.
	for id in MODULES:
		visited[id] = true
	var total := int((content.get("quiz", []) as Array).size())
	quiz_best = total
	quiz_last = total
	save_game()
	progress_changed.emit()


func record_quiz(score: int, total: int) -> void:
	quiz_prev = quiz_last if quiz_attempts > 0 else -1
	quiz_last = score
	quiz_attempts += 1
	if score > quiz_best:
		quiz_best = score
	if score >= int(ceil(total * 0.6)):
		complete("quiz")
	save_game()
	progress_changed.emit()


func save_game() -> void:
	var data := {
		"visited": visited,
		"quiz_best": quiz_best,
		"quiz_last": quiz_last,
		"quiz_prev": quiz_prev,
		"quiz_attempts": quiz_attempts,
		"lang": lang,
		"story_seen": story_seen,
		"name": player_name,
		"sound": sound_on,
		"reduced_motion": reduced_motion,
		"seminar_index": seminar_index,
		"seminar_elapsed": seminar_elapsed,
		"briefing_seen": briefing_seen,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	visited = parsed.get("visited", {})
	quiz_best = int(parsed.get("quiz_best", 0))
	quiz_last = int(parsed.get("quiz_last", 0))
	quiz_prev = int(parsed.get("quiz_prev", -1))
	quiz_attempts = int(parsed.get("quiz_attempts", 0))
	lang = str(parsed.get("lang", "en"))
	story_seen = bool(parsed.get("story_seen", false))
	player_name = str(parsed.get("name", ""))
	sound_on = bool(parsed.get("sound", true))
	reduced_motion = bool(parsed.get("reduced_motion", false))
	seminar_index = int(parsed.get("seminar_index", 0))
	seminar_elapsed = float(parsed.get("seminar_elapsed", 0.0))
	briefing_seen = parsed.get("briefing_seen", {})


func star_rating() -> int:
	return done_count()

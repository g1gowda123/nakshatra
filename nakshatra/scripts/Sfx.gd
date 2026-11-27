extends Node
## Tiny audio director. Streams are generated originals bundled with the game.

var _ambient: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _gesture_seen := false

const SFX := {
	"click": "res://audio/click.wav",
	"tick": "res://audio/tick.wav",
	"chime": "res://audio/chime.wav",
	"success": "res://audio/success.wav",
	"soft_error": "res://audio/soft_error.wav",
	"lantern": "res://audio/lantern.wav",
	"whoosh": "res://audio/whoosh.wav",
}


func _ready() -> void:
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "Ambient"
	add_child(_ambient)
	var amb = _load_stream("res://audio/ambient.ogg")
	if amb:
		if amb is AudioStreamOggVorbis:
			(amb as AudioStreamOggVorbis).loop = true
		_ambient.stream = amb
		_ambient.volume_db = -18.0
		_ambient.finished.connect(func(): if G.sound_on: _ambient.play())
		if G.sound_on:
			_ambient.play()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		add_child(p)
		_pool.append(p)


func apply_sound_setting() -> void:
	# The menu toggle used to only flip a bool: the ambient bed kept playing
	# over a "Sound: Off" label. Keep the one setting authoritative.
	if _ambient == null or _ambient.stream == null:
		return
	if G.sound_on:
		if not _ambient.playing:
			_ambient.play()
	else:
		_ambient.stop()


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


func _input(event: InputEvent) -> void:
	if _gesture_seen:
		return
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if pressed:
		_gesture_seen = true
		if G.sound_on and _ambient and _ambient.stream:
			_ambient.play()


func play(id: String, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	if not G.sound_on:
		return
	var path: String = SFX.get(id, "")
	if path == "":
		return
	var stream := _load_stream(path)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = clamp(pitch, 0.7, 1.4)
	p.play()


func set_ambient_volume(db: float) -> void:
	if _ambient:
		_ambient.volume_db = db

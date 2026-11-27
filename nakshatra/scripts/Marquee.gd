extends Control
## A single-line ticker. Two copies of the text chase each other so the strip
## can loop without a visible seam. It is decoration, never a control.

var text := ""
var color := Color.WHITE
var font_size := 14
var speed := 34.0
var _a: Label
var _b: Label
var _w := 0.0
var _x := 0.0


func setup(value: String, ink: Color = G.GOLD, fs: int = 14, px_speed: float = 34.0) -> void:
	text = value
	color = ink
	font_size = fs
	speed = px_speed
	_ready_labels()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(0, float(font_size) * 1.55)
	if _a == null:
		_ready_labels()


func _ready_labels() -> void:
	if is_node_ready() == false:
		return
	if _a != null:
		return
	_a = _make()
	_b = _make()
	add_child(_a)
	add_child(_b)
	_a.position = Vector2.ZERO
	_b.position = Vector2(_a.size.x + 42.0, 0)
	_w = _a.size.x + 42.0


func _make() -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", UI.display_font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = l.get_minimum_size()
	return l


func _process(delta: float) -> void:
	if G.reduced_motion or _a == null:
		return
	_x -= delta * speed
	if _x <= -_w:
		_x += _w
	_a.position.x = _x
	_b.position.x = _x + _w
	_a.size = _a.get_minimum_size()
	_b.size = _b.get_minimum_size()
	_w = maxf(_a.size.x + 42.0, _b.size.x + 42.0)

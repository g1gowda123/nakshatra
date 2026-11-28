class_name BrandMark
extends Control
## The almanac mark: a four-point star inside a hairline ring with two ticks.

var ink: Color = Design.GOLD
var weight := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s <= 2.0:
		return
	var c := size * 0.5
	var r := s * 0.46
	draw_arc(c, r, 0, TAU, 48, Color(ink, 0.55), maxf(1.0, s * 0.035), true)
	# Two small ticks at the equator, like a sighting ring.
	draw_line(Vector2(c.x - r - s * 0.06, c.y), Vector2(c.x - r + s * 0.1, c.y), Color(ink, 0.8), maxf(1.0, s * 0.03))
	draw_line(Vector2(c.x + r - s * 0.1, c.y), Vector2(c.x + r + s * 0.06, c.y), Color(ink, 0.8), maxf(1.0, s * 0.03))
	# A slender four-point star.
	var pts := PackedVector2Array([
		c + Vector2(0, -r * 0.72), c + Vector2(r * 0.17, -r * 0.17),
		c + Vector2(r * 0.72, 0), c + Vector2(r * 0.17, r * 0.17),
		c + Vector2(0, r * 0.72), c + Vector2(-r * 0.17, r * 0.17),
		c + Vector2(-r * 0.72, 0), c + Vector2(-r * 0.17, -r * 0.17),
	])
	draw_colored_polygon(pts, ink)
	draw_circle(c, r * 0.09, Color(Design.PHOSPHOR, 0.9))

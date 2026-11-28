class_name MechanicalButton
extends Button
## A Button with the cheap physical details that make Cassette Futurism read
## as hardware instead of a flat mobile control: a top highlight, a bottom
## shadow line, and four screw dots in the corners.
##
## The styleboxes still come from UI.gd. This class only adds the touches a
## StyleBoxFlat cannot draw.

var screw_color := Design.INK
var highlight_color := Color(Design.CREAM, 0.34)
var shadow_line_color := Color(0, 0, 0, 0.42)


func _draw() -> void:
	if size.x < 20.0 or size.y < 20.0:
		return
	# Top inner highlight: the light catching the upper edge of the switch.
	draw_line(Vector2(7, 4), Vector2(size.x - 7, 4), highlight_color, 3.0)
	# Bottom inner shadow: the switch sitting in its well.
	draw_line(Vector2(7, size.y - 4), Vector2(size.x - 7, size.y - 4), shadow_line_color, 3.0)
	# Round controls get a circular bevel; rectangular keys get a square one.
	var circular := absf(size.x - size.y) < maxf(4.0, minf(size.x, size.y) * 0.12)
	if circular:
		var c := size * 0.5
		var rr := minf(size.x, size.y) * 0.5 - 4.0
		draw_arc(c, rr, 0.0, TAU, 64, Color(Design.BEZEL_EDGE, 0.58), 3.0)
		draw_arc(c, rr, -PI * 0.15, PI * 0.35, 32, highlight_color, 3.0)
		draw_arc(c, rr, PI * 0.65, PI * 1.15, 32, shadow_line_color, 3.0)
		for ang in [-45.0, 45.0, 135.0, 225.0]:
			var a := deg_to_rad(ang)
			var p := c + Vector2(cos(a), sin(a)) * rr
			draw_circle(p, 3.4, Color(screw_color, 0.92))
	else:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), Color(Design.BEZEL_EDGE, 0.55), false, 3.0)
		var pts := [
			Vector2(5, 5),
			Vector2(size.x - 5, 5),
			Vector2(5, size.y - 5),
			Vector2(size.x - 5, size.y - 5),
		]
		for p in pts:
			draw_circle(p, 4.0, Color(screw_color, 0.98))

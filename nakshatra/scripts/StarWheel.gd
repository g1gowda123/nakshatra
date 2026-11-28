extends Control
## The hub dial in Cassette Futurism.
##
## A warm charcoal instrument panel, one thick amber bezel, seven phosphor arcs,
## and four screws in the corners. A completed exhibit reads as a lit tape
## segment; an unvisited one reads as a quiet rail. The exhibit buttons are
## separate MechanicalButtons placed by Lab.gd.

var done := []
var accent := Color(Design.GOLD, 0.46)
var phosphor := Color(Design.PHOSPHOR, 0.62)
var quiet := Color(Design.CREAM, 0.20)


func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.40

	# The instrument housing: one warm, slightly translucent panel.
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(Design.BEZEL, 0.88)
	psb.border_color = Design.BEZEL_EDGE
	psb.set_border_width_all(3)
	psb.set_corner_radius_all(14)
	psb.shadow_color = Color(0, 0, 0, 0.45)
	psb.shadow_size = 12
	psb.shadow_offset = Vector2(0, 6)
	draw_style_box(psb, Rect2(Vector2.ZERO, size))

	# Four screws, one in each corner of the housing.
	for p in [
		Vector2(10, 10),
		Vector2(size.x - 10, 10),
		Vector2(10, size.y - 10),
		Vector2(size.x - 10, size.y - 10),
	]:
		draw_circle(p, 4.0, Color(Design.INK, 0.85))
		draw_circle(p + Vector2(0, -1), 2.0, Color(Design.CREAM, 0.22))

	# The outer bezel: a thick amber ring with a faint phosphor hairline.
	draw_arc(c, r * 1.06, 0.0, TAU, 128, Color(accent, 0.46), 8.0)
	draw_arc(c, r * 0.98, 0.0, TAU, 128, Color(phosphor, 0.14), 2.0)

	# A soft bed for the centre note so the title never fights the panel.
	draw_circle(c, r * 0.68, Color(0.045, 0.040, 0.034, 0.55))

	# Seven evenly spaced arcs with breathing room between them.
	for i in 7:
		var seg := TAU / 7.0
		var start := -PI * 0.5 + seg * float(i) + 0.045
		var end := start + seg - 0.09
		var lit := i < done.size() and bool(done[i])
		draw_arc(c, r * 0.94, start, end, 48, phosphor if lit else quiet, 8.0 if lit else 2.0)

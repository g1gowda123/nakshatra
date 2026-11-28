extends Control
## The hub dial: one quiet brass ring, seven exhibit arcs, and a soft dark
## bed behind the centre note. Filled arcs are completed lanterns; hollow arcs
## are still waiting. The nodes themselves are icon Buttons placed by Lab.gd.

var done := []
var accent := Color(G.GOLD, 0.52)
var quiet := Color(G.CREAM, 0.20)


func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.40
	# A soft bed for the centre note so the title never fights the 3D hill.
	draw_circle(c, r * 0.66, Color(0.02, 0.03, 0.07, 0.50))
	# One outer ring, no tick dots, no second ring.
	draw_arc(c, r, 0.0, TAU, 128, Color(accent, 0.28), 1.6)
	# Seven evenly spaced arcs with breathing room between them.
	for i in 7:
		var seg := TAU / 7.0
		var start := -PI * 0.5 + seg * float(i) + 0.045
		var end := start + seg - 0.09
		var lit := i < done.size() and bool(done[i])
		draw_arc(c, r * 0.94, start, end, 48, accent if lit else quiet, 6.0 if lit else 2.0)

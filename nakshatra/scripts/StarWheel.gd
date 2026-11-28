extends Control
## The hub wheel: seven exhibit arcs around a brass ring. Filled arcs are lit
## lanterns; hollow arcs are still waiting. The nodes themselves are Buttons
## placed by Lab.gd on top of this drawing.

var done := []
var accent := Color(G.GOLD, 0.48)
var quiet := Color(G.CREAM, 0.16)
var node_color := Color(G.GOLD, 0.60)


func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.40
	draw_circle(c, r * 0.62, Color(0.02, 0.03, 0.07, 0.55))
	draw_arc(c, r, 0.0, TAU, 128, Color(accent, 0.24), 1.4)
	draw_arc(c, r * 0.76, 0.0, TAU, 128, Color(accent, 0.14), 1.0)
	for i in 28:
		var a := TAU * float(i) / 28.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r, 1.8, Color(G.CREAM, 0.18))
	for i in 7:
		var start := -PI * 0.5 + TAU * float(i) / 7.0
		var end := start + TAU / 7.0
		var lit := i < done.size() and bool(done[i])
		draw_arc(c, r * 0.94, start + 0.03, end - 0.03, 48, accent if lit else quiet, 5.0 if lit else 2.0)
		var mid := (start + end) * 0.5
		draw_circle(c + Vector2(cos(mid), sin(mid)) * r * 0.94, 5.0, node_color if lit else Color(G.CREAM, 0.24))

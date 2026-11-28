extends Control
## A quiet brass ring used behind the wordmark: 28 nakshatra points, seven
## larger lantern points, and two hairline circles. No text, no glow.

var ring_color := Color(G.GOLD, 0.22)
var point_color := Color(G.CREAM, 0.18)
var node_color := Color(G.GOLD, 0.42)


func _draw() -> void:
	if size.x < 80.0 or size.y < 80.0:
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.40
	draw_arc(c, r, 0.0, TAU, 128, ring_color, 1.6)
	draw_arc(c, r * 0.78, 0.0, TAU, 128, Color(ring_color, 0.55), 1.0)
	for i in 28:
		var a := TAU * float(i) / 28.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r, 2.0, point_color)
	for i in 7:
		var a := -PI * 0.5 + TAU * float(i) / 7.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.94, 5.0, node_color)

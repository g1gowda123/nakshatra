extends Control
## Cassette Futurism ornament: a quiet tape shell behind the wordmark.
##
## This is not a lesson element. It is the *interface's* signature object: a
## warm, chunky cassette shell with two reels, a tape window, and four screws.
## It says "this screen is hardware" before a single word is read.

var shell := Design.BEZEL
var edge := Design.BEZEL_EDGE
var window := Color(0.045, 0.040, 0.034, 0.92)
var reel := Design.CREAM
var hub := Design.PHOSPHOR


func _draw() -> void:
	if size.x < 120.0 or size.y < 80.0:
		return
	var r := Rect2(Vector2.ZERO, size)
	var corner := 8.0

	# Cassette shell.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(shell, 0.96)
	sb.border_color = Color(Design.CREAM, 0.50)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(corner))
	draw_style_box(sb, r)

	# Label strip: the paper sticker on the shell.
	var strip := Rect2(r.position + Vector2(18, 14), Vector2(r.size.x - 36, r.size.y * 0.24))
	var strip_sb := StyleBoxFlat.new()
	strip_sb.bg_color = Color(Design.PAPER, 0.16)
	strip_sb.border_color = Color(Design.INK, 0.22)
	strip_sb.set_border_width_all(1)
	strip_sb.set_corner_radius_all(3)
	draw_style_box(strip_sb, strip)
	var font := UI.mono_font()
	var label := "SIDE A"
	var fs := int(strip.size.y * 0.40)
	draw_string(font, strip.position + Vector2(0, strip.size.y * 0.74), label, HORIZONTAL_ALIGNMENT_CENTER, strip.size.x, fs, Color(Design.CREAM, 0.86))

	# Tape window between the reels.
	var win := Rect2(r.position + Vector2(r.size.x * 0.24, r.size.y * 0.40), Vector2(r.size.x * 0.52, r.size.y * 0.22))
	var win_sb := StyleBoxFlat.new()
	win_sb.bg_color = window
	win_sb.border_color = Color(Design.PHOSPHOR, 0.52)
	win_sb.set_border_width_all(1)
	win_sb.set_corner_radius_all(4)
	draw_style_box(win_sb, win)
	draw_rect(Rect2(win.position + Vector2(6, 5), Vector2(win.size.x - 12, win.size.y - 10)), Color(Design.GOLD, 0.14), false, 1.0)

	# Two reels, slightly different sizes like a real cassette.
	var cy := r.position.y + r.size.y * 0.66
	var left_c := Vector2(r.position.x + r.size.x * 0.30, cy)
	var right_c := Vector2(r.position.x + r.size.x * 0.70, cy)
	for c in [left_c, right_c]:
		var rr := minf(r.size.x, r.size.y) * 0.14
		draw_circle(c, rr, Color(window, 1.0))
		draw_arc(c, rr, 0.0, TAU, 64, Color(Design.PHOSPHOR, 0.48), 2.0, true)
		draw_circle(c, rr * 0.42, Color(hub, 0.48))
		draw_circle(c, rr * 0.16, Color(reel, 0.55))
	# A dark tape run between the hubs, with a little wound tape on each spool.
	draw_line(left_c + Vector2(0, 0), right_c + Vector2(0, 0), Color(Design.INK, 0.78), 5.0)
	draw_arc(left_c, minf(r.size.x, r.size.y) * 0.14, -0.35, 0.35, 24, Color(Design.INK, 0.55), 4.0)
	draw_arc(right_c, minf(r.size.x, r.size.y) * 0.14, PI - 0.35, PI + 0.35, 24, Color(Design.INK, 0.55), 4.0)

	# Four screws, one in each corner.
	for corner_pos in [
		Vector2(r.position.x + 12, r.position.y + 12),
		Vector2(r.position.x + r.size.x - 12, r.position.y + 12),
		Vector2(r.position.x + 12, r.position.y + r.size.y - 12),
		Vector2(r.position.x + r.size.x - 12, r.position.y + r.size.y - 12),
	]:
		draw_circle(corner_pos, 2.4, Color(edge, 0.9))

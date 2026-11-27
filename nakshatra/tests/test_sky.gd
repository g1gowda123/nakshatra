extends Node

var fails := 0


func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok  ", msg)
	else:
		fails += 1
		print("  FAIL  ", msg)


func _alt(sky: SkyDome, ra: float, dec: float) -> float:
	var dir: Vector3 = (sky.global_transform.basis * StarDB.dir_from_ra_dec(ra, dec)).normalized()
	return rad_to_deg(asin(clampf(dir.y, -1.0, 1.0)))


func _ready() -> void:
	var sky := SkyDome.new()
	sky.latitude_deg = 13.0
	sky.set_sidereal(17.0)
	add_child(sky)
	# At LST 01h at 13 N, these are the textbook altitudes. A mirror or a
	# half-turn in the horizon transform moves every one of them.
	var cases := [
		["Polaris", 37.95, 89.26, 13.2],
		["Capella", 79.2, 46.0, 28.5],
		["Sirius", 101.3, -16.7, 1.6],
		["Fomalhaut", 344.4, -29.6, 37.1],
		["Arcturus", 213.9, 19.2, -53.8],
	]
	for c in cases:
		var alt := _alt(sky, float(c[1]), float(c[2]))
		_check(absf(alt - float(c[3])) < 0.8, "%s altitude %.1f (want %.1f)" % [c[0], alt, float(c[3])])
	# The south celestial pole must be below the horizon at 13 N.
	_check(_alt(sky, 0.0, -90.0) < -12.0, "south celestial pole is below the horizon")
	if fails == 0:
		print("TEST PASS sky")
	else:
		print("TEST FAIL sky ", fails)
	get_tree().quit(0 if fails == 0 else 1)

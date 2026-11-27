extends Node
## Loads the real sky: HYG star catalogue + Stellarium constellation/nakshatra lines.

var hips: PackedInt32Array = PackedInt32Array()
var ra: PackedFloat32Array = PackedFloat32Array()      # degrees
var dec: PackedFloat32Array = PackedFloat32Array()     # degrees
var mag: PackedFloat32Array = PackedFloat32Array()
var ci: PackedFloat32Array = PackedFloat32Array()
var star_names: PackedStringArray = PackedStringArray()
var star_cons: PackedStringArray = PackedStringArray()
var dist: PackedFloat32Array = PackedFloat32Array()

var constellations: Array = []
var constellations_by_id: Dictionary = {}
var nakshatras: Array = []
var named_stars: Array = []

var ready_ok := false


func _ready() -> void:
	load_all()


func load_all() -> void:
	var d = _read_json("res://data/sky/stars.json")
	if typeof(d) == TYPE_DICTIONARY:
		hips = PackedInt32Array(_to_int_array(d.get("hips", [])))
		ra = PackedFloat32Array(_to_float_array(d.get("ra", [])))
		dec = PackedFloat32Array(_to_float_array(d.get("dec", [])))
		mag = PackedFloat32Array(_to_float_array(d.get("mag", [])))
		ci = PackedFloat32Array(_to_float_array(d.get("ci", [])))
		star_names = PackedStringArray(d.get("names", []))
		star_cons = PackedStringArray(d.get("cons", []))
		dist = PackedFloat32Array(_to_float_array(d.get("dist", [])))

	var c = _read_json("res://data/sky/constellations.json")
	if typeof(c) == TYPE_ARRAY:
		for item in c:
			constellations.append(item)
			constellations_by_id[item.get("id", "")] = item

	var n = _read_json("res://data/sky/nakshatras.json")
	if typeof(n) == TYPE_ARRAY:
		nakshatras = n

	var ns = _read_json("res://data/sky/named_stars.json")
	if typeof(ns) == TYPE_ARRAY:
		named_stars = ns

	ready_ok = hips.size() > 100
	print("[Sky] stars=", hips.size(), " constellations=", constellations.size(), " nakshatras=", nakshatras.size())


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Missing data: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	return JSON.parse_string(txt)


func _to_float_array(a: Array) -> Array:
	var out := []
	out.resize(a.size())
	for i in a.size():
		out[i] = float(a[i])
	return out


func _to_int_array(a: Array) -> Array:
	var out := []
	out.resize(a.size())
	for i in a.size():
		out[i] = int(a[i])
	return out


func star_dir(i: int) -> Vector3:
	return dir_from_ra_dec(ra[i], dec[i])


func dir_from_ra_dec(ra_deg: float, dec_deg: float) -> Vector3:
	var a := deg_to_rad(ra_deg)
	var d := deg_to_rad(dec_deg)
	var cd := cos(d)
	return Vector3(cd * cos(a), sin(d), -cd * sin(a)).normalized()


func star_color(bv: float) -> Color:
	# Hand-tuned stellar colour ramp from blue-white to deep orange.
	var stops := [
		[-0.35, Color("9db8ff")],
		[-0.05, Color("c5d6ff")],
		[0.25, Color("eef2ff")],
		[0.60, Color("fff6e2")],
		[1.00, Color("ffe3b3")],
		[1.55, Color("ffb982")],
		[2.20, Color("ff9268")],
	]
	for i in range(stops.size() - 1):
		var a = stops[i]
		var b = stops[i + 1]
		if bv <= b[0]:
			var t: float = clamp((bv - a[0]) / (b[0] - a[0]), 0.0, 1.0)
			return (a[1] as Color).lerp(b[1], t)
	return stops[stops.size() - 1][1]


func hip_star(hip: int) -> Dictionary:
	for i in hips.size():
		if hips[i] == hip:
			return {"index": i, "ra": ra[i], "dec": dec[i], "mag": mag[i], "ci": ci[i],
				"name": star_names[i], "con": star_cons[i], "dist": dist[i] if i < dist.size() else 0.0}
	return {}


func constellation(id: String) -> Dictionary:
	return constellations_by_id.get(id, {})


func star_index_by_hip(h: int) -> int:
	return hips.find(h)


func nakshatra_by_english(name: String) -> Dictionary:
	for n in nakshatras:
		if str(n.get("english", "")).to_lower() == name.to_lower():
			return n
	return {}

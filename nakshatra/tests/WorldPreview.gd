extends Node3D
## Dev-only art preview for the hilltop world, without any UI chrome.

var cam: Camera3D
var hill: SkyHill
var sky: SkyDome


func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 58.0
	cam.position = Vector3(0.0, 6.4, 17.0)
	add_child(cam)
	cam.look_at(Vector3(0.0, 4.0, -2.0), Vector3.UP)
	cam.current = true

	sky = SkyDome.new()
	sky.latitude_deg = 13.0
	sky.sidereal_deg = 108.0
	add_child(sky)
	sky.set_modern_lines(false)
	sky.set_star_scale(1.2)
	sky.set_star_intensity(1.08)

	hill = SkyHill.new()
	hill.name = "SkyHill"
	add_child(hill)
	hill.build(true)

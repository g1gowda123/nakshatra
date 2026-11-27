shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 core_color : source_color = vec3(1.0, 0.86, 0.58);
uniform vec3 limb_color : source_color = vec3(1.0, 0.52, 0.18);

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.6);
	float gran = 0.92 + 0.08 * hash13(floor(NORMAL * 90.0));
	ALBEDO = mix(core_color, limb_color, rim) * gran;
	EMISSION = ALBEDO * 2.6;
}

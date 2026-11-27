shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Riveted brass dome panels. Seams follow the meridian so the observatory
// reads as a built instrument, not a grey hemisphere.
uniform vec3 dome_color : source_color = vec3(0.105, 0.145, 0.185);
uniform vec3 sheen_color : source_color = vec3(0.35, 0.42, 0.46);
uniform vec3 seam_color : source_color = vec3(0.035, 0.045, 0.055);
uniform vec3 warm_color : source_color = vec3(1.0, 0.68, 0.36);
uniform float panel_count = 12.0;
uniform float warmth = 0.0;

varying vec3 v_local;
varying vec3 v_normal_local;

void vertex() {
	v_local = VERTEX;
	v_normal_local = NORMAL;
}

void fragment() {
	float ang = atan(v_local.z, v_local.x);
	float u = ang / 6.2831853 + 0.5;
	float seam_d = abs(fract(u * panel_count) - 0.5) * 2.0;
	float seam = smoothstep(0.90, 1.0, seam_d);
	float rib_h = abs(fract((v_local.y + 3.4) * 2.2) - 0.5) * 2.0;
	float rib = smoothstep(0.94, 1.0, rib_h);
	float facing = clamp(dot(normalize(v_normal_local), vec3(0.0, 0.5, 1.0)), 0.0, 1.0);
	vec3 col = mix(dome_color, sheen_color, facing * 0.35);
	col = mix(col, seam_color, max(seam * 0.7, rib * 0.5));
	ALBEDO = col;
	METALLIC = 0.72;
	ROUGHNESS = 0.42;
	EMISSION = warm_color * warmth * 0.12 * (0.4 + 0.6 * facing);
}

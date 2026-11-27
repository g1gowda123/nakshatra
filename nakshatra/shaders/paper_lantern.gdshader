shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

// Paper lantern skin: warm silk, dark bamboo ribs, a little flicker.
uniform vec3 paper_color : source_color = vec3(0.95, 0.62, 0.30);
uniform vec3 light_color : source_color = vec3(1.0, 0.78, 0.45);
uniform vec3 rib_color : source_color = vec3(0.36, 0.16, 0.07);
uniform float lit : hint_range(0.0, 1.0) = 1.0;
uniform float ribs = 9.0;
uniform float flicker = 1.0;
uniform vec3 done_tint : source_color = vec3(1.0, 0.86, 0.58);

varying vec3 v_local;

void vertex() {
	v_local = VERTEX;
}

void fragment() {
	float ang = atan(v_local.z, v_local.x);
	float u = ang / 6.2831853 + 0.5;
	// Bamboo ribs: soft dark bands at regular angles.
	float rib_d = abs(fract(u * ribs) - 0.5) * 2.0;
	float rib = smoothstep(0.82, 1.0, rib_d);
	// Vertical spring: brighter mid-height, darker at the caps.
	float h = clamp((v_local.y + 0.36) / 0.72, 0.0, 1.0);
	float belly = 0.55 + 0.45 * sin(h * 3.14159);
	float grain = 0.96 + 0.04 * sin(ang * 41.0 + v_local.y * 23.0);

	vec3 warm = mix(paper_color, light_color, lit) * grain;
	warm *= (0.78 + 0.32 * belly) * flicker;
	warm = mix(warm, done_tint, lit * 0.18);
	warm = mix(warm * 0.35, warm, lit);
	warm = mix(warm, rib_color, rib * 0.55);

	ALBEDO = warm;
	ROUGHNESS = 0.9;
	// The paper is the light source; a soft inner glow spills into the ribs.
	EMISSION = light_color * lit * (0.35 + 0.45 * belly) * flicker;
	ALPHA = 1.0;
}

shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx, cull_disabled;

// Worn stone path. Vertex colour carries lantern warmth; the shader adds
// irregular flagstones, mortar lines and a little gilt dust.
uniform vec3 stone_color : source_color = vec3(0.16, 0.17, 0.16);
uniform vec3 mortar_color : source_color = vec3(0.055, 0.065, 0.070);
uniform vec3 warm_color : source_color = vec3(1.0, 0.68, 0.38);
uniform float warm_emission = 0.35;

varying vec3 v_world;
varying vec3 v_tint;
varying float v_warm;

float hash21(vec2 p) {
	p = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
	           mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tint = COLOR.rgb;
	v_warm = COLOR.a;
}

void fragment() {
	// Staggered flagstones.
	vec2 p = v_world.xz * 0.9;
	vec2 row = floor(p);
	float stagger = mod(row.y, 2.0) * 0.5;
	vec2 cell = vec2(p.x + stagger, p.y);
	vec2 local = fract(cell);
	float stone_noise = noise2(floor(cell) * 3.7) * 0.18;
	float edge = min(min(local.x, 1.0 - local.x), min(local.y, 1.0 - local.y));
	float mortar = smoothstep(0.02, 0.075, edge);
	float chip = smoothstep(0.32, 0.7, noise2(p * 9.0));

	vec3 tint = v_tint;
	vec3 col = stone_color * tint * (0.85 + stone_noise + chip * 0.12);
	col = mix(mortar_color, col, mortar);
	// Gilt dust catches the lanterns.
	col += warm_color * v_warm * v_warm * 0.10;

	ALBEDO = col;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	SPECULAR = 0.12;
	EMISSION = warm_color * v_warm * v_warm * warm_emission;
}

shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;

// Night-hill ground. Writes warmth into vertex-alpha (0..1) so each lantern
// leaves a soft pool of light on the ink-washed grass without extra lights.
uniform vec3 deep_color : source_color = vec3(0.052, 0.080, 0.078);
uniform vec3 thicket_color : source_color = vec3(0.075, 0.110, 0.095);
uniform vec3 warm_color : source_color = vec3(1.0, 0.66, 0.34);
uniform float warm_emission = 0.34;
uniform float noise_scale = 0.55;

varying vec3 v_world;
varying vec3 v_tint;
varying float v_warm;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise2(p);
		p = p * 2.03 + vec2(13.1, 7.7);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_tint = COLOR.rgb;
	v_warm = COLOR.a;
}

void fragment() {
	vec2 p = v_world.xz * noise_scale;
	float broad = fbm2(p * 0.35);
	float fine = fbm2(p * 2.3 + vec2(41.0, 9.0));
	float fibre = fbm2(p * 9.0 + vec2(3.0, 27.0));

	vec3 base = v_tint * (0.78 + 0.36 * broad);
	// Patches of denser, cooler hill scrub.
	float scrub = smoothstep(0.52, 0.78, fbm2(p * 0.18 + vec2(19.0, 4.0)));
	base = mix(base, thicket_color, scrub * 0.45);
	base *= 0.92 + 0.13 * fine;
	// A faint paper-fibre grain, so the ground reads as painted rather than CG.
	base += vec3(0.012, 0.010, 0.006) * (fibre - 0.5);

	ALBEDO = base;
	ROUGHNESS = 0.97;
	METALLIC = 0.0;
	SPECULAR = 0.08;
	// Warm pools: squared so the falloff feels like lantern light, not a wash.
	EMISSION = warm_color * v_warm * v_warm * warm_emission;
}

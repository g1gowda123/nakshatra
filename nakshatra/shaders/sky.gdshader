shader_type sky;
render_mode use_debanding;

uniform vec3 zenith_color : source_color = vec3(0.012, 0.020, 0.055);
uniform vec3 mid_color : source_color = vec3(0.028, 0.055, 0.120);
uniform vec3 horizon_color : source_color = vec3(0.075, 0.115, 0.200);
uniform vec3 glow_color : source_color = vec3(0.42, 0.25, 0.13);
uniform float milky_strength = 0.85;
uniform float star_dust = 0.0;
uniform mat3 sky_basis = mat3(1.0);
uniform float low_quality = 0.0;

const vec3 GAL_NORTH = vec3(-0.868, 0.456, 0.191);

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1,0,0));
	float n010 = hash13(i + vec3(0,1,0));
	float n110 = hash13(i + vec3(1,1,0));
	float n001 = hash13(i + vec3(0,0,1));
	float n101 = hash13(i + vec3(1,0,1));
	float n011 = hash13(i + vec3(0,1,1));
	float n111 = hash13(i + vec3(1,1,1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
	           mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise3(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(transpose(sky_basis) * EYEDIR);
	float h = clamp(d.y, -1.0, 1.0);

	vec3 col = mix(horizon_color, mid_color, smoothstep(-0.05, 0.22, h));
	col = mix(col, zenith_color, smoothstep(0.18, 0.95, h));

	// Warm dust/airglow hugging the horizon, like a distant town.
	float horizon_band = exp(-abs(h) * 16.0);
	col += glow_color * horizon_band * 0.16;

	if (low_quality > 0.5) {
		vec3 cheap = mix(horizon_color, mid_color, smoothstep(-0.05, 0.22, h));
		cheap = mix(cheap, zenith_color, smoothstep(0.18, 0.95, h));
		float band2 = exp(-pow(dot(d, GAL_NORTH) / 0.20, 2.0));
		float n2 = noise3(d * 7.0) * 0.6 + noise3(d * 17.0) * 0.4;
		cheap += vec3(0.55, 0.58, 0.72) * band2 * (0.05 + 0.10 * n2) * milky_strength;
		COLOR = cheap;
	} else {
		// Milky Way: a soft galactic band with dust lanes and clumps.
		float b = dot(d, GAL_NORTH);
		float band = exp(-pow(b / 0.19, 2.0));
		float clouds = fbm(d * 6.5) * 0.6 + fbm(d * 16.0) * 0.4;
		float dust = smoothstep(0.35, 0.75, fbm(d * 9.0 + vec3(11.0)));
		vec3 mw = mix(vec3(0.45, 0.52, 0.72), vec3(0.95, 0.82, 0.62), clouds);
		col += mw * band * (0.055 + 0.10 * clouds) * (1.0 - 0.55 * dust) * milky_strength;

		// A whisper of unresolved starlight.
		float speck = smoothstep(0.90, 1.0, hash13(floor(d * 210.0)));
		col += vec3(0.55, 0.60, 0.78) * speck * star_dust * 0.25;

		// Subtle vignette to the nadir.
		col *= 1.0 - smoothstep(0.0, -0.7, h) * 0.55;
		COLOR = col;
	}
}

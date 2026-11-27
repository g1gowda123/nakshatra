shader_type spatial;
render_mode unshaded, cull_back;

uniform vec3 core_color : source_color = vec3(1.0, 0.82, 0.42);
uniform vec3 limb_color : source_color = vec3(1.0, 0.36, 0.06);
uniform float stress : hint_range(0.0, 1.0) = 0.3;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1,0,0)), f.x),
	               mix(hash13(i + vec3(0,1,0)), hash13(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash13(i + vec3(0,0,1)), hash13(i + vec3(1,0,1)), f.x),
	               mix(hash13(i + vec3(0,1,1)), hash13(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * noise3(p);
		p *= 2.04;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	float t = TIME * 0.035;
	float gran = fbm(n * 11.0 + vec3(t, -t * 0.6, t * 0.3));
	float cells = noise3(n * 26.0 - vec3(t * 1.8));
	float spot = smoothstep(0.62, 0.73, fbm(n * 2.6 + vec3(2.1, 4.7, 0.9)));
	vec3 col = mix(limb_color, core_color, gran * 0.65 + cells * 0.35);
	col *= 1.0 - spot * 0.72;
	float rim = pow(1.0 - clamp(dot(n, VIEW), 0.0, 1.0), 1.4);
	col = mix(col, vec3(1.0, 0.42, 0.08), rim * 0.5);
	col += vec3(1.0, 0.55, 0.12) * stress * 0.10;
	ALBEDO = col;
	EMISSION = col * 2.3;
}

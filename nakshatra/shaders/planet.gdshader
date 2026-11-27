shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_color : source_color = vec3(0.6, 0.5, 0.4);
uniform vec3 accent_color : source_color = vec3(0.9, 0.8, 0.6);
uniform float bands = 0.4;
uniform float mottle = 0.25;
uniform float band_freq = 18.0;

varying vec3 v_obj;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}
float noise3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1,0,0)), f.x),
	               mix(hash13(i + vec3(0,1,0)), hash13(i + vec3(1,1,0)), f.x), f.y),
	           mix(mix(hash13(i + vec3(0,0,1)), hash13(i + vec3(1,0,1)), f.x),
	               mix(hash13(i + vec3(0,1,1)), hash13(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
	float v = 0.0; float a = 0.5;
	for (int i = 0; i < 4; i++) { v += a * noise3(p); p *= 2.06; a *= 0.5; }
	return v;
}

void vertex() { v_obj = VERTEX; }

void fragment() {
	vec3 n = normalize(v_obj);
	float b = sin(n.y * band_freq + fbm(n * 3.0) * 2.2) * 0.5 + 0.5;
	float m = fbm(n * 7.0);
	vec3 col = mix(base_color, accent_color, clamp(b * bands + m * mottle, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.82;
	METALLIC = 0.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = vec3(0.06, 0.09, 0.16) * rim;
}

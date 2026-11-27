shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

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
	for (int i = 0; i < 5; i++) { v += a * noise3(p); p *= 2.05; a *= 0.5; }
	return v;
}

void vertex() { v_obj = VERTEX; }

void fragment() {
	vec3 n = normalize(v_obj);
	float base = 0.55 + fbm(n * 3.4) * 0.18;
	// Maria: darker low plains.
	float maria = smoothstep(0.42, 0.58, fbm(n * 1.7 + vec3(3.0)));
	base -= maria * 0.12;
	// Craters: ring + shadow.
	float c1 = fbm(n * 9.0);
	float crater = smoothstep(0.62, 0.69, c1);
	float rim = smoothstep(0.58, 0.64, c1) * (1.0 - crater);
	vec3 col = vec3(base);
	col += rim * 0.16;
	col -= crater * 0.10;
	col *= 1.0 - smoothstep(0.8, 1.0, fbm(n * 24.0)) * 0.08;
	ALBEDO = col;
	// A whisper of earthshine so the unlit limb still reads as a sphere.
	EMISSION = col * 0.030;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
}

shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 ocean_deep : source_color = vec3(0.020, 0.070, 0.180);
uniform vec3 ocean_shallow : source_color = vec3(0.030, 0.200, 0.330);
uniform vec3 land_low : source_color = vec3(0.130, 0.280, 0.150);
uniform vec3 land_high : source_color = vec3(0.420, 0.360, 0.200);
uniform vec3 cloud_color : source_color = vec3(0.900, 0.940, 1.000);

varying vec3 v_obj;

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
	for (int i = 0; i < 5; i++) {
		v += a * noise3(p);
		p *= 2.02;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_obj = VERTEX;
}

void fragment() {
	vec3 n = normalize(v_obj);
	float cont = fbm(n * 2.15 + vec3(4.2, 1.3, 8.7));
	float detail = fbm(n * 7.0);
	float land = smoothstep(0.515, 0.555, cont + detail * 0.055);

	vec3 ocean = mix(ocean_deep, ocean_shallow, smoothstep(-0.45, 0.55, n.y) * 0.55 + detail * 0.25);
	vec3 ground = mix(land_low, land_high, smoothstep(0.35, 0.8, detail));
	ground = mix(ground, vec3(0.52, 0.45, 0.28), smoothstep(0.62, 0.85, fbm(n * 3.1)) * 0.7);
	float ice = smoothstep(0.84, 0.94, abs(n.y));
	vec3 col = mix(ocean, ground, land);
	col = mix(col, vec3(0.86, 0.91, 0.97), ice);

	float cl = smoothstep(0.57, 0.70, fbm(n * 4.2 + vec3(TIME * 0.006, 0.0, 0.0)));
	col = mix(col, cloud_color, cl * 0.33);

	ALBEDO = col;
	ROUGHNESS = mix(0.32, 0.92, land);
	METALLIC = 0.0;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = vec3(0.10, 0.28, 0.72) * rim * 0.55;
}

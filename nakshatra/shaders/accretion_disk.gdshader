shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform float inner = 2.1;
uniform float outer = 4.6;

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
	for (int i = 0; i < 4; i++) { v += a * noise3(p); p *= 2.03; a *= 0.5; }
	return v;
}

void vertex() { v_obj = VERTEX; }

void fragment() {
	float r = length(v_obj.xz);
	float a = atan(v_obj.z, v_obj.x);
	float edge = smoothstep(inner, inner + 0.28, r) * (1.0 - smoothstep(outer - 0.65, outer, r));
	float swirl = fbm(vec3(cos(a) * 2.4, sin(a) * 2.4, r * 1.7 - TIME * 0.55));
	float bands = 0.55 + 0.45 * sin(a * 7.0 + r * 5.5 - TIME * 1.4 + swirl * 4.0);
	float heat = smoothstep(inner, inner + 1.2, r) * 0.55 + swirl * 0.45;
	vec3 col = mix(vec3(1.0, 0.30, 0.04), vec3(1.0, 0.93, 0.72), clamp(heat, 0.0, 1.0));
	col = mix(col, vec3(1.0, 0.68, 0.22), bands * 0.35);
	ALBEDO = col;
	EMISSION = col * (1.6 + bands * 1.1);
	ALPHA = edge * (0.45 + 0.55 * bands);
}

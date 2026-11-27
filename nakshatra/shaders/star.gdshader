shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float intensity = 1.0;
uniform float size_scale = 1.0;

varying vec3 v_color;
varying float v_twinkle;

void vertex() {
	v_color = COLOR.rgb;
	float phase = INSTANCE_CUSTOM.y;
	float size = max(INSTANCE_CUSTOM.x * size_scale, 0.001);
	v_twinkle = 1.0 + 0.13 * sin(TIME * (1.1 + phase * 1.7) + phase * 6.283);
	// Billboard in view space, scaled per instance.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(size, 0.0, 0.0, 0.0),
		vec4(0.0, size, 0.0, 0.0),
		vec4(0.0, 0.0, size, 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = PROJECTION_MATRIX * MODELVIEW_MATRIX;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float core = max(0.0, 1.0 - r);
	float halo = exp(-r * r * 5.0);
	float a = pow(core, 2.4) + halo * 0.28;
	ALBEDO = v_color * intensity * v_twinkle;
	ALPHA = clamp(a, 0.0, 1.0);
}

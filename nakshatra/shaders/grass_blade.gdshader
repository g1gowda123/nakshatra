shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;

// A single tapered hill-grass blade. Geometry is one triangle strip; the
// sway is done in the vertex stage so a MultiMesh of tufts costs almost nothing.
uniform vec3 base_color : source_color = vec3(0.045, 0.075, 0.065);
uniform vec3 tip_color : source_color = vec3(0.12, 0.16, 0.12);
uniform vec3 warm_color : source_color = vec3(1.0, 0.70, 0.38);
uniform float sway = 0.10;

varying float v_height;
varying float v_warm;

void vertex() {
	v_height = UV.y;
	v_warm = COLOR.a;
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sin(TIME * 1.35 + wp.x * 0.6 + wp.z * 0.45 + COLOR.r * 6.28);
	VERTEX.x += wave * sway * v_height * v_height;
	VERTEX.z += cos(TIME * 1.1 + wp.z * 0.5) * sway * 0.5 * v_height * v_height;
}

void fragment() {
	vec3 col = mix(base_color, tip_color, v_height * v_height);
	col = mix(col, warm_color, v_warm * v_warm * 0.35);
	ALBEDO = col;
	ROUGHNESS = 1.0;
	EMISSION = warm_color * v_warm * v_warm * 0.035;
}

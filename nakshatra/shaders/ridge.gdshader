shader_type spatial;
render_mode unshaded, cull_disabled;

// A soft, layered hill silhouette for the horizon. No texture, no lighting:
// just a vertical ink wash that reads as distant land in the dark.
uniform vec3 low_color : source_color = vec3(0.020, 0.032, 0.050);
uniform vec3 high_color : source_color = vec3(0.050, 0.075, 0.105);
uniform float base_y = -4.0;
uniform float top_y = 8.0;
uniform float mist = 0.35;
uniform vec3 mist_color : source_color = vec3(0.18, 0.23, 0.30);

varying vec3 v_world;

void vertex() {
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float h = clamp((v_world.y - base_y) / max(top_y - base_y, 0.001), 0.0, 1.0);
	vec3 col = mix(low_color, high_color, smoothstep(0.0, 1.0, h));
	float band = exp(-abs(h - 0.25) * 7.0);
	col = mix(col, mist_color, band * mist);
	ALBEDO = col;
}

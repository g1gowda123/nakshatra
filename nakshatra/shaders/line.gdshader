shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform float alpha = 0.75;

void vertex() {
	// Lines live far away; no billboarding needed.
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * alpha;
}

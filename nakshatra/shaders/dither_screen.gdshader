shader_type canvas_item;
// Full-screen 1-bit / posterized dither. Add as the last 3D-covering CanvasItem
// but before the UI so text stays crisp. Based on the standard 4x4 Bayer matrix.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 light : source_color = vec4(0.949, 0.949, 0.933, 1.0);
uniform vec4 dark : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float levels = 2.0;
uniform float pixel_size = 2.0;
uniform float dither_strength = 0.42;

float bayer4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));
	int i = x + y * 4;
	float m[16] = float[](
		0.0, 8.0, 2.0, 10.0,
		12.0, 4.0, 14.0, 6.0,
		3.0, 11.0, 1.0, 9.0,
		15.0, 7.0, 13.0, 5.0
	);
	return m[i] / 16.0;
}

void fragment() {
	vec2 px = max(vec2(pixel_size), vec2(1.0));
	vec2 screen_size = 1.0 / max(SCREEN_PIXEL_SIZE, vec2(0.000001));
	vec2 uv = floor(SCREEN_UV * screen_size / px) * px * SCREEN_PIXEL_SIZE;
	vec3 c = texture(screen_tex, uv).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	float d = bayer4(FRAGCOORD.xy);
	float levels_n = max(levels, 2.0);
	float q = floor(l * levels_n + (d - 0.5) * dither_strength) / (levels_n - 1.0);
	q = clamp(q, 0.0, 1.0);
	vec3 out_col = mix(dark.rgb, light.rgb, q);
	COLOR = vec4(out_col, 1.0);
}

shader_type canvas_item;
// 1-bit image treatment for plates and previews. The paper/ink palette keeps
// the archive/receipt feel even when the source art is photographic.

uniform vec4 light : source_color = vec4(0.949, 0.949, 0.933, 1.0);
uniform vec4 dark : source_color = vec4(0.02, 0.02, 0.02, 1.0);
uniform float levels = 2.0;
uniform float pixel_size = 1.0;

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
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv = floor(UV * tex_size / px) * px / tex_size;
	vec4 c = texture(TEXTURE, uv);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float levels_n = max(levels, 2.0);
	float q = floor(l * levels_n + (bayer4(FRAGCOORD.xy) - 0.5) * 0.42) / (levels_n - 1.0);
	q = clamp(q, 0.0, 1.0);
	COLOR = vec4(mix(dark.rgb, light.rgb, q), c.a);
}

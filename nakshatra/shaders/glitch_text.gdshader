shader_type canvas_item;
// Horizontal block tearing and RGB separation for the wordmark. Keep the
// amount low: this should read as a signal, not as a broken font.

uniform float amount : hint_range(0.0, 1.0) = 0.35;
uniform float speed = 7.0;
uniform vec3 tint : source_color = vec3(0.776, 1.0, 0.0);

float rand(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float block = floor(uv.y * 28.0 + floor(TIME * speed));
	float n = rand(block);
	if (n > 0.82) {
		uv.x += (n - 0.82) * amount * 0.16;
	}
	vec4 c = texture(TEXTURE, uv);
	float split = (n - 0.5) * amount * 0.012;
	c.r = texture(TEXTURE, uv + vec2(split, 0.0)).r;
	c.b = texture(TEXTURE, uv - vec2(split, 0.0)).b;
	COLOR = c * COLOR;
}

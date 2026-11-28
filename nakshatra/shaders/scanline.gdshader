shader_type canvas_item;
// A transparent CRT scanline veil. It is drawn above the UI but ignores input.

uniform float alpha = 0.10;
uniform vec3 line_color : source_color = vec3(0.0, 0.0, 0.0);
uniform float speed = 0.05;

void fragment() {
	float y = FRAGCOORD.y;
	float scan = step(0.55, fract(y * 0.5 + TIME * speed));
	float band = smoothstep(0.0, 0.06, abs(fract(SCREEN_UV.y * 0.9 - TIME * 0.015) - 0.5));
	COLOR = vec4(line_color, alpha * (0.4 + 0.6 * scan) * (0.7 + 0.3 * band));
}

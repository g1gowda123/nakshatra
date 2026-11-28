shader_type canvas_item;
// A brief datamosh wipe for scene changes: rows tear sideways, a few blocks
// displace, and the RGB channels separate before the status card takes over.
// It samples the outgoing frame only, so UI and text never feed back.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

float rand(float n) {
	return fract(sin(n * 12.9898) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 12.0);
	float row = floor(uv.y * 54.0);
	float n = rand(row + t * 7.0);
	if (n > 0.70) {
		uv.x += (n - 0.70) * amount * 0.24;
	}
	vec2 cell = floor(uv * vec2(22.0, 13.0));
	float c = rand(cell.x + cell.y * 31.0 + t);
	if (c > 0.88) {
		uv += (vec2(rand(cell.x + t), rand(cell.y - t)) - 0.5) * amount * 0.09;
	}
	vec3 col = texture(screen_tex, uv).rgb;
	if (amount > 0.001) {
		col.r = texture(screen_tex, uv + vec2(amount * 0.008, 0.0)).r;
		col.b = texture(screen_tex, uv - vec2(amount * 0.008, 0.0)).b;
	}
	col = mix(col, vec3(0.018, 0.018, 0.018), smoothstep(0.62, 1.0, amount));
	COLOR = vec4(col, 1.0);
}

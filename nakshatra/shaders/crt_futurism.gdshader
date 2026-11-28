shader_type canvas_item;
// Cassette Futurism screen treatment.
//
// One quiet pass over the finished frame: faint phosphor scanlines, a warm
// vignette, a whisper of tape noise, and just enough chromatic split to feel
// like a tube without turning the lesson text into soup.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.055;
uniform float scanline_count : hint_range(64.0, 1440.0) = 720.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.24;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.018;
uniform float chromatic_split : hint_range(0.0, 0.004) = 0.0007;
uniform vec3 phosphor_tint : source_color = vec3(0.49, 1.0, 0.66);

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 split = vec2(chromatic_split, 0.0);
	vec3 col;
	col.r = texture(screen_tex, uv + split).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - split).b;

	// Scanlines: a slow, calm comb. Never a harsh CRT flicker.
	float line = 0.5 + 0.5 * sin(uv.y * scanline_count * 3.14159265);
	col *= 1.0 - scanline_strength * line;

	// A whisper of phosphor warmth over the whole tube.
	col = mix(col, col * phosphor_tint * 1.08, 0.10);

	// Vignette: keep the corners quiet, never crush the centre.
	vec2 d = uv - vec2(0.5, 0.5);
	float vig = 1.0 - vignette_strength * clamp(dot(d, d) * 2.4, 0.0, 1.0);
	col *= clamp(vig, 0.0, 1.0);

	// Tape noise: a few grains, not a snowstorm.
	float n = hash12(uv * vec2(1920.0, 1080.0) + vec2(TIME * 13.0, TIME * 7.0));
	col += (n - 0.5) * noise_strength;

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}

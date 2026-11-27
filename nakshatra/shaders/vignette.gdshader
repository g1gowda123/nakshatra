shader_type canvas_item;

uniform float strength = 0.38;
uniform vec4 tint : source_color = vec4(0.01, 0.015, 0.04, 1.0);

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float edge = smoothstep(0.55, 1.45, length(uv));
	COLOR = vec4(tint.rgb, edge * strength);
}

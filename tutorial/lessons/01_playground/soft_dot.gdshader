shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;
// Deliberately reproduce a common mistake for the lesson.
uniform bool ignore_particle_color = false;

void fragment() {
	// COLOR already contains the particle tint and the sampled texture.
	vec4 incoming = COLOR;
	float distance_to_center = length(UV - vec2(0.5));
	float mask = 1.0 - smoothstep(0.20, 0.48, distance_to_center);
	if (ignore_particle_color) {
		COLOR = vec4(vec3(1.0), mask * opacity);
	} else {
		COLOR = vec4(incoming.rgb, incoming.a * mask * opacity);
	}
}

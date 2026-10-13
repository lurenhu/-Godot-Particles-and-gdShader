shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform sampler2D noise_map : repeat_enable, filter_linear;
uniform int samples : hint_range(1, 8) = 4;
varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float noise_value = 0.0;
	for (int i = 0; i < samples; i++) {
		noise_value += texture(noise_map, UV * (1.0 + float(i) * 0.37) + vec2(age * 0.1, float(i) * 0.173)).r;
	}
	noise_value /= float(samples);
	float mask = 1.0 - smoothstep(0.1, 0.5, length(UV - 0.5));
	ALBEDO = mix(vec3(0.15, 0.5, 1.0), vec3(0.7, 0.9, 1.0), noise_value);
	ALPHA = COLOR.a * mask * noise_value * 0.16 * sin(clamp(age, 0.0, 1.0) * 3.14159265);
}

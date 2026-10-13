shader_type canvas_item;
render_mode blend_add;
uniform vec4 tint : source_color = vec4(0.25, 0.7, 1.0, 1.0);
uniform sampler2D noise_map : repeat_enable, filter_linear;
uniform float effect_time = 0.0;
uniform float radius = 120.0;
uniform float intensity = 1.0;
uniform float extent = 264.0;
uniform int noise_samples = 3;

void fragment() {
	// 用局部像素坐标定义效果，调整矩形尺寸不会改变形状尺寸。
	vec2 p = (UV - 0.5) * extent;
	float d = length(p);
	float noise_value = 0.0;
	for (int i = 0; i < noise_samples; i++) {
		noise_value += texture(noise_map, p / radius * (0.7 + float(i) * 0.23) + vec2(effect_time * 0.08, float(i) * 0.31)).r;
	}
	noise_value /= float(noise_samples);
	float mask;
	if (effect_time < 0.8) {
		float q = effect_time / 0.8;
		float ring_radius = mix(radius * 0.5, 12.0, q);
		float ring = 1.0 - smoothstep(1.0, 3.0, abs(d - ring_radius));
		float angle = atan(p.y, p.x);
		float spokes = pow(abs(cos(angle * 4.0 + q * 4.0)), 10.0);
		mask = (ring + spokes * (1.0 - smoothstep(8.0, ring_radius, d)) * 0.3) * smoothstep(0.0, 0.15, q);
	} else if (effect_time < 1.3) {
		mask = 1.0 - smoothstep(3.0, 22.0, d);
	} else {
		float q = clamp((effect_time - 1.3) / 1.3, 0.0, 1.0);
		float ring_radius = mix(8.0, radius * 0.95, 1.0 - exp(-4.0 * q));
		float ring = 1.0 - smoothstep(2.0, 5.0, abs(d - ring_radius));
		float flash = (1.0 - smoothstep(0.0, 0.14, q)) * (1.0 - smoothstep(0.0, radius * 0.6, d));
		float dissolve = smoothstep(q - 0.08, q + 0.08, noise_value);
		mask = (ring * dissolve + flash) * (1.0 - smoothstep(0.5, 1.0, q));
	}
	COLOR = vec4(tint.rgb * (0.7 + noise_value * 0.6), tint.a * clamp(mask * intensity, 0.0, 1.0));
}

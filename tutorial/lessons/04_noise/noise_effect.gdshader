shader_type canvas_item;
render_mode unshaded, blend_mix;

// 同一数据纹理，三个采样器用于比较过滤和边界寻址。
uniform sampler2D noise_linear : repeat_enable, filter_linear_mipmap;
uniform sampler2D noise_nearest : repeat_enable, filter_nearest;
uniform sampler2D noise_clamp : repeat_disable, filter_linear_mipmap;
uniform int sampling_mode = 0;
uniform int effect = 0; // 0 溶解；1 火焰
uniform int debug_view = 0; // 成品、原噪声、扭曲坐标、组合噪声、遮罩
uniform float lesson_time = 0.0;
uniform float progress : hint_range(0.0, 1.0) = 0.45;
uniform float frequency : hint_range(0.5, 6.0) = 2.0;
uniform float warp_amount : hint_range(0.0, 0.3) = 0.06;
uniform float detail_weight : hint_range(0.0, 1.0) = 0.3;
uniform float scroll_speed : hint_range(-0.6, 0.6) = 0.15;
uniform float edge_width : hint_range(0.005, 0.2) = 0.06;

float noise_at(vec2 uv) {
	if (sampling_mode == 1) { return texture(noise_nearest, uv).r; }
	if (sampling_mode == 2) { return texture(noise_clamp, uv).r; }
	return texture(noise_linear, uv).r;
}

void fragment() {
	vec4 incoming = COLOR;
	vec2 flow = vec2(0.0, lesson_time * scroll_speed);
	float raw_noise = noise_at(UV * frequency + flow);
	vec2 displacement = vec2(noise_at(UV + flow), noise_at(UV + flow + vec2(0.37, 0.61))) * 2.0 - 1.0;
	vec2 warped_uv = UV + displacement * warp_amount;
	float low = noise_at(warped_uv * frequency + flow);
	float high = noise_at(warped_uv * frequency * 2.0 - flow * 0.7 + vec2(0.21, 0.43));
	float n = mix(low, high, detail_weight);
	float mask = 0.0;
	vec3 color = vec3(0.12, 0.65, 0.95);
	if (effect == 0) {
		float base = 1.0 - smoothstep(0.335, 0.345, length(UV - vec2(0.5)));
		// 扩展阈值范围，使端点不依赖噪声是否碰巧含有 0 或 1。
		float threshold = mix(-0.21, 1.01, progress);
		float remaining = smoothstep(threshold, threshold + 0.015, n);
		if (progress <= 0.0) { remaining = 1.0; }
		if (progress >= 1.0) { remaining = 0.0; }
		float edge = 1.0 - smoothstep(threshold + 0.015, threshold + 0.015 + edge_width, n);
		if (progress <= 0.0 || progress >= 1.0) { edge = 0.0; }
		mask = base * remaining;
		color = mix(color, vec3(1.0, 0.65, 0.08), edge);
	} else {
		// 下宽上窄的轮廓，加向上流动的噪声。这里没有流体模拟。
		vec2 p = UV;
		p.x += displacement.x * warp_amount * (1.0 - UV.y);
		float half_width = mix(0.015, 0.27, clamp((p.y - 0.1) / 0.8, 0.0, 1.0));
		float envelope = (1.0 - smoothstep(half_width, half_width + 0.025, abs(p.x - 0.5)))
			* smoothstep(0.08, 0.2, p.y) * (1.0 - smoothstep(0.85, 0.92, p.y));
		mask = envelope * smoothstep(0.4, 0.65, n + UV.y * 0.4);
		color = mix(vec3(1.0, 0.12, 0.015), vec3(1.0, 0.9, 0.3), clamp(UV.y * n * 1.6, 0.0, 1.0));
	}
	if (debug_view == 1) { COLOR = vec4(vec3(raw_noise), 1.0); }
	else if (debug_view == 2) { COLOR = vec4(clamp(warped_uv, vec2(0.0), vec2(1.0)), 0.0, 1.0); }
	else if (debug_view == 3) { COLOR = vec4(vec3(n), 1.0); }
	else if (debug_view == 4) { COLOR = vec4(vec3(mask), 1.0); }
	else { COLOR = vec4(incoming.rgb * color, incoming.a * mask); }
}

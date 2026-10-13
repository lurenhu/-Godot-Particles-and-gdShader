uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform bool use_particle_age = true;
uniform bool random_phase = true;
uniform bool preserve_color = true;
uniform bool dissolve_enabled = true;
uniform int debug_view = 0;
uniform float lesson_time = 0.0;
uniform float lifetime = 4.0;
uniform float dissolve_start : hint_range(0.2, 0.85) = 0.55;
uniform float pulse_hz : hint_range(0.0, 4.0) = 1.0;

varying float particle_age;
varying float birth_phase;

void vertex() {
	// 本课寿命随机为 0；不写入或重新定义引擎的 CUSTOM 通道。
	particle_age = clamp(INSTANCE_CUSTOM.y, 0.0, 1.0);
	// 动画速度为 0，无序列帧；借用稳定的动画偏移作为相位。
	birth_phase = INSTANCE_CUSTOM.z;
}

void fragment() {
	vec4 incoming = COLOR;
	float age = use_particle_age ? particle_age : fract(lesson_time / lifetime);
	float radius = mix(0.12, 0.42, smoothstep(0.0, 0.35, age));
	float disk = 1.0 - smoothstep(radius - 0.015, radius, length(UV - vec2(0.5)));
	float progress = smoothstep(dissolve_start, 0.98, age);
	float n = texture(noise_texture, UV * 1.3).r;
	float threshold = mix(-0.02, 1.02, progress);
	float remaining = smoothstep(threshold, threshold + 0.025, n);
	if (!dissolve_enabled || progress <= 0.0) { remaining = 1.0; }
	if (dissolve_enabled && progress >= 1.0) { remaining = 0.0; }
	float phase = random_phase ? birth_phase : 0.0;
	// 随机相位只改变闪烁，不把寿命进度循环或打乱。
	float pulse = pulse_hz <= 0.0 ? 1.0 : 0.75 + 0.25 * sin(TAU * (lesson_time * pulse_hz + phase));
	vec3 tint = mix(vec3(1.0), vec3(0.85, 0.65, 1.0), age);
	vec4 source = preserve_color ? incoming : vec4(1.0);
	if (debug_view == 1) {
		float marker = 1.0 - step(0.38, length(UV - vec2(0.5)));
		COLOR = vec4(vec3(age), marker);
	} else if (debug_view == 2) {
		float marker = 1.0 - step(0.38, length(UV - vec2(0.5)));
		COLOR = vec4(vec3(birth_phase), marker);
	} else {
		COLOR = vec4(source.rgb * tint * pulse, source.a * disk * remaining);
	}
}

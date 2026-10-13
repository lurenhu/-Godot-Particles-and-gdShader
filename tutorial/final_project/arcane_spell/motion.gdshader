shader_type particles;
render_mode disable_velocity;

uniform float effect_time = 0.0;
uniform float radius = 120.0;
uniform float intensity = 1.0;
uniform vec2 target = vec2(400.0, 0.0);

float random_value(uint value) {
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	value = ((value >> uint(16)) ^ value) * uint(73244475);
	value = (value >> uint(16)) ^ value;
	return float(value & uint(16777215)) / 16777216.0;
}

void start() {
	TRANSFORM = mat4(1.0);
	VELOCITY = vec3(0.0);
	CUSTOM = vec4(0.0, random_value(INDEX + RANDOM_SEED), mix(0.65, 1.25, random_value(INDEX + RANDOM_SEED + uint(37))), float(INDEX % uint(2)));
	COLOR = vec4(1.0, 1.0, 1.0, 0.0);
}

void process() {
	// 全部粒子同时出生，视觉年龄来自组件时钟；不读取全局 TIME。
	CUSTOM.x = clamp(effect_time / 2.6, 0.0, 1.0);
	float phase = CUSTOM.y;
	float angle = phase * TAU;
	vec2 pos;
	float opacity;
	if (effect_time < 0.8) {
		float q = effect_time / 0.8;
		angle += q * TAU * 1.5;
		pos = vec2(cos(angle), sin(angle)) * mix(radius * CUSTOM.z, 9.0, q);
		opacity = smoothstep(0.0, 0.15, q);
	} else if (effect_time < 1.3) {
		float q = clamp((effect_time - 0.8 - phase * 0.06) / 0.5, 0.0, 1.0);
		pos = target * smoothstep(0.0, 1.0, q) + vec2(cos(angle), sin(angle)) * (4.0 + 8.0 * phase);
		opacity = 1.0;
	} else {
		float age = (effect_time - 1.3) / 1.3;
		float travel = (1.0 - exp(-3.0 * age)) * radius * CUSTOM.z;
		pos = target + vec2(cos(angle), sin(angle)) * travel + vec2(0.0, 25.0 * age * age);
		opacity = 1.0 - smoothstep(0.2, 1.0, age);
	}
	TRANSFORM[3].xy = pos;
	float size = CUSTOM.z * 0.3 * sqrt(intensity);
	TRANSFORM[0].x = size;
	TRANSFORM[1].y = size;
	COLOR = vec4(vec3(1.0), opacity);
}

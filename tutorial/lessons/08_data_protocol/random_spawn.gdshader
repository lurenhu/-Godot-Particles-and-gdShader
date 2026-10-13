shader_type particles;
render_mode disable_velocity;
#include "protocol.gdshaderinc"

uniform bool use_number = true;
uniform bool resample_each_step = false;

// 教学用整数混合函数，不用于密码学，也不承诺统计独立。
uint mix_bits(uint value) {
	value = value ^ (value >> uint(16));
	value = value * uint(73244475);
	value = value ^ (value >> uint(16));
	value = value * uint(73244475);
	return value ^ (value >> uint(16));
}

float random01(uint identity, uint salt, uint emitter_seed) {
	uint bits = mix_bits(identity ^ mix_bits(emitter_seed + salt));
	// 保留 24 位，避免 uint 转 float 后在上端舍入到 1。
	return float(bits & uint(16777215)) / 16777216.0;
}

vec3 birth_data(uint identity, uint emitter_seed) {
	return vec3(random01(identity, uint(11), emitter_seed),
		mix(0.65, 1.25, random01(identity, uint(37), emitter_seed)),
		step(0.5, random01(identity, uint(79), emitter_seed)));
}

void start() {
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xy = vec2(float(INDEX % uint(4)) - 1.5,
		float(INDEX / uint(4)) - 1.0) * vec2(90.0, 100.0);
	VELOCITY = vec3(0.0);
	COLOR = vec4(1.0);
	uint identity = use_number ? NUMBER : INDEX;
	vec3 data = birth_data(identity, RANDOM_SEED);
	CUSTOM = vec4(0.0, data.x, data.y, data.z);
	ACTIVE = true;
}

void process() {
	CUSTOM[DATA_AGE] += DELTA / LIFETIME;
	if (resample_each_step) {
		// 故意把变化的年龄时间桶混入 key，破坏出生属性的稳定性。
		uint tick = uint(floor(CUSTOM[DATA_AGE] * LIFETIME * 60.0));
		uint identity = use_number ? NUMBER : INDEX;
		vec3 data = birth_data(identity ^ mix_bits(tick + uint(101)), RANDOM_SEED);
		CUSTOM[DATA_PHASE] = data.x;
		CUSTOM[DATA_SIZE] = data.y;
		CUSTOM[DATA_KIND] = data.z;
	}
	COLOR.a = 1.0 - smoothstep(0.8, 1.0, CUSTOM[DATA_AGE]);
	if (CUSTOM[DATA_AGE] >= 1.0) {
		ACTIVE = false;
	}
}

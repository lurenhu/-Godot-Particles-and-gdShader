shader_type particles;
render_mode disable_velocity;
#include "../08_data_protocol/protocol.gdshaderinc"

uniform float spawn_offset_x = 0.0;

void start() {
	float phase = fract(float(INDEX) * 0.61803399);
	TRANSFORM = mat4(1.0);
	VELOCITY = vec3(0.0);
	CUSTOM = vec4(0.0, phase, mix(0.65, 1.25, fract(float(INDEX) * 0.37)), 0.0);
	COLOR = vec4(1.0);
	ACTIVE = true;
}

void process() {
	CUSTOM[DATA_AGE] += DELTA / LIFETIME;
	float age = clamp(CUSTOM[DATA_AGE], 0.0, 1.0);
	float phase = CUSTOM[DATA_PHASE];
	float angle = TAU * phase + age * 1.4;
	float radius = mix(0.35, 1.1, fract(float(INDEX) * 0.43));
	// 直接由年龄计算轨迹，不再积分 VELOCITY；3D 的 +Y 朝上。
	TRANSFORM[3].xyz = vec3(spawn_offset_x + cos(angle) * radius, 0.3 + age * 2.6, sin(angle) * radius);
	float scale = CUSTOM[DATA_SIZE];
	TRANSFORM[0].x = scale;
	TRANSFORM[1].y = scale;
	TRANSFORM[2].z = scale;
	float alpha = smoothstep(0.0, 0.12, age) * (1.0 - smoothstep(0.65, 1.0, age));
	COLOR = vec4(mix(vec3(0.12, 0.7, 1.0), vec3(0.8, 0.3, 1.0), phase), alpha);
	if (age >= 1.0) { ACTIVE = false; }
}

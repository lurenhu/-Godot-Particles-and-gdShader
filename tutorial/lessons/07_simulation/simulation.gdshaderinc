uniform float launch_speed = 170.0;
uniform float gravity_y = 220.0;
uniform float end_age = 1.0;
uniform bool reset_velocity_each_step = false;
uniform bool fade_enabled = true;
uniform bool age_debug = false;

vec3 initial_velocity(uint slot) {
	// 九个固定方向排除随机性干扰；本课节点 amount 固定为 9。
	float angle = mix(-0.6, 0.6, float(slot % uint(9)) / 8.0);
	return vec3(sin(angle), -cos(angle), 0.0) * launch_speed;
}

void start() {
	// 仅针对本课 local_coords=true 的普通发射；不处理外部 emit_particle 数据。
	TRANSFORM = mat4(1.0);
	TRANSFORM[0].x = 0.65;
	TRANSFORM[1].y = 0.65;
	VELOCITY = initial_velocity(INDEX);
	COLOR = vec4(0.25, 0.85, 1.0, 1.0);
	// 只约定 y 为归一化年龄；不使用序列帧或旋转通道。
	CUSTOM = vec4(0.0);
	ACTIVE = true;
}

void process() {
#ifdef MANUAL_MOVE
	// 对齐本版本自动位移：先用保存的速度移动，再更新速度。
	// 出生这一步不位移，避免比自动版本多走一次。
	if (!RESTART) {
		TRANSFORM[3].xyz += VELOCITY * DELTA;
	}
#endif
	if (reset_velocity_each_step) {
		VELOCITY = initial_velocity(INDEX); // 故意丢弃重力积累。
	}
	VELOCITY += vec3(0.0, gravity_y, 0.0) * DELTA;
	CUSTOM.y += DELTA / LIFETIME;
	float age = clamp(CUSTOM.y, 0.0, 1.0);
	COLOR.rgb = age_debug ? vec3(age) : mix(vec3(0.25, 0.85, 1.0), vec3(1.0, 0.45, 0.15), age);
	COLOR.a = fade_enabled ? 1.0 - smoothstep(0.65, 1.0, age) : 1.0;
	if (CUSTOM.y >= end_age) {
		ACTIVE = false;
	}
}

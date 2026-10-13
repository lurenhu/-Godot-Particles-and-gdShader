shader_type particles;
render_mode disable_velocity;
#include "../08_data_protocol/protocol.gdshaderinc"

uniform vec2 target_local = vec2(0.0);
uniform float radial_accel = 500.0;
uniform float swirl_accel = 260.0;
uniform float damping = 1.8;
uniform float field_radius = 320.0;
uniform float spawn_radius = 160.0;
uniform int debug_view = 0;
uniform bool spawn_at_target = false;
const float CORE_RADIUS = 24.0;
const float MAX_SPEED = 260.0;

void start() {
	float phase = fract(float(INDEX) * 0.61803399);
	float angle = TAU * phase;
	float radius = spawn_radius * mix(0.75, 1.25, fract(float(INDEX) * 0.37));
	TRANSFORM = mat4(1.0);
	TRANSFORM[3].xy = spawn_at_target ? target_local : vec2(cos(angle), sin(angle)) * radius;
	VELOCITY = vec3(0.0);
	COLOR = vec4(1.0);
	// 沿用第八课协议；phase 在本课用于确定初始角度，kind 固定为圆点。
	CUSTOM = vec4(0.0, phase, mix(0.65, 1.25, phase), 0.0);
	ACTIVE = true;
}

void process() {
	vec2 offset = target_local - TRANSFORM[3].xy;
	float distance_to_target = length(offset);
	// 核心区长度逐渐降到零；这里故意不是处处单位长度的 normalize。
	vec2 inward = offset / max(distance_to_target, CORE_RADIUS);
	vec2 tangent = vec2(-inward.y, inward.x);
	float falloff = 1.0 - smoothstep(field_radius * 0.65, field_radius, distance_to_target);
	vec2 acceleration = (inward * radial_accel + tangent * swirl_accel) * falloff;
	// 半隐式 Euler，加上指数阻尼，再限制速度；只有这里负责位置推进。
	VELOCITY.xy += acceleration * DELTA;
	VELOCITY.xy *= exp(-damping * DELTA);
	float speed = length(VELOCITY.xy);
	if (speed > MAX_SPEED) {
		VELOCITY.xy *= MAX_SPEED / speed;
	}
	TRANSFORM[3].xy += VELOCITY.xy * DELTA;
	CUSTOM[DATA_AGE] += DELTA / LIFETIME;
	float age = clamp(CUSTOM[DATA_AGE], 0.0, 1.0);
	vec3 tint = mix(vec3(0.25, 0.85, 1.0), vec3(0.8, 0.4, 1.0), CUSTOM[DATA_PHASE]);
	if (debug_view == 1) {
		tint = mix(vec3(0.1, 0.3, 1.0), vec3(1.0, 0.25, 0.05), length(VELOCITY.xy) / MAX_SPEED);
	} else if (debug_view == 2) {
		// 使用本步更新前的距离，便于对应力场采样位置。
		tint = vec3(clamp(distance_to_target / field_radius, 0.0, 1.0));
	}
	COLOR = vec4(tint, debug_view == 0 ? 1.0 - smoothstep(0.75, 1.0, age) : 1.0);
	if (age >= 1.0) { ACTIVE = false; }
}

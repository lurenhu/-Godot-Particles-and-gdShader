shader_type canvas_item;
render_mode unshaded, blend_mix;
#include "protocol.gdshaderinc"

uniform int debug_view = 0;
uniform bool wrong_decode = false;
varying vec4 particle_data;

void vertex() {
	particle_data = INSTANCE_CUSTOM;
	if (wrong_decode) {
		// 模拟协议不匹配：绘制端误把相位当大小、大小当相位。
		particle_data[DATA_PHASE] = INSTANCE_CUSTOM[DATA_SIZE];
		particle_data[DATA_SIZE] = INSTANCE_CUSTOM[DATA_PHASE];
	}
	// 调试时使用相同尺寸，避免灰度比较受到面积变化干扰。
	VERTEX *= 2.2 * (debug_view == 0 ? particle_data[DATA_SIZE] : 1.0);
}

void fragment() {
	vec4 incoming = COLOR;
	float age = clamp(particle_data[DATA_AGE], 0.0, 1.0);
	float phase = particle_data[DATA_PHASE];
	float initial_size = particle_data[DATA_SIZE];
	float kind = particle_data[DATA_KIND];
	float d = length(UV - vec2(0.5));
	float disk = 1.0 - smoothstep(0.37, 0.42, d);
	float ring = disk * smoothstep(0.23, 0.28, d);
	vec3 tint = kind < 0.5 ? vec3(0.25, 0.9, 1.0) : vec3(1.0, 0.6, 0.22);
	if (debug_view > 0) {
		vec3 value = vec3(age);
		if (debug_view == 2) { value = vec3(phase); }
		if (debug_view == 3) { value = vec3(clamp((initial_size - 0.65) / 0.6, 0.0, 1.0)); }
		if (debug_view == 4) { value = tint; }
		// 原始通道观察忽略淡出和随机尺寸，但保留粒子的存在状态。
		COLOR = vec4(value, disk);
	} else {
		float pulse = 0.75 + 0.25 * sin(TAU * (age * 3.0 + phase));
		float mask = kind < 0.5 ? disk : ring;
		COLOR = vec4(incoming.rgb * tint * pulse, incoming.a * mask);
	}
}

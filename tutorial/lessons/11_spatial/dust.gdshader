shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
#include "../08_data_protocol/protocol.gdshaderinc"

uniform bool billboard = true;
uniform bool ignore_particle_color = false;
uniform bool show_card = false;
uniform float emission_energy : hint_range(0.0, 6.0) = 2.0;
varying float particle_age;

void vertex() {
	particle_age = INSTANCE_CUSTOM[DATA_AGE];
	if (billboard) {
		// 保留每颗粒子的世界位置与缩放，用相机轴替换朝向。
		vec3 scales = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
		mat4 facing = mat4(
			vec4(INV_VIEW_MATRIX[0].xyz * scales.x, 0.0),
			vec4(INV_VIEW_MATRIX[1].xyz * scales.y, 0.0),
			vec4(INV_VIEW_MATRIX[2].xyz * scales.z, 0.0),
			MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = VIEW_MATRIX * facing;
		MODELVIEW_NORMAL_MATRIX = mat3(VIEW_MATRIX * mat4(
			vec4(INV_VIEW_MATRIX[0].xyz, 0.0),
			vec4(INV_VIEW_MATRIX[1].xyz, 0.0),
			vec4(INV_VIEW_MATRIX[2].xyz, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0)));
	}
}

void fragment() {
	vec4 tint = ignore_particle_color ? vec4(1.0) : COLOR;
	float mask = 1.0 - smoothstep(0.1, 0.48, length(UV - 0.5));
	float pulse = 0.75 + 0.25 * sin(particle_age * TAU);
	ALBEDO = tint.rgb * 0.25;
	ROUGHNESS = 1.0;
	EMISSION = tint.rgb * emission_energy * pulse;
	ALPHA = tint.a * (show_card ? 0.5 : mask);
}

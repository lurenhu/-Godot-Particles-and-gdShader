shader_type spatial;
render_mode unshaded, blend_mix;

// 本课使用内置 ParticleProcessMaterial，不接入第八课的自定义协议。
varying float age;

void vertex() {
	age = INSTANCE_CUSTOM.y;
}

void fragment() {
	ALBEDO = vec3(0.12, 0.85, 1.0) * COLOR.rgb;
	ALPHA = COLOR.a * (1.0 - smoothstep(0.35, 1.0, age));
}

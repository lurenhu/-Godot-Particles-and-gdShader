shader_type canvas_item;
render_mode blend_add;
uniform vec4 tint : source_color = vec4(0.25, 0.7, 1.0, 1.0);
varying float kind;

void vertex() {
	kind = INSTANCE_CUSTOM.w;
}

void fragment() {
	float d = length(UV - 0.5);
	float shape = 1.0 - smoothstep(0.1, 0.48, d);
	if (kind > 0.5) {
		shape *= smoothstep(0.1, 0.25, d);
	}
	COLOR *= vec4(tint.rgb, tint.a * shape);
}

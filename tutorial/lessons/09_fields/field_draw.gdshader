shader_type canvas_item;
render_mode unshaded;
#include "../08_data_protocol/protocol.gdshaderinc"

void vertex() {
	VERTEX *= INSTANCE_CUSTOM[DATA_SIZE] * 0.65;
}

void fragment() {
	vec4 incoming = COLOR;
	float mask = 1.0 - smoothstep(0.2, 0.48, length(UV - vec2(0.5)));
	COLOR = vec4(incoming.rgb, incoming.a * mask);
}

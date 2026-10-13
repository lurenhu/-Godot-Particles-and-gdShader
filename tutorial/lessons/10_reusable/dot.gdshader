shader_type canvas_item;
render_mode unshaded;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
 vec4 incoming = COLOR;
 float mask = 1.0 - smoothstep(0.08, 0.48, length(UV - 0.5));
 COLOR = incoming * tint * vec4(1.0, 1.0, 1.0, mask);
}

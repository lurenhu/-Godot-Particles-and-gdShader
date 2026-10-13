shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

void fragment() {
	vec2 offset = vec2(sin(SCREEN_UV.y * 60.0), cos(SCREEN_UV.x * 50.0)) * SCREEN_PIXEL_SIZE * 3.0;
	COLOR = texture(screen_tex, SCREEN_UV + offset);
}

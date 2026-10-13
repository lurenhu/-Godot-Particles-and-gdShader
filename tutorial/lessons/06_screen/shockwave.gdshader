shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 center_uv = vec2(0.5);
uniform float progress : hint_range(0.0, 1.0) = 0.45;
uniform float strength_px = 18.0;
uniform float width_px = 22.0;
uniform bool wrong_uv = false;
uniform bool opaque_outside = false;
uniform int debug_view = 0;

void fragment() {
	// 在渲染目标像素空间计算距离，避免长窗口把圆拉成椭圆。
	vec2 delta_px = (SCREEN_UV - center_uv) / SCREEN_PIXEL_SIZE;
	float distance_px = length(delta_px);
	float short_side = min(1.0 / SCREEN_PIXEL_SIZE.x, 1.0 / SCREEN_PIXEL_SIZE.y);
	float radius_px = mix(12.0, short_side * 0.32, progress);
	float ring = 1.0 - smoothstep(width_px * 0.5, width_px, abs(distance_px - radius_px));
	float envelope = smoothstep(0.0, 0.08, progress) * (1.0 - smoothstep(0.7, 1.0, progress));
	float mask = ring * envelope;
	vec2 direction = delta_px / max(distance_px, 0.001);
	vec2 offset_uv = direction * strength_px * mask * SCREEN_PIXEL_SIZE;
	// 故意把当前全屏矩形的 UV 压缩到局部区域，模拟局部卡片 UV 误用。
	vec2 base_uv = wrong_uv ? UV * 0.65 + vec2(0.15, 0.05) : SCREEN_UV;
	vec2 sample_uv = clamp(base_uv + offset_uv, SCREEN_PIXEL_SIZE * 0.5,
		vec2(1.0) - SCREEN_PIXEL_SIZE * 0.5);
	if (debug_view == 1) {
		COLOR = vec4(vec3(mask), 1.0);
	} else if (debug_view == 2) {
		COLOR = vec4(direction * 0.5 + 0.5, mask, 1.0);
	} else {
		// 零遮罩不写回旧拷贝，否则 B 会擦除 A 的非重叠部分。
		if (mask <= 0.0 && !opaque_outside) {
			discard;
		}
		COLOR = vec4(textureLod(screen_texture, sample_uv, 0.0).rgb, 1.0);
	}
}

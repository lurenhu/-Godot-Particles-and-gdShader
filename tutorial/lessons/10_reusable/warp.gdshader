shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float effect_time = 0.0;
uniform float intensity = 1.0;
varying vec2 canvas_offset;
void vertex() {
 // 卡片以节点原点为中心；w=0 只变换方向，包含实例旋转。
 canvas_offset = (CANVAS_MATRIX * MODEL_MATRIX * vec4(VERTEX, 0.0, 0.0)).xy;
}
void fragment() {
 float p = clamp(effect_time / 0.6, 0.0, 1.0);
 vec2 delta = UV - 0.5;
 float d = length(delta);
 float mask = (1.0 - smoothstep(0.012, 0.035, abs(d - mix(0.03, 0.37, p) * intensity))) * sin(p * PI);
 if (p <= 0.0 || p >= 1.0 || mask <= 0.0) { discard; }
 vec2 offset = canvas_offset / max(length(canvas_offset), 0.001) * 10.0 * intensity * mask * SCREEN_PIXEL_SIZE;
 vec2 sample_uv = clamp(SCREEN_UV + offset, SCREEN_PIXEL_SIZE * 0.5, vec2(1.0) - SCREEN_PIXEL_SIZE * 0.5);
 COLOR = vec4(textureLod(screen_texture, sample_uv, 0.0).rgb, 1.0);
}

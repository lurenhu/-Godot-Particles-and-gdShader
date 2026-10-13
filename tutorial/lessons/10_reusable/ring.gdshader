shader_type canvas_item;
render_mode unshaded;
uniform float effect_time = 0.0;
uniform float intensity = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
void fragment() {
 float p = clamp(effect_time / 0.9, 0.0, 1.0);
 float radius = mix(0.04, 0.37, p) * intensity;
 float ring = 1.0 - smoothstep(0.006, 0.016, abs(length(UV - 0.5) - radius));
 COLOR = vec4(tint.rgb, tint.a * ring * sin(p * PI) * (1.0 - p));
}

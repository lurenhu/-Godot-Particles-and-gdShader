shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec2 rect_size = vec2(300.0);
uniform bool correct_aspect = true;
uniform int shape = 0; // 0 圆环，1 扇形，2 胶囊，3 并集，4 差集
uniform int debug_view = 0; // 0 成品，1 UV，2 有符号场，3 遮罩
uniform float radius : hint_range(0.1, 0.4) = 0.28;
uniform float thickness : hint_range(0.02, 0.16) = 0.08;
uniform float angle_degrees : hint_range(-180.0, 180.0) = 0.0;
uniform float sector_degrees : hint_range(15.0, 180.0) = 90.0;
uniform float softness_px : hint_range(0.0, 12.0) = 2.0;
uniform bool derivative_aa = true;
uniform vec4 tint : source_color = vec4(0.2, 0.8, 1.0, 1.0);

vec2 rotate_point(vec2 p, float a) {
	float c = cos(a);
	float s = sin(a);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}

float capsule_sdf(vec2 p, vec2 a, vec2 b, float r) {
	vec2 ab = b - a;
	float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.000001), 0.0, 1.0);
	return length(p - (a + h * ab)) - r;
}

void fragment() {
	vec4 incoming = COLOR;
	float short_side = max(min(rect_size.x, rect_size.y), 1.0);
	vec2 p = UV - vec2(0.5);
	if (correct_aspect) {
		p *= rect_size / short_side;
	}
	// 逆向变换采样坐标，得到正向旋转的图案。
	p = rotate_point(p, -radians(angle_degrees));
	float ring = abs(length(p) - radius) - thickness * 0.5;
	float capsule = capsule_sdf(p, vec2(-radius, 0.0), vec2(radius, 0.0), thickness * 0.5);
	float half_angle = radians(sector_degrees) * 0.5;
	float wedge = max(dot(p, vec2(-sin(half_angle), cos(half_angle))),
		dot(p, vec2(-sin(half_angle), -cos(half_angle))));
	// 圆与两个半平面的交集：符号正确，但角点外侧不保证精确欧氏距离。
	float sector = max(length(p) - radius, wedge);
	float d = ring;
	if (shape == 1) { d = sector; }
	else if (shape == 2) { d = capsule; }
	else if (shape == 3) { d = min(ring, capsule); }
	else if (shape == 4) { d = max(ring, -capsule); }
	float pixel_width = fwidth(d);
	float width = softness_px / short_side;
	if (derivative_aa) { width = max(width, pixel_width); }
	// smoothstep 两个边界不能相等，零柔边用 step。
	float mask;
	if (width > 0.000001) { mask = 1.0 - smoothstep(-width * 0.5, width * 0.5, d); }
	else { mask = 1.0 - step(0.0, d); }
	if (debug_view == 1) {
		COLOR = vec4(UV, 0.0, 1.0);
	} else if (debug_view == 2) {
		float band = 0.4 + 0.6 * abs(sin(d * 90.0));
		vec3 side_color = d < 0.0 ? vec3(0.1, 0.65, 1.0) : vec3(1.0, 0.4, 0.15);
		float boundary = 1.0 - smoothstep(0.0, max(pixel_width, 0.002), abs(d));
		COLOR = vec4(mix(side_color * band, vec3(1.0), boundary), 1.0);
	} else if (debug_view == 3) {
		COLOR = vec4(vec3(mask), 1.0);
	} else {
		COLOR = vec4(incoming.rgb * tint.rgb, incoming.a * tint.a * mask);
	}
}

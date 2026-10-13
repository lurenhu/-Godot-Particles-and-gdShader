shader_type particles;
render_mode disable_velocity;
#include "../08_data_protocol/protocol.gdshaderinc"
uniform bool smoke = false;
uniform float intensity = 1.0;
void start() {
 float phase = fract(float(INDEX) * 0.61803399);
 float angle = TAU * phase;
 vec2 radial = vec2(cos(angle), sin(angle));
 TRANSFORM = mat4(1.0);
 TRANSFORM[3].xy = radial * (smoke ? 15.0 : 3.0);
 VELOCITY = vec3((radial * (smoke ? 38.0 : 210.0) + vec2(smoke ? 0.0 : 70.0, 0.0)) * intensity, 0.0);
 CUSTOM = vec4(0.0, phase, 1.0, 0.0);
 COLOR = vec4(1.0);
 ACTIVE = true;
}
void process() {
 CUSTOM[DATA_AGE] += DELTA / LIFETIME;
 float age = clamp(CUSTOM[DATA_AGE], 0.0, 1.0);
 if (smoke) { VELOCITY.y -= 20.0 * DELTA; }
 VELOCITY.xy *= exp(-(smoke ? 0.6 : 2.0) * DELTA);
 TRANSFORM[3].xy += VELOCITY.xy * DELTA;
 float size = smoke ? mix(1.0, 3.2, age) : mix(0.6, 0.15, age);
 TRANSFORM[0].x = size;
 TRANSFORM[1].y = size;
 COLOR = vec4(vec3(smoke ? 0.55 : 1.0), (1.0 - smoothstep(0.15, 1.0, age)) * (smoke ? 0.28 : 1.0));
 if (age >= 1.0) { ACTIVE = false; }
}

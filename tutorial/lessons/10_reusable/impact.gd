extends Node2D
## 调用前先 add_child；position 参数属于此节点父级的局部空间。
signal finished
@export var free_on_finish := false
@onready var burst: GPUParticles2D = $Burst
@onready var smoke: GPUParticles2D = $Smoke
@onready var ring: ColorRect = $Ring
@onready var warp: ColorRect = $Warp
var timeline: Tween
var effect_time := 0.0
var playing := false
var paused := false
var completed: Dictionary = {}

func _ready() -> void:
	# 仅复制要修改的材质；只读 Shader、纹理仍可共享。
	for layer in [burst, smoke, ring, warp]:
		layer.material = layer.material.duplicate()
	for emitter in [burst, smoke]:
		emitter.process_material = emitter.process_material.duplicate()
	burst.finished.connect(_layer_done.bind("burst"))
	smoke.finished.connect(_layer_done.bind("smoke"))
	hide()

func play(at: Vector2, direction: Vector2, intensity: float, color: Color) -> void:
	assert(is_node_ready(), "先把特效加入场景树，再调用 play")
	if timeline: timeline.kill()
	playing = false
	completed.clear()
	position = at
	rotation = direction.angle() if direction.length_squared() > 0.000001 else 0.0
	var power := clampf(intensity, 0.5, 1.2)
	for layer in [burst, smoke, ring]:
		layer.material.set_shader_parameter("tint", color)
	for layer in [ring, warp]:
		layer.material.set_shader_parameter("intensity", power)
	for emitter in [burst, smoke]:
		emitter.process_material.set_shader_parameter("intensity", power)
		emitter.speed_scale = 1.0
	_set_time(0.0)
	paused = false
	playing = true
	show()
	burst.restart(true)
	smoke.restart(true)
	timeline = create_tween()
	timeline.tween_method(_set_time, 0.0, 0.9, 0.9)
	timeline.tween_callback(_layer_done.bind("visual"))

func set_paused(value: bool) -> void:
	paused = value
	if not playing: return
	if timeline:
		if value: timeline.pause()
		else: timeline.play()
	for emitter in [burst, smoke]:
		emitter.speed_scale = 0.0 if value else 1.0

func _set_time(value: float) -> void:
	effect_time = value
	ring.material.set_shader_parameter("effect_time", value)
	warp.material.set_shader_parameter("effect_time", value)

func _layer_done(layer: String) -> void:
	if not playing: return
	completed[layer] = true
	if completed.size() != 3: return
	playing = false
	hide()
	# 释放决定先固定；默认保留实例供下次 play 使用。
	if free_on_finish: queue_free()
	finished.emit()

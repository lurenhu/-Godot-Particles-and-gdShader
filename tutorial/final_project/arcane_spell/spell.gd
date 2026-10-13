extends Node2D
## play 的起点、终点都属于本节点父级的局部空间。
signal impacted(run_id: int, at: Vector2)
signal finished(run_id: int)

enum Quality { LOW, MEDIUM, HIGH }
const DURATION := 2.6
const IMPACT_TIME := 1.3
@export var free_on_finish := false
var particles: GPUParticles2D
var core: ColorRect
var motion: ShaderMaterial
var appearance: ShaderMaterial
var core_material: ShaderMaterial
var effect_time := 0.0
var playing := false
var paused := false
var run_id := 0
var phase := "idle"
var playback_speed := 1.0
var target_offset := Vector2.ZERO
var target_position := Vector2.ZERO
var impact_sent := false
var configuration: Dictionary = {}


func _ready() -> void:
	# 每次实例化都创建独立材质；Shader 与噪声等只读资源共享。
	process_mode = Node.PROCESS_MODE_PAUSABLE
	motion = ShaderMaterial.new()
	motion.shader = preload("res://tutorial/final_project/arcane_spell/motion.gdshader")
	appearance = ShaderMaterial.new()
	appearance.shader = preload("res://tutorial/final_project/arcane_spell/spark.gdshader")
	core_material = ShaderMaterial.new()
	core_material.shader = preload("res://tutorial/final_project/arcane_spell/core.gdshader")
	core_material.set_shader_parameter("noise_map", preload("res://tutorial/final_project/arcane_spell/noise.tres"))
	particles = GPUParticles2D.new()
	particles.name = "OrbitAndBurst"
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 1.0
	# GPU 槽位寿命只是上限；视觉播放与结束由统一时钟负责。
	particles.lifetime = 120.0
	particles.local_coords = true
	particles.fixed_fps = 60
	particles.interpolate = false
	particles.use_fixed_seed = true
	particles.texture = preload("res://tutorial/final_project/arcane_spell/particle.svg")
	particles.process_material = motion
	particles.material = appearance
	add_child(particles)
	core = ColorRect.new()
	core.name = "GlyphAndImpact"
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	core.material = core_material
	add_child(core)
	cancel()


func play(from: Vector2, to: Vector2, options: Dictionary = {}) -> int:
	assert(is_node_ready(), "先 add_child，再调用 play")
	assert(from.is_finite() and to.is_finite(), "位置必须为有限坐标")
	cancel()
	run_id += 1
	position = from
	target_position = to
	target_offset = to - from
	configuration = {
		"color": options.get("color", Color("52bdff")),
		"intensity": clampf(float(options.get("intensity", 1.0)), 0.5, 1.5),
		"radius": clampf(float(options.get("radius", 120.0)), 60.0, 180.0),
		"speed": clampf(float(options.get("speed", 1.0)), 0.25, 2.0),
		"quality": clampi(int(options.get("quality", Quality.HIGH)), Quality.LOW, Quality.HIGH),
		"seed": int(options.get("seed", 137)),
		"oversized_quad": bool(options.get("oversized_quad", false))
	}
	playback_speed = configuration.speed
	var quality: int = configuration.quality
	particles.amount = [64, 128, 256][quality]
	particles.fixed_fps = 30 if quality == Quality.LOW else 60
	particles.seed = configuration.seed
	particles.visibility_rect = Rect2(Vector2.ZERO, Vector2.ZERO).expand(target_offset).grow(configuration.radius * 1.5 + 40.0)
	for material in [motion, core_material]:
		material.set_shader_parameter("radius", configuration.radius)
		material.set_shader_parameter("intensity", configuration.intensity)
	for material in [appearance, core_material]:
		material.set_shader_parameter("tint", configuration.color)
	motion.set_shader_parameter("target", target_offset)
	core_material.set_shader_parameter("noise_samples", quality + 1)
	var extent: float = 1024.0 if configuration.oversized_quad else configuration.radius * 2.0 + 24.0
	core.size = Vector2.ONE * extent
	core_material.set_shader_parameter("extent", extent)
	effect_time = 0.0
	impact_sent = false
	paused = false
	playing = true
	show()
	_update_visuals()
	particles.restart(true)
	_sync_pause()
	return run_id


func cancel() -> void:
	playing = false
	paused = false
	phase = "idle"
	hide()
	if is_instance_valid(particles):
		particles.emitting = false
		particles.speed_scale = 0.0


func set_paused(value: bool) -> void:
	paused = value
	_sync_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_UNPAUSED:
		_sync_pause()


func _sync_pause() -> void:
	if is_instance_valid(particles):
		particles.speed_scale = 0.0 if not playing or paused or get_tree().paused else 1.0


func _process(delta: float) -> void:
	if not playing or paused:
		return
	effect_time = minf(effect_time + delta * playback_speed, DURATION)
	_update_visuals()
	var current_run := run_id
	if effect_time >= IMPACT_TIME and not impact_sent:
		impact_sent = true
		impacted.emit(current_run, target_position)
		# 信号接收方可能立即重播或取消，旧调用不得结束新一轮。
		if run_id != current_run or not playing:
			return
	if effect_time >= DURATION:
		cancel()
		if free_on_finish:
			queue_free()
		finished.emit(current_run)


func _update_visuals() -> void:
	motion.set_shader_parameter("effect_time", effect_time)
	core_material.set_shader_parameter("effect_time", effect_time)
	var center := Vector2.ZERO
	if effect_time < 0.8:
		phase = "charge"
	elif effect_time < IMPACT_TIME:
		phase = "release"
		center = target_offset * smoothstep(0.0, 1.0, (effect_time - 0.8) / 0.5)
	else:
		phase = "impact" if effect_time < 1.48 else "fade"
		center = target_offset
	core.position = center - core.size * 0.5

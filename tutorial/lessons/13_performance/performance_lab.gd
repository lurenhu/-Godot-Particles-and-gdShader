extends Node3D

const BASE := {"amount": 4096, "size": 0.35, "samples": 4, "fps": 60, "turbulence": false, "collision": false, "warp": false}
const CASES := [
	["基线 / 高档", {}],
	["数量减半", {"amount": 2048}],
	["卡片边长加倍", {"size": 0.7}],
	["噪声采样 8 次", {"samples": 8}],
	["模拟 30 Hz", {"fps": 30}],
	["启用湍流", {"turbulence": true}],
	["启用碰撞", {"collision": true}],
	["全屏扭曲", {"warp": true}],
	["低档", {"amount": 1024, "samples": 1, "fps": 30}],
	["中档", {"amount": 2048, "samples": 2}]
]
var particles: GPUParticles3D
var motion: ParticleProcessMaterial
var draw: ShaderMaterial
var quad: QuadMesh
var warp: ColorRect
var copy: BackBufferCopy
var selector: OptionButton
var status: Label
var controls: Array[Button] = []
var busy := false
var rows: Array = []
var benchmark_size := Vector2i.ZERO
var initial_vsync: DisplayServer.VSyncMode
var initial_max_fps: int
var viewport_rid: RID


func _ready() -> void:
	initial_vsync = DisplayServer.window_get_vsync_mode()
	initial_max_fps = Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 240
	viewport_rid = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	_build_world()
	_build_ui()
	_apply(0)
	if "--lesson-test" in OS.get_cmdline_user_args():
		call_deferred("_run", true, true)
	elif "--benchmark" in OS.get_cmdline_user_args():
		call_deferred("_run", true, false)


func _exit_tree() -> void:
	DisplayServer.window_set_vsync_mode(initial_vsync)
	Engine.max_fps = initial_max_fps


func _build_world() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("071223")
	add_child(environment)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 2.4, 8)
	add_child(camera)
	camera.look_at(Vector3(0, 1.6, 0))
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(10, 0.4, 6)
	var floor_draw := StandardMaterial3D.new()
	floor_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_draw.albedo_color = Color("24344a")
	box.material = floor_draw
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.2
	add_child(floor_mesh)
	var collider := GPUParticlesCollisionBox3D.new()
	collider.size = box.size
	collider.position.y = -0.2
	add_child(collider)
	particles = GPUParticles3D.new()
	particles.name = "MeasuredParticles"
	particles.emitting = false
	particles.position.y = 2.4
	particles.lifetime = 2.0
	particles.use_fixed_seed = true
	particles.seed = 137
	particles.visibility_aabb = AABB(Vector3(-6, -8, -4), Vector3(12, 16, 8))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	motion = ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(1.8, 0.2, 0.5)
	motion.direction = Vector3.UP
	motion.spread = 30
	motion.initial_velocity_min = 0.5
	motion.initial_velocity_max = 1.0
	motion.gravity = Vector3(0, -2, 0)
	motion.collision_bounce = 0.3
	motion.turbulence_influence_min = 0.02
	motion.turbulence_influence_max = 0.02
	motion.turbulence_noise_speed_random = 0.0
	particles.process_material = motion
	draw = ShaderMaterial.new()
	draw.shader = load("res://tutorial/lessons/13_performance/cloud.gdshader")
	# 复用第四课噪声资源；正式采样前预热，避开首次生成与编译。
	draw.set_shader_parameter("noise_map", load("res://tutorial/lessons/04_noise/noise.tres"))
	quad = QuadMesh.new()
	quad.material = draw
	particles.draw_pass_1 = quad
	add_child(particles)
	var effects := CanvasLayer.new()
	add_child(effects)
	copy = BackBufferCopy.new()
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	effects.add_child(copy)
	warp = ColorRect.new()
	warp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	warp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warp_draw := _make_warp_material()
	warp.material = warp_draw
	effects.add_child(warp)


func _make_warp_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://tutorial/lessons/13_performance/warp.gdshader")
	return material


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 12)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "第十三课 · 先测量，再选择质量档位"
	box.add_child(title)
	selector = OptionButton.new()
	for entry in CASES:
		selector.add_item(entry[0])
	if RenderingServer.get_current_rendering_driver_name() == "d3d12":
		selector.set_item_disabled(5, true)
	selector.item_selected.connect(_apply)
	box.add_child(selector)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "重播", func(): _apply(selector.selected))
	_button(row, "测当前项 ×3", func(): _run(false, false))
	_button(row, "测完整对照 ×3", func(): _run(true, false))
	status = Label.new()
	status.text = "3 秒预热 + 2 秒采样 / 轮；VSync 关闭，限帧 240\nD3D12 跳过湍流；完整实验使用 Vulkan。"
	box.add_child(status)


func _button(row: HBoxContainer, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(action)
	row.add_child(button)
	controls.append(button)


func _apply(index: int) -> void:
	var config := BASE.duplicate()
	config.merge(CASES[index][1], true)
	particles.amount = config.amount
	particles.fixed_fps = config.fps
	quad.size = Vector2.ONE * config.size
	draw.set_shader_parameter("samples", config.samples)
	motion.turbulence_enabled = config.turbulence and RenderingServer.get_current_rendering_driver_name() != "d3d12"
	motion.collision_mode = ParticleProcessMaterial.COLLISION_RIGID if config.collision else ParticleProcessMaterial.COLLISION_DISABLED
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if config.warp else BackBufferCopy.COPY_MODE_DISABLED
	warp.visible = config.warp
	selector.select(index)
	particles.restart(true)
	particles.emitting = true


func _stats(values: Array) -> Dictionary:
	if values.is_empty():
		return {"valid_n": 0, "median_ms": null, "p95_ms": null}
	var ordered := values.duplicate()
	ordered.sort()
	return {"valid_n": ordered.size(), "median_ms": ordered[int((ordered.size() - 1) / 2.0)], "p95_ms": ordered[ceili(ordered.size() * 0.95) - 1]}


func _sample(seconds: float) -> Dictionary:
	var wall: Array = []
	var cpu: Array = []
	var gpu: Array = []
	await get_tree().process_frame
	var previous := Time.get_ticks_usec()
	var deadline := previous + int(seconds * 1000000)
	while Time.get_ticks_usec() < deadline:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		wall.append((now - previous) / 1000.0)
		previous = now
		var cpu_ms := RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
		var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
		if cpu_ms > 0 and is_finite(cpu_ms):
			cpu.append(cpu_ms)
		if gpu_ms > 0 and is_finite(gpu_ms):
			gpu.append(gpu_ms)
	return {"wall": _stats(wall), "viewport_cpu": _stats(cpu), "viewport_gpu": _stats(gpu), "raw_wall_ms": wall, "raw_cpu_ms": cpu, "raw_gpu_ms": gpu}


func _run(all_cases: bool, smoke: bool) -> void:
	if busy:
		return
	busy = true
	selector.disabled = true
	for button in controls:
		button.disabled = true
	rows.clear()
	benchmark_size = get_viewport().get_visible_rect().size
	var indices: Array = range(CASES.size()) if all_cases else [selector.selected]
	if RenderingServer.get_current_rendering_driver_name() == "d3d12":
		indices.erase(5)
	var aborted := false
	for repeat in range(1 if smoke else 3):
		# 反转中间轮，减轻固定顺序与温度变化混淆；不声称消除所有漂移。
		var order := indices.duplicate()
		if repeat % 2 == 1:
			order.reverse()
		for index in order:
			_apply(index)
			status.text = "%s / 第 %d 轮：预热中，请保持窗口尺寸" % [CASES[index][0], repeat + 1]
			await get_tree().create_timer(0.4 if smoke else 3.0).timeout
			status.text = "%s / 第 %d 轮：采样中" % [CASES[index][0], repeat + 1]
			var result: Dictionary = await _sample(0.3 if smoke else 2.0)
			if Vector2i(get_viewport().get_visible_rect().size) != benchmark_size:
				aborted = true
				break
			result["case"] = CASES[index][0]
			result["repeat"] = repeat + 1
			var config := BASE.duplicate()
			config.merge(CASES[index][1], true)
			result["config"] = config
			rows.append(result)
		if aborted:
			break
	var report := {"smoke_only": smoke, "aborted": aborted, "date_system": Time.get_datetime_string_from_system(), "engine": Engine.get_version_info().string, "gpu": RenderingServer.get_video_adapter_name(), "driver": RenderingServer.get_current_rendering_driver_name(), "renderer": RenderingServer.get_current_rendering_method(), "viewport_size": [benchmark_size.x, benchmark_size.y], "vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps, "warmup_s": 0.4 if smoke else 3.0, "sample_s": 0.3 if smoke else 2.0, "rows": rows}
	var path := "user://lesson13_%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
		status.text = ("尺寸改变，已中止；部分数据不可作完整对照\n" if aborted else "已保存原始样本与各轮中位数 / P95\n") + ProjectSettings.globalize_path(path)
	else:
		status.text = "保存失败：%s" % FileAccess.get_open_error()
	print("LESSON13_REPORT=", ProjectSettings.globalize_path(path))
	selector.disabled = false
	for button in controls:
		button.disabled = false
	busy = false
	if smoke or "--benchmark" in OS.get_cmdline_user_args():
		assert(not aborted and file != null and rows.size() == indices.size() * (1 if smoke else 3))
		assert(_stats([3.0, 1.0, 2.0]).median_ms == 2.0)
		assert(_stats([]).median_ms == null)
		if smoke:
			_apply(0)
			assert(particles.amount == 4096 and particles.fixed_fps == 60)
			assert(not warp.visible and not motion.turbulence_enabled)
			print("LESSON_13_TEST_OK")
			get_tree().quit()
			return
		for index in [0, 8, 9]:
			_apply(index)
			await get_tree().create_timer(2.2).timeout
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			assert(image != null)
			var name := "preview" if index == 0 else ("low" if index == 8 else "medium")
			assert(image.save_png("res://tutorial/lessons/13_performance/" + name + ".png") == OK)
		print("LESSON_13_TEST_OK")
		get_tree().quit()

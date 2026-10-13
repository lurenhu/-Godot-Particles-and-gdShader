extends Node2D

const SPELL := preload("res://tutorial/final_project/arcane_spell/spell.tscn")
const COLORS := [Color("50cfff"), Color("d881ff"), Color("ffbd63")]
var spells: Array = []
var quality: OptionButton
var color_picker: ColorPickerButton
var power: SpinBox
var radius: SpinBox
var speed: SpinBox
var status: Label
var slot := 0
var automatic := false
var impacts := [0, 0, 0]
var completions := [0, 0, 0]


func _ready() -> void:
	# 演示 UI 与测试协程能在全局暂停时响应；组件显式 PAUSABLE。
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in 3:
		var spell = SPELL.instantiate()
		add_child(spell)
		spell.impacted.connect(func(_id, _at): impacts[index] += 1)
		spell.finished.connect(func(_id): completions[index] += 1)
		spells.append(spell)
	_build_ui()
	_three()
	if "--lesson-test" in OS.get_cmdline_user_args():
		automatic = true
		call_deferred("_verify")
	elif "--benchmark" in OS.get_cmdline_user_args():
		automatic = true
		call_deferred("_benchmark")


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("091323"))
	for x in range(0, int(size.x), 40):
		draw_line(Vector2(x, 200), Vector2(x, size.y), Color("15243a"))
	for y in range(200, int(size.y), 40):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("15243a"))
	for index in 3:
		draw_circle(_origin(index), 5.0, COLORS[index])
		draw_arc(_target(index), 16, 0, TAU, 32, Color("405675"), 1.0)


func _origin(index: int) -> Vector2:
	return Vector2(get_viewport_rect().size.x * 0.25, 300.0 + index * 140.0)


func _target(index: int) -> Vector2:
	return Vector2(get_viewport_rect().size.x * 0.68, 300.0 + index * 140.0)


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
	title.text = "第十四课 · 奥术冲击：蓄力 → 释放 → 命中 → 消散"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "三实例演示", _three)
	_button(row, "重播 A", func(): _play_selected(0, _target(0)))
	_button(row, "暂停 / 恢复 A", func(): spells[0].set_paused(not spells[0].paused))
	_button(row, "全局暂停 / 恢复", func(): get_tree().paused = not get_tree().paused)
	_button(row, "取消全部", _cancel_all)
	row = HBoxContainer.new()
	box.add_child(row)
	color_picker = ColorPickerButton.new()
	color_picker.color = COLORS[0]
	color_picker.custom_minimum_size = Vector2(60, 28)
	row.add_child(color_picker)
	power = _number(row, "强度", 0.5, 1.5, 0.1, 1.0)
	radius = _number(row, "范围", 60, 180, 10, 120)
	speed = _number(row, "速度", 0.25, 2.0, 0.25, 1.0)
	quality = OptionButton.new()
	for text in ["低", "中", "高"]:
		quality.add_item(text)
	quality.select(2)
	row.add_child(quality)
	status = Label.new()
	box.add_child(status)
	var hint := Label.new()
	hint.text = "点击下方场地，按 A/B/C 循环播放；参数在下次播放时生效。"
	box.add_child(hint)


func _number(row: HBoxContainer, label: String, minimum: float, maximum: float, step: float, value: float) -> SpinBox:
	var text := Label.new()
	text.text = label
	row.add_child(text)
	var control := SpinBox.new()
	control.min_value = minimum
	control.max_value = maximum
	control.step = step
	control.value = value
	row.add_child(control)
	return control


func _button(row: HBoxContainer, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(func():
		if not automatic:
			action.call())
	row.add_child(button)


func _process(_delta: float) -> void:
	status.text = "A: %s  B: %s  C: %s   命中 %s / 完成 %s" % [spells[0].phase, spells[1].phase, spells[2].phase, impacts, completions]


func _unhandled_input(event: InputEvent) -> void:
	if automatic:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.position.y > 220:
		_play_selected(slot, event.position)
		slot = (slot + 1) % 3


func _play_selected(index: int, at: Vector2) -> void:
	spells[index].play(_origin(index), at, {"color": color_picker.color, "intensity": power.value, "radius": radius.value, "speed": speed.value, "quality": quality.selected})


func _three(oversized: bool = false) -> void:
	get_tree().paused = false
	for index in 3:
		spells[index].play(_origin(index), _target(index), {"color": COLORS[index], "oversized_quad": oversized})


func _cancel_all() -> void:
	get_tree().paused = false
	for spell in spells:
		spell.cancel()


func _snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	assert(image != null)
	assert(image.save_png("res://tutorial/lessons/14_capstone/" + name + ".png") == OK)


func _pose(time: float) -> void:
	for spell in spells:
		spell.set_paused(true)
		spell.effect_time = time
		spell._update_visuals()
		spell.particles.request_particles_process(0.05)
	for frame in 4:
		await get_tree().process_frame


func _verify() -> void:
	await get_tree().create_timer(0.15).timeout
	assert(spells[0].motion != spells[1].motion and spells[0].core_material != spells[1].core_material)
	assert(spells[0].appearance.get_shader_parameter("tint") == COLORS[0])
	await _pose(0.4)
	await _snapshot("charge")
	await _pose(1.05)
	await _snapshot("release")
	await _pose(1.42)
	await _snapshot("impact")
	await _pose(2.0)
	await _snapshot("fade")
	_three()
	await get_tree().create_timer(0.1).timeout
	spells[0].set_paused(true)
	var frozen: float = spells[0].effect_time
	var moving: float = spells[1].effect_time
	await get_tree().create_timer(0.15).timeout
	assert(spells[0].effect_time == frozen and spells[1].effect_time > moving)
	assert(spells[0].particles.speed_scale == 0.0)
	get_tree().paused = true
	var global_frozen: float = spells[1].effect_time
	await get_tree().create_timer(0.1, true).timeout
	assert(spells[1].effect_time == global_frozen and spells[1].particles.speed_scale == 0.0)
	get_tree().paused = false
	spells[0].set_paused(false)
	assert(spells[0].particles.speed_scale == 1.0)
	_cancel_all()
	var hit_before: int = impacts[0]
	var done_before: int = completions[0]
	spells[0].play(_origin(0), _target(0), {"speed": 2.0})
	await get_tree().create_timer(0.2).timeout
	var newest: int = spells[0].play(_origin(0), _origin(0), {"speed": 2.0, "intensity": 99.0, "radius": 1.0})
	assert(spells[0].configuration.intensity == 1.5 and spells[0].configuration.radius == 60.0)
	await get_tree().create_timer(1.5).timeout
	assert(spells[0].run_id == newest and not spells[0].playing)
	assert(impacts[0] == hit_before + 1 and completions[0] == done_before + 1)
	assert(not spells[0].visible and spells[0].particles.speed_scale == 0.0)
	# 接收命中信号时立即重播，检查旧时钟不会错误结束新一轮。
	spells[0].impacted.connect(func(_id, _at): spells[0].play(_origin(0), _target(0)), CONNECT_ONE_SHOT)
	spells[0].play(_origin(0), _target(0), {"speed": 2.0})
	var old_run: int = spells[0].run_id
	await get_tree().create_timer(0.8).timeout
	assert(spells[0].playing and spells[0].run_id == old_run + 1 and spells[0].effect_time < 0.3)
	_cancel_all()
	var disposable = SPELL.instantiate()
	add_child(disposable)
	disposable.free_on_finish = true
	disposable.play(Vector2.ZERO, Vector2.ZERO, {"speed": 2.0})
	await get_tree().create_timer(1.5).timeout
	assert(not is_instance_valid(disposable))
	for index in 3:
		spells[index].play(_origin(index), _target(index), {"color": COLORS[index], "quality": index})
		assert(spells[index].particles.amount == [64, 128, 256][index])
	await _pose(1.6)
	await _snapshot("quality")
	print("LESSON_14_TEST_OK")
	get_tree().quit()


func _stats(values: Array) -> Dictionary:
	if values.is_empty():
		return {"n": 0, "median_ms": null, "p95_ms": null}
	var ordered := values.duplicate()
	ordered.sort()
	return {"n": values.size(), "median_ms": ordered[int((ordered.size() - 1) / 2.0)], "p95_ms": ordered[ceili(ordered.size() * 0.95) - 1]}


func _benchmark() -> void:
	var old_vsync := DisplayServer.window_get_vsync_mode()
	var old_limit := Engine.max_fps
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 240
	var viewport_rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport_rid, true)
	# 等待窗口启动与 stretch 尺寸稳定，再记录纹理 API 报告尺寸。
	await get_tree().create_timer(1.0).timeout
	var render_size := get_viewport().get_texture().get_size()
	var report: Dictionary = {"engine": Engine.get_version_info().string, "gpu": RenderingServer.get_video_adapter_name(), "driver": RenderingServer.get_current_rendering_driver_name(), "logical_size": [get_viewport_rect().size.x, get_viewport_rect().size.y], "render_target_size": [render_size.x, render_size.y], "max_fps": 240, "vsync": DisplayServer.window_get_vsync_mode(), "rows": []}
	for repeat in 3:
		var order := [true, false] if repeat != 1 else [false, true]
		for oversized in order:
			var gpu: Array = []
			var wall: Array = []
			# 每轮先播一个完整周期预热，再采三个完整周期。
			for cycle in 4:
				_three(oversized)
				await get_tree().process_frame
				var previous := Time.get_ticks_usec()
				while spells[0].playing:
					await get_tree().process_frame
					var now := Time.get_ticks_usec()
					if cycle > 0:
						wall.append((now - previous) / 1000.0)
						var value := RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
						if value > 0.0 and is_finite(value):
							gpu.append(value)
					previous = now
			assert(get_viewport().get_texture().get_size() == render_size, "测量期间不能改变渲染尺寸")
			report.rows.append({"repeat": repeat + 1, "oversized": oversized, "gpu": _stats(gpu), "wall": _stats(wall), "raw_gpu_ms": gpu, "raw_wall_ms": wall})
	var file := FileAccess.open("res://tutorial/lessons/14_capstone/benchmark-example.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	# 优化前后采用相同时间和颜色截图；截图位于测量区间外。
	for oversized in [true, false]:
		_three(oversized)
		await get_tree().create_timer(0.1).timeout
		await _pose(1.6)
		await _snapshot("before" if oversized else "after")
	DisplayServer.window_set_vsync_mode(old_vsync)
	Engine.max_fps = old_limit
	print("LESSON_14_BENCHMARK_OK")
	get_tree().quit()

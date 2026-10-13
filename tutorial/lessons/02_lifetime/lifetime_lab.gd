extends Control
## 本课只修改内置过程材质；绘制复用第一课的柔边圆点。

const TITLES := ["火星 / 缩小与褪色", "烟尘 / 扩张与淡出", "命中爆点 / 集中发射"]
const DURATIONS := [1.8, 3.0, 0.85]
const SPEED_MIN := [95.0, 20.0, 110.0]
const SPEED_MAX := [150.0, 40.0, 180.0]
const MATERIALS := [preload("sparks.tres"), preload("smoke.tres"), preload("impact.tres")]
const DOT_SHADER := preload("../01_playground/soft_dot.gdshader")

var particles: Array[GPUParticles2D] = []
var selected := 0
var clock := 0.0
var moving := false
var syncing := false
var size_curves := [true, true, true]
var fades := [true, true, true]
var spread_speeds := [true, true, true]
var selector: OptionButton
var duration: HSlider
var explosion: HSlider
var prewarm: HSlider
var curve_toggle: CheckBox
var fade_toggle: CheckBox
var random_toggle: CheckBox
var local_toggle: CheckBox
var move_toggle: CheckBox
var status: Label
var labels: Array[Label] = []


func _ready() -> void:
	var draw := ShaderMaterial.new()
	draw.shader = DOT_SHADER
	for i in range(3):
		var panel := $Stage.get_child(i) as Control
		var emitter := panel.get_node("Particles") as GPUParticles2D
		# 深复制保证三个预设和源资源不会互相改动。
		emitter.process_material = MATERIALS[i].duplicate(true)
		emitter.material = draw
		particles.append(emitter)
		var label := Label.new()
		label.text = TITLES[i]
		label.position = Vector2(8, 8)
		panel.add_child(label)
		labels.append(label)
		var origin := Label.new()
		origin.name = "Origin"
		origin.text = "+ 发射点"
		panel.add_child(origin)
	_build_ui()
	particles[2].finished.connect(func() -> void:
		status.text = "爆点已全部结束：点击同步重播再次触发。停止发射不等于粒子已全部死亡。"
	)
	_sync_ui()
	_replay()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		call_deferred("_smoke_test")
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		call_deferred("_capture")


func _process(delta: float) -> void:
	clock += delta
	_position_emitters()


func _position_emitters() -> void:
	for emitter in particles:
		var panel := emitter.get_parent() as Control
		var offset_x := sin(clock * 1.8) * 65.0 if moving else 0.0
		emitter.position = Vector2(panel.size.x * 0.5 + offset_x, panel.size.y * 0.76)
		panel.get_node("Origin").position = emitter.position + Vector2(10, 10)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 12)
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var heading := Label.new()
	heading.text = "02 / 生命周期、随机性与时间节奏"
	heading.add_theme_font_size_override("font_size", 24)
	box.add_child(heading)
	var row := HBoxContainer.new()
	box.add_child(row)
	selector = OptionButton.new()
	for title in TITLES:
		selector.add_item(title)
	selector.item_selected.connect(func(index: int) -> void:
		selected = index
		_sync_ui()
	)
	row.add_child(selector)
	_button(row, "同步重播", _replay)
	_button(row, "换种子并重播", _new_seed)
	_button(row, "全部恢复基线", _reset)
	duration = _slider(box, "寿命（选中效果）", 0.5, 4.0, 0.05, _set_duration)
	explosion = _slider(box, "爆发程度（选中效果）", 0, 1, 0.1, _set_explosion)
	prewarm = _slider(box, "预热秒数（选中效果）", 0, 2, 0.5, _set_prewarm)
	var toggles := HBoxContainer.new()
	box.add_child(toggles)
	curve_toggle = _check(toggles, "大小曲线（选中）", _set_curve)
	fade_toggle = _check(toggles, "生命周期透明度（选中）", _set_fade)
	random_toggle = _check(toggles, "出生速度范围（选中）", _set_random)
	var global_row := HBoxContainer.new()
	box.add_child(global_row)
	move_toggle = _check(global_row, "移动全部发射器", _set_moving)
	local_toggle = _check(global_row, "本地坐标（全部）", _set_local)
	var footer := VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_top = -86
	footer.offset_bottom = -12
	add_child(footer)
	status = Label.new()
	footer.add_child(status)
	var note := Label.new()
	note.text = "上方三个滑条和前三个开关只改选中效果；所有参数改动都会重播，便于对照。\n爆点只播放一轮；切换选中项不会重播。曲线可在对应 .tres 资源中查看。"
	footer.add_child(note)


func _button(parent: Control, title: String, action: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)


func _check(parent: Control, title: String, action: Callable) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.text = title
	checkbox.toggled.connect(func(value: bool) -> void:
		if not syncing:
			action.call(value)
	)
	parent.add_child(checkbox)
	return checkbox


func _slider(parent: Control, title: String, low: float, high: float,
		step_size: float, action: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 220
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 320
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	row.add_child(slider)
	var value_label := Label.new()
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		if not syncing:
			action.call(value)
	)
	return slider


func _sync_ui() -> void:
	syncing = true
	duration.value = particles[selected].lifetime
	explosion.value = particles[selected].explosiveness
	prewarm.value = particles[selected].preprocess
	# 数值未变时也更新标签。
	for slider in [duration, explosion, prewarm]:
		slider.get_parent().get_child(2).text = "%.2f" % slider.value
	curve_toggle.button_pressed = size_curves[selected]
	fade_toggle.button_pressed = fades[selected]
	random_toggle.button_pressed = spread_speeds[selected]
	for i in range(3):
		labels[i].text = ("▶ " if i == selected else "") + TITLES[i]
	syncing = false


func _replay() -> void:
	clock = 0.0
	_position_emitters()
	for emitter in particles:
		emitter.restart(true)
	status.text = "已保留种子 %d 重播。先预测，再每次只改一个变量。" % particles[0].seed


func _new_seed() -> void:
	for emitter in particles:
		emitter.seed += 1
	_replay()


func _set_duration(value: float) -> void:
	particles[selected].lifetime = value
	_replay()


func _set_explosion(value: float) -> void:
	particles[selected].explosiveness = value
	_replay()


func _set_prewarm(value: float) -> void:
	particles[selected].preprocess = value
	_replay()


func _set_curve(enabled: bool) -> void:
	size_curves[selected] = enabled
	particles[selected].process_material.scale_curve = MATERIALS[selected].scale_curve if enabled else null
	_replay()


func _set_fade(enabled: bool) -> void:
	fades[selected] = enabled
	var source: GradientTexture1D = MATERIALS[selected].color_ramp
	var ramp := source.duplicate(true) as GradientTexture1D
	if not enabled:
		for i in range(ramp.gradient.get_point_count()):
			var tint := ramp.gradient.get_color(i)
			tint.a = 1.0
			ramp.gradient.set_color(i, tint)
	particles[selected].process_material.color_ramp = ramp
	_replay()


func _set_random(enabled: bool) -> void:
	spread_speeds[selected] = enabled
	var motion := particles[selected].process_material as ParticleProcessMaterial
	var midpoint: float = (SPEED_MIN[selected] + SPEED_MAX[selected]) * 0.5
	motion.initial_velocity_min = SPEED_MIN[selected] if enabled else midpoint
	motion.initial_velocity_max = SPEED_MAX[selected] if enabled else midpoint
	_replay()


func _set_moving(enabled: bool) -> void:
	moving = enabled
	_replay()


func _set_local(enabled: bool) -> void:
	for emitter in particles:
		emitter.local_coords = enabled
	_replay()


func _reset() -> void:
	for i in range(3):
		particles[i].process_material = MATERIALS[i].duplicate(true)
		particles[i].lifetime = DURATIONS[i]
		particles[i].explosiveness = 1.0 if i == 2 else 0.0
		particles[i].preprocess = 0.0
		particles[i].local_coords = false
		particles[i].seed = 137
		size_curves[i] = true
		fades[i] = true
		spread_speeds[i] = true
	moving = false
	syncing = true
	move_toggle.button_pressed = false
	local_toggle.button_pressed = false
	syncing = false
	_sync_ui()
	_replay()


func _smoke_test() -> void:
	assert(particles[0].process_material != particles[1].process_material)
	selected = 1
	_sync_ui()
	duration.value = 4.0
	assert(particles[1].lifetime == 4.0 and particles[0].lifetime == 1.8)
	explosion.value = 0.5
	assert(particles[1].explosiveness == 0.5 and particles[2].explosiveness == 1.0)
	curve_toggle.button_pressed = false
	assert(particles[1].process_material.scale_curve == null)
	assert(MATERIALS[1].scale_curve != null)
	fade_toggle.button_pressed = false
	assert(particles[1].process_material.color_ramp.gradient.get_color(0).a == 1.0)
	assert(MATERIALS[1].color_ramp.gradient.get_color(0).a == 0.0)
	random_toggle.button_pressed = false
	assert(particles[1].process_material.initial_velocity_min == 30.0)
	assert(particles[1].process_material.initial_velocity_max == 30.0)
	prewarm.value = 1.0
	assert(particles[1].preprocess == 1.0)
	local_toggle.button_pressed = true
	move_toggle.button_pressed = true
	assert(particles[0].local_coords and particles[2].local_coords and moving)
	_new_seed()
	assert(particles[0].seed == 138)
	_reset()
	assert(particles[1].lifetime == 3.0 and particles[1].preprocess == 0.0)
	assert(particles[1].explosiveness == 0.0 and particles[1].seed == 137)
	assert(not moving and not particles[1].local_coords)
	assert(particles[2].one_shot and particles[2].explosiveness == 1.0)
	assert(particles[1].process_material.color_ramp.gradient.get_color(0).a == 0.0)
	print("LESSON_02_SMOKE_TEST_OK")
	get_tree().quit()


func _capture() -> void:
	await get_tree().create_timer(3.0).timeout
	particles[2].restart(true)
	status.text = "预览：连续效果已运行 3 秒，爆点单独重触发以展示三种外观。"
	await get_tree().create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(
		"res://tutorial/lessons/02_lifetime/preview.png")
	print("LESSON_02_CAPTURE: ", error)
	get_tree().quit()

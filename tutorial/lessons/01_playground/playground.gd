extends Control
## UI orchestration only. Motion stays in ParticleProcessMaterial.

@onready var left: GPUParticles2D = $Stage/Left/Particles
@onready var right: GPUParticles2D = $Stage/Right/Particles
@onready var motion: ParticleProcessMaterial = left.process_material
@onready var appearance: ShaderMaterial = right.material

var speed_slider: HSlider
var opacity_slider: HSlider
var amount_slider: HSlider
var mistake: CheckBox
var light_background := false
var status: Label


func _ready() -> void:
	_build_controls()
	_build_stage_labels($Stage/Left, "A  普通纹理 · 方形", "没有自定义绘制材质")
	_build_stage_labels($Stage/Right, "B  Shader · 柔边圆点", "相同模拟参数，不同绘制方式")
	$Stage/Left.resized.connect(_position_emitters)
	$Stage/Right.resized.connect(_position_emitters)
	_position_emitters()
	_replay()
	# Optional runtime smoke check, executed after the scene has initialized.
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		call_deferred("_smoke_test")
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		call_deferred("_capture_preview")


func _build_controls() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 16)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "01 / 粒子实验场：运动与外观"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	_add_button(buttons, "同步重播", _replay)
	_add_button(buttons, "切换明暗背景", _toggle_background)
	_add_button(buttons, "恢复基线", _reset)
	mistake = CheckBox.new()
	mistake.text = "错误示范：覆盖粒子颜色"
	mistake.toggled.connect(_set_mistake)
	buttons.add_child(mistake)
	speed_slider = _add_slider(box, "初速度（两侧）", 60, 220, 10, 150, _set_speed)
	opacity_slider = _add_slider(box, "不透明度（仅 B）", 0, 1, 0.05, 1, _set_opacity)
	amount_slider = _add_slider(box, "粒子数量（每侧）", 8, 128, 8, 48, _set_amount)
	var footer := VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_top = -82
	footer.offset_right = -24
	footer.offset_bottom = -12
	add_child(footer)
	status = Label.new()
	status.text = "先观察基线，再每次只改变一个参数。"
	footer.add_child(status)
	var note := Label.new()
	note.text = "实验 A：改初速度，看轨迹。  实验 B：改不透明度，看形状与路径。\n实验 C：开启错误示范，观察蓝色和末段淡出是否保留。"
	footer.add_child(note)


func _add_button(parent: Control, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	parent.add_child(button)


func _add_slider(parent: Control, caption: String, low: float, high: float,
		step_size: float, initial: float, action: Callable) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 300
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	slider.value = initial
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = str(initial)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = str(snappedf(value, 0.01))
		action.call(value)
	)
	return slider


func _build_stage_labels(panel: Control, caption: String, description: String) -> void:
	var title := Label.new()
	title.text = caption + "\n" + description
	title.position = Vector2(12, 4)
	panel.add_child(title)
	var marker := Label.new()
	marker.name = "Origin"
	marker.text = "+  发射点"
	panel.add_child(marker)


func _position_emitters() -> void:
	for emitter: GPUParticles2D in [left, right]:
		var panel := emitter.get_parent() as Control
		emitter.position = Vector2(panel.size.x * 0.5, panel.size.y * 0.7)
		var marker := panel.get_node_or_null("Origin") as Label
		if marker:
			marker.position = emitter.position + Vector2(12, 12)


func _replay() -> void:
	left.restart(true)
	right.restart(true)


func _set_speed(value: float) -> void:
	# Both emitters intentionally share this resource for a controlled comparison.
	motion.initial_velocity_min = value
	motion.initial_velocity_max = value
	_replay()
	status.text = "已修改过程材质并同步重播；两侧初速度相同。"


func _set_opacity(value: float) -> void:
	appearance.set_shader_parameter("opacity", value)
	status.text = "仅修改 B 的绘制参数；模拟继续运行，没有重播。"


func _set_amount(value: float) -> void:
	left.amount = int(value)
	right.amount = int(value)
	_replay()
	status.text = "已修改节点数量并同步重播；数量是每侧的粒子容量。"


func _set_mistake(enabled: bool) -> void:
	appearance.set_shader_parameter("ignore_particle_color", enabled)
	status.text = "B 忽略了传入颜色和透明度：注意白色与突然消失。" if enabled else "B 恢复保留传入颜色与生命周期淡出。"


func _toggle_background() -> void:
	light_background = not light_background
	$Background.color = Color("d9e2ed") if light_background else Color("090d14")
	add_theme_color_override("font_color", Color("182536") if light_background else Color("e2ecfa"))


func _reset() -> void:
	speed_slider.value = 150
	opacity_slider.value = 1
	amount_slider.value = 48
	mistake.button_pressed = false
	if light_background:
		_toggle_background()
	_replay()
	status.text = "已恢复基线：150 px/s、48 个粒子、不透明度 1。"


func _smoke_test() -> void:
	assert(left.process_material == right.process_material)
	assert(left.use_fixed_seed and right.use_fixed_seed and left.seed == right.seed)
	speed_slider.value = 220
	assert(motion.initial_velocity_min == 220 and motion.initial_velocity_max == 220)
	opacity_slider.value = 0.25
	assert(is_equal_approx(float(appearance.get_shader_parameter("opacity")), 0.25))
	assert(motion.initial_velocity_min == 220)
	amount_slider.value = 96
	assert(left.amount == 96 and right.amount == 96)
	mistake.button_pressed = true
	assert(appearance.get_shader_parameter("ignore_particle_color") == true)
	_toggle_background()
	_reset()
	assert(left.amount == 48 and motion.initial_velocity_min == 150)
	assert(not light_background and not mistake.button_pressed)
	assert(is_equal_approx(float(appearance.get_shader_parameter("opacity")), 1.0))
	print("LESSON_01_SMOKE_TEST_OK")
	get_tree().quit()


func _capture_preview() -> void:
	await get_tree().create_timer(3.0).timeout
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(
		"res://tutorial/lessons/01_playground/preview.png")
	print("LESSON_01_CAPTURE: ", error)
	get_tree().quit()

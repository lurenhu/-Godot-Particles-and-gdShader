extends Control

const NOISE := preload("../04_noise/noise.tres")
const MIX_SHADER := preload("age_mix.gdshader")
const ADD_SHADER := preload("age_add.gdshader")
@onready var emitters: Array[GPUParticles2D] = [$Left, $Right]
var clock := 0.0
var playing := false
var light := false
var pause: CheckBox
var random_toggle: CheckBox
var preserve: CheckBox
var dissolve: CheckBox
var view: OptionButton
var blend: OptionButton
var start_slider: HSlider
var pulse_slider: HSlider
var status: Label


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	_reset()
	if NOISE.get_image() == null:
		await NOISE.changed
	playing = true
	_replay()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _process(delta: float) -> void:
	if playing and not pause.button_pressed:
		clock += delta
		_set_parameter("lesson_time", clock)
	if status:
		status.text = "共享时间 %.2f s / 左侧周期进度 %.2f；右侧进度来自每颗粒子。" % [clock, fmod(clock / 4.0, 1.0)]


func _set_parameter(key: String, value: Variant) -> void:
	for emitter in emitters:
		emitter.material.set_shader_parameter(key, value)


func _layout() -> void:
	for i in range(2):
		emitters[i].position = Vector2(size.x * (0.25 + i * 0.5), size.y - 140)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 12)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "05 / 每颗粒子自己的时间：扩张、变色与溶解"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "同步重播", _replay)
	_button(row, "只重播右侧", func() -> void: emitters[1].restart(true))
	_button(row, "明暗背景", _background)
	_button(row, "恢复基线", _reset)
	pause = _check(row, "冻结时间与模拟", func(value: bool) -> void:
		for emitter in emitters:
			emitter.speed_scale = 0.0 if value else 1.0
	)
	var options := HBoxContainer.new()
	box.add_child(options)
	view = OptionButton.new()
	for entry in ["成品", "使用的年龄（灰度）", "出生相位（灰度）"]:
		view.add_item(entry)
	view.item_selected.connect(func(index: int) -> void: _set_parameter("debug_view", index))
	options.add_child(view)
	blend = OptionButton.new()
	for entry in ["普通透明混合", "加法混合"]:
		blend.add_item(entry)
	blend.item_selected.connect(_set_blend)
	options.add_child(blend)
	random_toggle = _check(options, "随机闪烁相位", func(value: bool) -> void: _set_parameter("random_phase", value))
	preserve = _check(options, "保留输入颜色与淡出", func(value: bool) -> void: _set_parameter("preserve_color", value))
	dissolve = _check(options, "启用溶解", func(value: bool) -> void: _set_parameter("dissolve_enabled", value))
	start_slider = _slider(box, "溶解起点（生命进度）", "dissolve_start", 0.2, 0.85, 0.05, 0.55)
	pulse_slider = _slider(box, "闪烁频率（Hz；0 为关闭）", "pulse_hz", 0, 4, 0.25, 1)
	var captions := HBoxContainer.new()
	captions.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	captions.offset_top = 250
	captions.offset_left = 40
	captions.offset_right = -40
	add_child(captions)
	for entry in ["A / 共享周期进度\n所有粒子使用同一个时钟", "B / 自身生命周期\n每颗粒子从出生开始播放"]:
		var label := Label.new()
		label.text = entry
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		captions.add_child(label)
	var footer := VBoxContainer.new()
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_top = -92
	footer.offset_bottom = -12
	add_child(footer)
	status = Label.new()
	footer.add_child(status)
	var note := Label.new()
	note.text = "先看年龄调试：左侧同时变亮，右侧下方年轻、上方年老。冻结后仍可调整绘制参数。\n先关随机相位看同步闪烁，再打开看错开；随机相位不改变粒子的溶解时间表。\n灰度调试请用普通混合与深色背景，避免加法叠加改变读数。"
	footer.add_child(note)


func _button(parent: Control, text_value: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text_value
	button.pressed.connect(action)
	parent.add_child(button)


func _check(parent: Control, text_value: String, action: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = text_value
	check.toggled.connect(action)
	parent.add_child(check)
	return check


func _slider(parent: Control, text_value: String, key: String, low: float,
		high: float, step_size: float, initial: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size.x = 290
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	slider.value = initial
	slider.custom_minimum_size.x = 320
	row.add_child(slider)
	var number := Label.new()
	number.text = "%.2f" % initial
	row.add_child(number)
	slider.value_changed.connect(func(value: float) -> void:
		number.text = "%.2f" % value
		_set_parameter(key, value)
	)
	return slider


func _set_blend(index: int) -> void:
	for emitter in emitters:
		emitter.material.shader = MIX_SHADER if index == 0 else ADD_SHADER
	# 更换 Shader 后显式重填参数，不依赖编辑器保留行为。
	_apply_parameters()


func _apply_parameters() -> void:
	_set_parameter("noise_texture", NOISE)
	_set_parameter("lesson_time", clock)
	_set_parameter("lifetime", 4.0)
	_set_parameter("random_phase", random_toggle.button_pressed)
	_set_parameter("preserve_color", preserve.button_pressed)
	_set_parameter("dissolve_enabled", dissolve.button_pressed)
	_set_parameter("debug_view", view.selected)
	_set_parameter("dissolve_start", start_slider.value)
	_set_parameter("pulse_hz", pulse_slider.value)
	emitters[0].material.set_shader_parameter("use_particle_age", false)
	emitters[1].material.set_shader_parameter("use_particle_age", true)


func _replay() -> void:
	clock = 0.0
	_set_parameter("lesson_time", clock)
	for emitter in emitters:
		emitter.restart(true)


func _background() -> void:
	light = not light
	$Background.color = Color("d5dde8") if light else Color("090d14")
	var foreground := Color("132139") if light else Color("eeeeee")
	for label in find_children("*", "Label", true, false):
		label.add_theme_color_override("font_color", foreground)
	for check in find_children("*", "CheckBox", true, false):
		for color_name in ["font_color", "font_pressed_color", "font_hover_color", "font_hover_pressed_color"]:
			check.add_theme_color_override(color_name, foreground)


func _reset() -> void:
	pause.button_pressed = false
	for emitter in emitters:
		emitter.speed_scale = 1.0
	random_toggle.button_pressed = true
	preserve.button_pressed = true
	dissolve.button_pressed = true
	view.select(0)
	blend.select(0)
	start_slider.value = 0.55
	pulse_slider.value = 1.0
	if light:
		_background()
	_set_blend(0)
	_replay()


func _smoke_test() -> void:
	assert(emitters[0].process_material == emitters[1].process_material)
	assert(emitters[0].material != emitters[1].material)
	assert(emitters[0].process_material.lifetime_randomness == 0)
	assert(emitters[0].process_material.anim_speed_max == 0)
	assert(emitters[0].process_material.anim_offset_max == 1)
	pause.button_pressed = true
	var before := clock
	_process(1)
	assert(clock == before and emitters[1].speed_scale == 0)
	start_slider.value = 0.8
	assert(is_equal_approx(emitters[1].material.get_shader_parameter("dissolve_start"), 0.8))
	blend.select(1)
	_set_blend(1)
	assert(emitters[1].material.shader == ADD_SHADER)
	assert(emitters[1].material.get_shader_parameter("use_particle_age") == true)
	_background()
	_reset()
	assert(not light and emitters[0].speed_scale == 1)
	assert(emitters[0].material.get_shader_parameter("use_particle_age") == false)
	print("LESSON_05_SMOKE_TEST_OK")
	get_tree().quit()


func _frame(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(
		"res://tutorial/lessons/05_particle_age/" + filename)
	assert(error == OK)


func _capture() -> void:
	await get_tree().create_timer(5.4).timeout
	pause.button_pressed = true
	await _frame("preview.png")
	view.select(1)
	_set_parameter("debug_view", 1)
	await _frame("age_debug.png")
	view.select(2)
	_set_parameter("debug_view", 2)
	await _frame("phase_debug.png")
	view.select(0)
	_set_parameter("debug_view", 0)
	blend.select(1)
	_set_blend(1)
	await _frame("add_dark.png")
	_background()
	await _frame("add_light.png")
	blend.select(0)
	_set_blend(0)
	await _frame("mix_light.png")
	print("LESSON_05_CAPTURE_OK")
	get_tree().quit()

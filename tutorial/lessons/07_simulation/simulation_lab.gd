extends Control

const DRAW_SHADER := preload("../01_playground/soft_dot.gdshader")
@onready var emitters: Array[GPUParticles2D] = [$Automatic, $Manual, $DoubleMove]
var pause: CheckBox
var reset_velocity: CheckBox
var fade: CheckBox
var age_view: CheckBox
var speed: HSlider
var gravity: HSlider
var end_age: HSlider
var fps: OptionButton
var status: Label
var clock := 0.0


func _ready() -> void:
	var drawing := ShaderMaterial.new()
	drawing.shader = DRAW_SHADER
	for emitter in emitters:
		emitter.material = drawing # 仅绘制材质共享，不在运行时修改。
	_build_ui()
	resized.connect(_layout)
	_layout()
	_reset()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _process(delta: float) -> void:
	if not pause.button_pressed:
		clock += delta
	status.text = "重播后脚本时间 %.2f s（非 GPU 年龄读数） / 改参数后请重播；十字为发射原点。" % clock


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1323"))
	for i in range(3):
		var origin := Vector2(size.x * (float(i) + 0.5) / 3.0, size.y * 0.65)
		draw_line(origin - Vector2(12, 0), origin + Vector2(12, 0), Color("94a3b8"), 1)
		draw_line(origin - Vector2(0, 12), origin + Vector2(0, 12), Color("94a3b8"), 1)
		for distance in [100, 200]:
			draw_arc(origin, distance, PI, TAU, 48, Color("26364e"), 1)
		if i > 0:
			draw_line(Vector2(size.x * i / 3.0, 310), Vector2(size.x * i / 3.0, size.y - 50), Color("26364e"), 1)


func _layout() -> void:
	for i in range(3):
		emitters[i].position = Vector2(size.x * (float(i) + 0.5) / 3.0, size.y * 0.65)
	queue_redraw()


func _parameter(key: String, value: Variant) -> void:
	for emitter in emitters:
		emitter.process_material.set_shader_parameter(key, value)


func _replay() -> void:
	clock = 0
	pause.button_pressed = false
	for emitter in emitters:
		emitter.speed_scale = 1
		emitter.restart(true)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 12)
	add_child(box)
	var title := Label.new()
	title.text = "07 / 自定义粒子模拟：谁负责移动位置？"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "同步重播", _replay)
	_button(row, "恢复基线并重播", _reset)
	pause = _check(row, "冻结模拟", func(value: bool) -> void:
		for emitter in emitters:
			emitter.speed_scale = 0 if value else 1)
	fps = OptionButton.new()
	for label in ["固定模拟 60 Hz", "固定模拟 30 Hz", "固定模拟 15 Hz"]:
		fps.add_item(label)
	fps.item_selected.connect(func(index: int) -> void:
		for emitter in emitters:
			emitter.fixed_fps = [60, 30, 15][index]
		_replay())
	row.add_child(fps)
	var options := HBoxContainer.new()
	box.add_child(options)
	reset_velocity = _check(options, "错误：每步重置速度", func(value: bool) -> void: _parameter("reset_velocity_each_step", value))
	fade = _check(options, "生命周期淡出", func(value: bool) -> void: _parameter("fade_enabled", value))
	age_view = _check(options, "年龄灰度", func(value: bool) -> void: _parameter("age_debug", value))
	speed = _slider(box, "初速度 / 局部单位每秒", "launch_speed", 60, 240, 10)
	gravity = _slider(box, "重力 Y / 局部单位每秒²", "gravity_y", 0, 320, 20)
	end_age = _slider(box, "ACTIVE 结束年龄 / 寿命比例", "end_age", 0.25, 1, 0.05)
	status = Label.new()
	box.add_child(status)
	var captions := HBoxContainer.new()
	captions.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	captions.offset_top = 275
	add_child(captions)
	for text_value in ["A / 自动位移\nprocess 只更新速度", "B / 手动位移\ndisable_velocity + 手动推进", "C / 故意重复位移\n自动与手动同时开启"]:
		var label := Label.new()
		label.text = text_value
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		captions.add_child(label)


func _button(parent: Control, caption: String, action: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.pressed.connect(action)
	parent.add_child(button)


func _check(parent: Control, caption: String, action: Callable) -> CheckBox:
	var check := CheckBox.new()
	check.text = caption
	check.toggled.connect(action)
	parent.add_child(check)
	return check


func _slider(parent: Control, caption: String, key: String, low: float, high: float, step_value: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 330
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step_value
	slider.custom_minimum_size.x = 320
	row.add_child(slider)
	var number := Label.new()
	row.add_child(number)
	slider.value_changed.connect(func(value: float) -> void:
		_parameter(key, value)
		number.text = "%.2f" % value)
	return slider


func _reset() -> void:
	reset_velocity.button_pressed = false
	fade.button_pressed = true
	age_view.button_pressed = false
	_parameter("reset_velocity_each_step", false)
	_parameter("fade_enabled", true)
	_parameter("age_debug", false)
	speed.value = 170
	gravity.value = 220
	end_age.value = 1
	fps.select(0)
	for emitter in emitters:
		emitter.fixed_fps = 60
	_replay()


func _smoke_test() -> void:
	assert(emitters[0].process_material != emitters[1].process_material)
	assert(emitters[0].material == emitters[1].material)
	for emitter in emitters:
		assert(emitter.local_coords and emitter.one_shot and emitter.amount == 9)
	pause.button_pressed = true
	var before := clock
	_process(1)
	assert(clock == before and emitters[0].speed_scale == 0)
	gravity.value = 0
	assert(emitters[1].process_material.get_shader_parameter("gravity_y") == 0)
	end_age.value = 0.5
	assert(emitters[2].process_material.get_shader_parameter("end_age") == 0.5)
	_reset()
	assert(gravity.value == 220 and emitters[1].speed_scale == 1)
	print("LESSON_07_SMOKE_TEST_OK")
	get_tree().quit()


func _seek(seconds: float) -> void:
	pause.button_pressed = true
	clock = seconds
	for emitter in emitters:
		emitter.restart(true)
		emitter.speed_scale = 0
		emitter.request_particles_process(seconds)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _snapshot(filename: String) -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png("res://tutorial/lessons/07_simulation/" + filename)
	assert(error == OK)
	return image


func _capture() -> void:
	await get_tree().create_timer(0.4).timeout
	await _seek(0.7)
	await _snapshot("preview.png")
	var a := emitters[0].capture_rect()
	var b := emitters[1].capture_rect()
	print("AUTO_RECT=", a, " MANUAL_RECT=", b)
	assert(a.position.distance_to(b.position) < 0.1 and a.size.distance_to(b.size) < 0.1, "自动与手动包围盒应一致")
	reset_velocity.button_pressed = true
	await _seek(0.7)
	await _snapshot("reset_velocity.png")
	_reset()
	gravity.value = 0
	await _seek(0.7)
	await _snapshot("zero_gravity.png")
	_reset()
	fade.button_pressed = false
	end_age.value = 0.5
	await _seek(0.7)
	await _snapshot("before_death.png")
	await _seek(1.2)
	var ended := await _snapshot("early_death.png")
	for emitter in emitters:
		emitter.hide()
	var empty := await _snapshot("empty.png")
	assert(ended.get_data() == empty.get_data(), "关闭淡出后 ACTIVE=false 仍应消失")
	for emitter in emitters:
		emitter.show()
	_reset()
	age_view.button_pressed = true
	await _seek(0.7)
	await _snapshot("age_debug.png")
	print("LESSON_07_CAPTURE_OK")
	get_tree().quit()

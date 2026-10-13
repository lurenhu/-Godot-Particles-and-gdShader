extends Control

@onready var particles: GPUParticles2D = $Particles
@onready var target: Node2D = $Target
var pause: CheckBox
var moving: CheckBox
var wrong: CheckBox
var center_test: CheckBox
var radial: HSlider
var swirl: HSlider
var drag: HSlider
var radius: HSlider
var view: OptionButton
var fps: OptionButton
var status: Label
var clock := 0.0
var target_uv := Vector2(0.5, 0.67)


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_reset()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _process(delta: float) -> void:
	if not pause.button_pressed:
		clock += delta
	_layout()
	status.text = "左键移动目标（黄十字）；白圈为出生区域，灰圈为力场范围。时间 %.2f s" % clock


func _layout() -> void:
	target.position = size * target_uv
	particles.position = size * Vector2(0.5, 0.67)
	particles.rotation = 0
	if moving and moving.button_pressed:
		particles.position += Vector2(sin(clock) * 110, cos(clock * 0.7) * 30)
		particles.rotation = sin(clock * 0.8) * 0.5
	_update_target()
	queue_redraw()


func _update_target() -> void:
	# 两个节点在同一画布；local_coords=true，所以要转换到发射器局部。
	var local_target := particles.to_local(target.global_position)
	_parameter("target_local", target.global_position if wrong and wrong.button_pressed else local_target)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y > 320:
			target_uv = event.position / size
			_layout()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1323"))
	if not is_instance_valid(target) or not radius:
		return
	draw_arc(target.position, radius.value, 0, TAU, 96, Color("26364e"), 1)
	draw_arc(target.position, 24, 0, TAU, 32, Color("66532c"), 1)
	draw_line(target.position - Vector2(12, 0), target.position + Vector2(12, 0), Color("ffd166"), 2)
	draw_line(target.position - Vector2(0, 12), target.position + Vector2(0, 12), Color("ffd166"), 2)
	var spawn: float = particles.process_material.get_shader_parameter("spawn_radius")
	draw_arc(particles.position, spawn, 0, TAU, 64, Color("52647c"), 1)
	var axis := Vector2.RIGHT.rotated(particles.rotation) * 36
	draw_line(particles.position, particles.position + axis, Color("eeeeee"), 2)


func _parameter(key: String, value: Variant) -> void:
	particles.process_material.set_shader_parameter(key, value)


func _replay() -> void:
	clock = 0
	pause.button_pressed = false
	particles.speed_scale = 1
	_layout()
	particles.restart(true)


func _preset(outward: bool) -> void:
	radial.value = -500 if outward else 500
	swirl.value = 180 if outward else 260
	drag.value = 1.2 if outward else 1.8
	radius.value = 320
	_parameter("spawn_radius", 35.0 if outward else 160.0)
	_replay()


func _reset() -> void:
	moving.button_pressed = false
	wrong.button_pressed = false
	center_test.button_pressed = false
	_parameter("spawn_at_target", false)
	view.select(0)
	_parameter("debug_view", 0)
	fps.select(0)
	particles.fixed_fps = 60
	target_uv = Vector2(0.5, 0.67)
	_preset(false)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 8)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1323")
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "09 / 力场与旋涡：根据当前位置更新速度"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "吸入预设", func() -> void: _preset(false))
	_button(row, "喷散预设", func() -> void: _preset(true))
	_button(row, "重播", _replay)
	_button(row, "恢复基线", _reset)
	pause = _check(row, "冻结", func(value: bool) -> void: particles.speed_scale = 0 if value else 1)
	var options := HBoxContainer.new()
	box.add_child(options)
	moving = _check(options, "移动并旋转发射器", func(_value: bool) -> void: _layout())
	wrong = _check(options, "错误：直接传世界坐标", func(_value: bool) -> void: _update_target())
	center_test = _check(options, "中心出生诊断", func(value: bool) -> void:
		_parameter("spawn_at_target", value)
		_replay())
	var selectors := HBoxContainer.new()
	box.add_child(selectors)
	view = OptionButton.new()
	for label in ["成品颜色", "速度：蓝慢 / 红快", "距离：黑近 / 白远"]:
		view.add_item(label)
	view.item_selected.connect(func(index: int) -> void: _parameter("debug_view", index))
	selectors.add_child(view)
	fps = OptionButton.new()
	for label in ["模拟 60 Hz", "模拟 30 Hz", "模拟 15 Hz"]:
		fps.add_item(label)
	fps.item_selected.connect(func(index: int) -> void:
		particles.fixed_fps = [60, 30, 15][index]
		_replay())
	selectors.add_child(fps)
	radial = _slider(box, "径向加速度：正吸入 / 负喷散", "radial_accel", -800, 800, 20)
	swirl = _slider(box, "切向加速度：正负改变旋向", "swirl_accel", -600, 600, 20)
	drag = _slider(box, "阻尼系数 / 每秒", "damping", 0, 4, 0.1)
	radius = _slider(box, "力场半径 / 局部单位", "field_radius", 100, 400, 10)
	status = Label.new()
	box.add_child(status)


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
	label.custom_minimum_size.x = 340
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step_value
	slider.custom_minimum_size.x = 300
	row.add_child(slider)
	var number := Label.new()
	row.add_child(number)
	slider.value_changed.connect(func(value: float) -> void:
		_parameter(key, value)
		number.text = "%.1f" % value)
	return slider


func _smoke_test() -> void:
	assert(particles.local_coords and particles.fixed_fps == 60)
	moving.button_pressed = true
	clock = 1.1
	_layout()
	var received: Vector2 = particles.process_material.get_shader_parameter("target_local")
	assert(particles.to_global(received).distance_to(target.global_position) < 0.001)
	wrong.button_pressed = true
	assert(particles.process_material.get_shader_parameter("target_local") == target.global_position)
	pause.button_pressed = true
	var before := clock
	_process(1)
	assert(clock == before and particles.speed_scale == 0)
	_reset()
	assert(radial.value == 500 and not wrong.button_pressed)
	print("LESSON_09_SMOKE_TEST_OK")
	get_tree().quit()


func _seek(seconds: float) -> void:
	pause.button_pressed = true
	clock = seconds
	_layout()
	particles.restart(true)
	particles.speed_scale = 0
	particles.request_particles_process(seconds)
	await _settle()


func _settle() -> void:
	for frame in range(2):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _snapshot(filename: String) -> void:
	await _settle()
	var error := get_viewport().get_texture().get_image().save_png("res://tutorial/lessons/09_fields/" + filename)
	assert(error == OK)
	var bounds := particles.capture_rect()
	assert(bounds.position.is_finite() and bounds.size.is_finite())
	assert(bounds.size.length() < 4000, "粒子范围异常")
	print(filename, " bounds=", bounds)


func _capture() -> void:
	await get_tree().create_timer(0.3).timeout
	await _seek(3.0)
	await _snapshot("preview.png")
	_parameter("debug_view", 1)
	await _seek(3.0)
	await _snapshot("speed.png")
	_parameter("debug_view", 2)
	await _seek(3.0)
	await _snapshot("distance.png")
	_reset()
	_preset(true)
	await _seek(3.0)
	await _snapshot("outward.png")
	_reset()
	moving.button_pressed = true
	target_uv = Vector2(0.6, 0.7)
	await _seek(2.0)
	await _snapshot("transformed.png")
	wrong.button_pressed = true
	await _seek(2.0)
	await _snapshot("wrong_space.png")
	_reset()
	center_test.button_pressed = true
	await _seek(2.0)
	await _snapshot("center.png")
	var bounds := particles.capture_rect()
	assert(bounds.size.length() < 100, "中心零速度粒子不应被加速飞离")
	_reset()
	particles.fixed_fps = 15
	fps.select(2)
	await _seek(3.0)
	await _snapshot("fps15.png")
	_reset()
	moving.button_pressed = true
	await get_tree().create_timer(1.2).timeout
	target_uv = Vector2(0.38, 0.73)
	await get_tree().create_timer(0.6).timeout
	pause.button_pressed = true
	await _snapshot("moving.png")
	print("LESSON_09_CAPTURE_OK")
	get_tree().quit()

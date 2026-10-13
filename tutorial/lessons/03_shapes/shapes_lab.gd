extends Control

@onready var canvases: Array[ColorRect] = [$Square, $Wide]
var shape_select: OptionButton
var view_select: OptionButton
var sliders: Dictionary = {}
var aspect: CheckBox
var antialias: CheckBox
var labels: Array[Label] = []
var syncing := false


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	_reset()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		call_deferred("_smoke_test")
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		call_deferred("_capture")


func _set_parameter(key: String, value: Variant) -> void:
	for canvas in canvases:
		canvas.material.set_shader_parameter(key, value)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 12)
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var heading := Label.new()
	heading.text = "03 / 从坐标到形状：圆环、扇形与胶囊"
	heading.add_theme_font_size_override("font_size", 24)
	box.add_child(heading)
	var row := HBoxContainer.new()
	box.add_child(row)
	shape_select = _option(row, ["圆环", "扇形", "胶囊", "并集：圆环 + 胶囊", "差集：圆环减胶囊"], "shape")
	view_select = _option(row, ["成品", "原始 UV", "有符号场", "灰度遮罩"], "debug_view")
	var reset := Button.new()
	reset.text = "恢复基线"
	reset.pressed.connect(_reset)
	row.add_child(reset)
	_slider(box, "半径 / 胶囊半段长", "radius", 0.1, 0.4, 0.01, 0.28)
	_slider(box, "环宽 / 胶囊直径", "thickness", 0.02, 0.16, 0.01, 0.08)
	_slider(box, "旋转角（度）", "angle_degrees", -180, 180, 5, 0)
	_slider(box, "扇形张角（度）", "sector_degrees", 15, 180, 5, 90)
	_slider(box, "柔边宽度（本地像素）", "softness_px", 0, 12, 0.5, 2)
	var toggles := HBoxContainer.new()
	box.add_child(toggles)
	aspect = _checkbox(toggles, "宽高比校正（关闭以观察错误）", "correct_aspect")
	antialias = _checkbox(toggles, "fwidth 最小抗锯齿宽度", "derivative_aa")
	for title in ["A / 正方形画布", "B / 2:1 长方形画布"]:
		var label := Label.new()
		label.text = title
		add_child(label)
		labels.append(label)
	var footer := Label.new()
	footer.text = "两侧形状参数相同，各自传入真实画布尺寸。调整窗口会自动更新尺寸。\n实验：关宽高比校正 → 看圆变椭圆；切有符号场 → 看蓝色内部、橙色外部与白色边界。\n原始 UV 视图不经过旋转或宽高比校正。扇形不使用厚度参数。"
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 24
	footer.offset_top = -85
	footer.offset_bottom = -12
	add_child(footer)


func _option(parent: Control, entries: Array, parameter: String) -> OptionButton:
	var option := OptionButton.new()
	for entry in entries:
		option.add_item(entry)
	option.item_selected.connect(func(index: int) -> void: _set_parameter(parameter, index))
	parent.add_child(option)
	return option


func _checkbox(parent: Control, title: String, parameter: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = title
	check.toggled.connect(func(value: bool) -> void: _set_parameter(parameter, value))
	parent.add_child(check)
	return check


func _slider(parent: Control, title: String, parameter: String, low: float,
		high: float, step_size: float, initial: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 250
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size.x = 320
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	slider.value = initial
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = str(initial)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%.2f" % value
		_set_parameter(parameter, value)
	)
	sliders[parameter] = slider


func _layout() -> void:
	# 两侧短边相同；共同尺度下可直接比较形状大小。
	var side := maxf(100.0, minf((size.x - 120.0) / 3.0, size.y - 420.0))
	var left_x := (size.x - (side * 3.0 + 40.0)) * 0.5
	canvases[0].position = Vector2(left_x, 320)
	canvases[0].size = Vector2(side, side)
	canvases[1].position = Vector2(left_x + side + 40, 320)
	canvases[1].size = Vector2(side * 2, side)
	for i in range(2):
		canvases[i].material.set_shader_parameter("rect_size", canvases[i].size)
		labels[i].position = canvases[i].position - Vector2(0, 30)


func _reset() -> void:
	shape_select.select(0)
	view_select.select(0)
	_set_parameter("shape", 0)
	_set_parameter("debug_view", 0)
	var defaults := {"radius": 0.28, "thickness": 0.08, "angle_degrees": 0.0,
		"sector_degrees": 90.0, "softness_px": 2.0}
	for key in defaults:
		sliders[key].value = defaults[key]
		_set_parameter(key, defaults[key])
	aspect.button_pressed = true
	antialias.button_pressed = true
	_set_parameter("correct_aspect", true)
	_set_parameter("derivative_aa", true)


func _smoke_test() -> void:
	assert(canvases[0].material != canvases[1].material)
	assert(is_equal_approx(canvases[1].size.x / canvases[1].size.y, 2.0))
	for canvas in canvases:
		assert(canvas.material.get_shader_parameter("rect_size") == canvas.size)
	sliders["radius"].value = 0.35
	for canvas in canvases:
		assert(is_equal_approx(canvas.material.get_shader_parameter("radius"), 0.35))
	aspect.button_pressed = false
	assert(canvases[1].material.get_shader_parameter("correct_aspect") == false)
	shape_select.item_selected.emit(4)
	assert(canvases[0].material.get_shader_parameter("shape") == 4)
	view_select.item_selected.emit(2)
	assert(canvases[1].material.get_shader_parameter("debug_view") == 2)
	sliders["softness_px"].value = 0
	antialias.button_pressed = false
	assert(canvases[0].material.get_shader_parameter("derivative_aa") == false)
	_reset()
	assert(canvases[0].material.get_shader_parameter("shape") == 0)
	assert(canvases[1].material.get_shader_parameter("correct_aspect") == true)
	print("LESSON_03_SMOKE_TEST_OK")
	get_tree().quit()


func _save_frame(filename: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(
		"res://tutorial/lessons/03_shapes/" + filename)
	assert(error == OK)


func _capture() -> void:
	await get_tree().create_timer(1.0).timeout
	await _save_frame("preview.png")
	aspect.button_pressed = false
	await _save_frame("aspect_error.png")
	_reset()
	for i in range(1, 5):
		shape_select.select(i)
		_set_parameter("shape", i)
		await _save_frame("shape_%d.png" % i)
	view_select.select(2)
	_set_parameter("debug_view", 2)
	await _save_frame("field.png")
	print("LESSON_03_CAPTURE_OK")
	get_tree().quit()

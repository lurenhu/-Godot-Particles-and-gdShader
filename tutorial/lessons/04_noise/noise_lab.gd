extends Control

const NOISE := preload("noise.tres")
const DEFAULTS := {"progress": 0.45, "frequency": 2.0, "warp_amount": 0.06,
	"detail_weight": 0.3, "scroll_speed": 0.15, "edge_width": 0.06}
@onready var canvases: Array[ColorRect] = [$Dissolve, $Flame]
var sliders: Dictionary = {}
var view: OptionButton
var sampling: OptionButton
var pause: CheckBox
var clock := 0.0
var ready_noise := false
var labels: Array[Label] = []


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	_reset()
	# NoiseTexture2D 在后台线程生成，等数据就绪再推进演示时间。
	if NOISE.get_image() == null:
		await NOISE.changed
	ready_noise = true
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _process(delta: float) -> void:
	if ready_noise and not pause.button_pressed:
		clock += delta
		_set_parameter("lesson_time", clock)


func _set_parameter(parameter: String, value: Variant) -> void:
	for canvas in canvases:
		canvas.material.set_shader_parameter(parameter, value)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(24, 12)
	box.add_theme_constant_override("separation", 6)
	add_child(box)
	var title := Label.new()
	title.text = "04 / 噪声、UV 扭曲与溶解"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	view = _option(row, ["成品", "原噪声", "扭曲 UV", "组合噪声", "最终遮罩"], "debug_view")
	sampling = _option(row, ["线性 + Mipmap / 重复", "最近邻 / 重复", "线性 + Mipmap / 边缘夹取"], "sampling_mode")
	pause = CheckBox.new()
	pause.text = "暂停噪声时间"
	row.add_child(pause)
	var reset := Button.new()
	reset.text = "恢复基线"
	reset.pressed.connect(_reset)
	row.add_child(reset)
	_slider(box, "溶解进度（只影响左侧）", "progress", 0, 1, 0.01)
	_slider(box, "采样频率（纹理重复尺度）", "frequency", 0.5, 6, 0.1)
	_slider(box, "UV 扭曲振幅", "warp_amount", 0, 0.3, 0.01)
	_slider(box, "第二层噪声权重", "detail_weight", 0, 1, 0.05)
	_slider(box, "纵向滚动速度", "scroll_speed", -0.6, 0.6, 0.05)
	_slider(box, "溶解亮边宽度（噪声值域）", "edge_width", 0.005, 0.2, 0.005)
	for text_value in ["A / 圆形溶解：阈值与亮边", "B / 火焰遮罩：轮廓与向上流动"]:
		var label := Label.new()
		label.text = text_value
		add_child(label)
		labels.append(label)
	var note := Label.new()
	note.text = "先暂停时间再做单变量对照。溶解进度 0 = 完整，1 = 完全消失；亮边宽度只影响左侧。\n两侧共用一张可平铺的数据噪声。正滚动速度主要向上流动；第二层使用反向慢速滚动。\n调试视图：原噪声 → 扭曲 UV → 组合噪声 → 最终遮罩 → 成品。"
	note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	note.offset_left = 24
	note.offset_top = -86
	note.offset_bottom = -12
	add_child(note)


func _option(parent: Control, entries: Array, parameter: String) -> OptionButton:
	var option := OptionButton.new()
	for entry in entries:
		option.add_item(entry)
	option.item_selected.connect(func(index: int) -> void: _set_parameter(parameter, index))
	parent.add_child(option)
	return option


func _slider(parent: Control, title: String, parameter: String, low: float,
		high: float, step_size: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 330
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	slider.value = DEFAULTS[parameter]
	slider.custom_minimum_size.x = 320
	row.add_child(slider)
	var number := Label.new()
	number.text = "%.3f" % slider.value
	row.add_child(number)
	slider.value_changed.connect(func(value: float) -> void:
		number.text = "%.3f" % value
		_set_parameter(parameter, value)
	)
	sliders[parameter] = slider


func _layout() -> void:
	var side := maxf(100, minf((size.x - 160) * 0.5, size.y - 460))
	for i in range(2):
		canvases[i].size = Vector2(side, side)
		canvases[i].position = Vector2(size.x * (0.25 + i * 0.5) - side * 0.5, 350)
		labels[i].position = canvases[i].position - Vector2(0, 30)


func _reset() -> void:
	clock = 0
	pause.button_pressed = false
	_set_parameter("lesson_time", 0.0)
	view.select(0)
	sampling.select(0)
	_set_parameter("debug_view", 0)
	_set_parameter("sampling_mode", 0)
	for key in DEFAULTS:
		sliders[key].value = DEFAULTS[key]
		_set_parameter(key, DEFAULTS[key])


func _smoke_test() -> void:
	assert(NOISE.get_image() != null and NOISE.seamless)
	assert(canvases[0].material != canvases[1].material)
	assert(canvases[0].material.get_shader_parameter("effect") == 0)
	assert(canvases[1].material.get_shader_parameter("effect") == 1)
	for key in DEFAULTS:
		sliders[key].value = sliders[key].max_value
		for canvas in canvases:
			assert(is_equal_approx(canvas.material.get_shader_parameter(key), sliders[key].max_value))
	sampling.item_selected.emit(2)
	assert(canvases[0].material.get_shader_parameter("sampling_mode") == 2)
	pause.button_pressed = true
	var before := clock
	_process(1.0)
	assert(clock == before)
	_reset()
	assert(clock == 0 and not pause.button_pressed)
	print("LESSON_04_SMOKE_TEST_OK")
	get_tree().quit()


func _frame(filename: String) -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var frame := get_viewport().get_texture().get_image()
	var error := frame.save_png("res://tutorial/lessons/04_noise/" + filename)
	assert(error == OK)
	return frame


func _capture() -> void:
	pause.button_pressed = true
	_set_parameter("lesson_time", 1.0)
	await _frame("preview.png")
	for mode in range(1, 5):
		view.select(mode)
		_set_parameter("debug_view", mode)
		await _frame("debug_%d.png" % mode)
	# GPU 检查遮罩端点：圆心应从白变黑，火焰保持不变。
	sliders["progress"].value = 0
	var full := await _frame("endpoint_full.png")
	sliders["progress"].value = 1
	var empty := await _frame("endpoint_empty.png")
	# 捕获图像像素与拉伸后的逻辑画布坐标可能不同。
	var pixel_scale := Vector2(full.get_size()) / size
	var center := Vector2i((canvases[0].position + canvases[0].size * 0.5) * pixel_scale)
	assert(full.get_pixelv(center).r > 0.95)
	var maximum := 0.0
	var begin := (canvases[0].position * pixel_scale).ceil() + Vector2.ONE
	var end := ((canvases[0].position + canvases[0].size) * pixel_scale).floor() - Vector2.ONE
	for y in range(int(begin.y), int(end.y)):
		for x in range(int(begin.x), int(end.x)):
			maximum = maxf(maximum, empty.get_pixel(x, y).r)
	assert(maximum < 0.01, "进度为 1 时整个左侧遮罩必须为零")
	print("LESSON_04_GPU_ENDPOINTS_OK")
	get_tree().quit()

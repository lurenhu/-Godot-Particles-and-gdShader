extends Control

@onready var waves: Array[ColorRect] = [$WaveA, $WaveB]
var center := Vector2(0.44, 0.64)
var progress_slider: HSlider
var strength_slider: HSlider
var width_slider: HSlider
var pause: CheckBox
var second: CheckBox
var copy_between: CheckBox
var wrong: CheckBox
var outside: CheckBox
var view: OptionButton
var status: Label


func _ready() -> void:
	_build_ui()
	resized.connect(_update_centers)
	_reset()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _process(delta: float) -> void:
	if not pause.button_pressed:
		progress_slider.value = minf(1.0, progress_slider.value + delta / 2.0)
	status.text = "进度 %.2f / A 中心 (%.2f, %.2f) / 点击下方背景移动中心；扩散结束后点击重播。" % [progress_slider.value, center.x, center.y]


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y > 270:
			center = event.position / size
			_update_centers()


func _update_centers() -> void:
	# 本课根 Control 覆盖视口、无 Camera2D 或 CanvasLayer 变换。
	# 点击与绘制共用归一化视口坐标，缩放后重新换算。
	waves[0].material.set_shader_parameter("center_uv", center)
	waves[1].material.set_shader_parameter("center_uv", center + Vector2(0.12, 0.035))


func _parameter(key: String, value: Variant) -> void:
	for wave in waves:
		wave.material.set_shader_parameter(key, value)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 12)
	add_child(panel) # UI 最后绘制，不进入此前的屏幕拷贝。
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "06 / 屏幕采样：冲击波读取了哪一份画面？"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "重播（2 秒）", func() -> void:
		progress_slider.value = 0
		pause.button_pressed = false)
	_button(row, "恢复基线", _reset)
	pause = _check(row, "冻结进度", func(_value: bool) -> void: pass)
	second = _check(row, "显示 B", func(value: bool) -> void: waves[1].visible = value)
	copy_between = _check(row, "A 后再拷贝", func(value: bool) -> void:
		$CopyBetween.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT if value else BackBufferCopy.COPY_MODE_DISABLED)
	var options := HBoxContainer.new()
	box.add_child(options)
	wrong = _check(options, "错误采样坐标", func(value: bool) -> void: _parameter("wrong_uv", value))
	outside = _check(options, "错误：遮罩外也写回", func(value: bool) -> void: _parameter("opaque_outside", value))
	view = OptionButton.new()
	for entry in ["成品", "遮罩（请关闭 B）", "方向 RG / 遮罩 B"]:
		view.add_item(entry)
	view.item_selected.connect(func(index: int) -> void: _parameter("debug_view", index))
	options.add_child(view)
	# 连续进度不能每帧按 0.01 舍入，否则播放时长会随帧率变化。
	progress_slider = _slider(box, "扩散进度", "progress", 0, 1, 0)
	strength_slider = _slider(box, "采样偏移 / 渲染像素", "strength_px", -32, 32, 1)
	width_slider = _slider(box, "环带半宽 / 渲染像素", "width_px", 4, 48, 1)
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


func _slider(parent: Control, caption: String, key: String, low: float, high: float, step_size: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 270
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step_size
	slider.custom_minimum_size.x = 320
	row.add_child(slider)
	var value_label := Label.new()
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		_parameter(key, value)
		value_label.text = "%.2f" % value)
	return slider


func _reset() -> void:
	pause.button_pressed = true
	second.button_pressed = true
	waves[1].show()
	copy_between.button_pressed = false
	$CopyBetween.copy_mode = BackBufferCopy.COPY_MODE_DISABLED
	wrong.button_pressed = false
	outside.button_pressed = false
	view.select(0)
	_parameter("debug_view", 0)
	_parameter("wrong_uv", false)
	_parameter("opaque_outside", false)
	progress_slider.value = 0.45
	strength_slider.value = 18
	width_slider.value = 22
	center = Vector2(0.44, 0.64)
	_update_centers()


func _smoke_test() -> void:
	assert(waves[0].material != waves[1].material)
	assert(get_node("CopyBeforeA").get_index() < waves[0].get_index())
	assert(waves[0].get_index() < get_node("CopyBetween").get_index())
	assert(get_node("CopyBetween").get_index() < waves[1].get_index())
	copy_between.button_pressed = true
	assert($CopyBetween.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT)
	var before := progress_slider.value
	_process(1)
	assert(progress_slider.value == before)
	pause.button_pressed = false
	_process(0.2)
	assert(is_equal_approx(progress_slider.value, before + 0.1))
	progress_slider.value = 0
	for frame in range(120):
		_process(1.0 / 60.0)
	assert(is_equal_approx(progress_slider.value, 1.0))
	center = Vector2(0.2, 0.7)
	_update_centers()
	assert(waves[0].material.get_shader_parameter("center_uv") == center)
	_reset()
	assert($CopyBetween.copy_mode == 0 and pause.button_pressed)
	print("LESSON_06_SMOKE_TEST_OK")
	get_tree().quit()


func _snapshot(filename: String) -> Image:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png("res://tutorial/lessons/06_screen/" + filename)
	assert(error == OK)
	return image


func _capture() -> void:
	await get_tree().create_timer(0.5).timeout
	await _snapshot("preview.png")
	copy_between.button_pressed = true
	await _snapshot("sequential.png")
	second.button_pressed = false
	view.select(1)
	_parameter("debug_view", 1)
	await _snapshot("mask.png")
	view.select(0)
	_parameter("debug_view", 0)
	wrong.button_pressed = true
	await _snapshot("wrong_uv.png")
	_reset()
	outside.button_pressed = true
	await _snapshot("outside_write.png")
	_reset()
	# 隐藏 UI 后逐像素对照：终点应与不绘制波纹完全相同。
	get_child(get_child_count() - 1).hide()
	progress_slider.value = 1
	var ended := await _snapshot("endpoint.png")
	waves[0].hide()
	waves[1].hide()
	var background := await _snapshot("background.png")
	assert(ended.get_data() == background.get_data(), "终点不应改变背景")
	waves[0].show()
	progress_slider.value = 0.45
	var single := await _snapshot("single.png")
	_parameter("debug_view", 1)
	await _snapshot("mask_clean.png")
	var image_center := center * Vector2(single.get_size())
	var radius := lerpf(12.0, minf(single.get_width(), single.get_height()) * 0.32, 0.45)
	var changed_inside := 0
	for y in range(single.get_height()):
		for x in range(single.get_width()):
			# PNG 的 8 位灰度可能把很小的非零遮罩舍入成 0。
			# 用几何支持范围加 1 像素余量判定明确的环带外区域。
			var radial_error := absf((Vector2(x, y) + Vector2(0.5, 0.5)).distance_to(image_center) - radius)
			if radial_error > width_slider.value + 1.0:
				assert(single.get_pixel(x, y) == background.get_pixel(x, y), "零遮罩区域发生改动")
			elif single.get_pixel(x, y) != background.get_pixel(x, y):
				changed_inside += 1
	assert(changed_inside > 0, "环带内应确实产生扭曲")
	_parameter("debug_view", 0)
	_reset()
	get_child(get_child_count() - 1).show()
	get_window().size = Vector2i(1440, 900)
	await get_tree().process_frame
	await _snapshot("resized.png")
	print("LESSON_06_CAPTURE_OK: endpoint equals background; zero-mask unchanged; changed pixels ", changed_inside)
	get_tree().quit()

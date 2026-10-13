extends Control

@onready var emitters: Array[GPUParticles2D] = [$Stable, $Resampled]
var pause: CheckBox
var bad_random: CheckBox
var bad_decode: CheckBox
var identity: OptionButton
var view: OptionButton
var seed_input: SpinBox
var status: Label
var clock := 0.0


func _ready() -> void:
	_build_ui()
	resized.connect(_layout)
	_layout()
	_reset()
	if "--lesson-smoke-test" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--lesson-capture" in OS.get_cmdline_user_args():
		_capture()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0a1323"))
	draw_line(Vector2(size.x / 2, 280), Vector2(size.x / 2, size.y - 40), Color("334155"), 1)


func _layout() -> void:
	for i in range(2):
		emitters[i].position = Vector2(size.x * (0.25 + 0.5 * i), size.y * 0.63)
	queue_redraw()


func _process(delta: float) -> void:
	if not pause.button_pressed:
		clock += delta
	status.text = "种子 %d / 脚本时间 %.2f s（非 GPU 年龄读数） / 每 3 秒自然重生；观察同一格。" % [int(seed_input.value), clock]


func _replay() -> void:
	clock = 0
	pause.button_pressed = false
	for emitter in emitters:
		emitter.seed = int(seed_input.value)
		emitter.speed_scale = 1
		emitter.restart(true)


func _set_identity(index: int) -> void:
	for emitter in emitters:
		emitter.process_material.set_shader_parameter("use_number", index == 0)
	_replay()


func _set_view(index: int) -> void:
	for emitter in emitters:
		emitter.material.set_shader_parameter("debug_view", index)


func _build_ui() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 12)
	add_child(box)
	var title := Label.new()
	title.text = "08 / 随机种子与数据协议：出生属性怎样保持稳定？"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "相同种子重播", _replay)
	_button(row, "种子 +1 并重播", func() -> void:
		seed_input.value += 1
		_replay())
	_button(row, "恢复基线", _reset)
	pause = _check(row, "冻结模拟", func(value: bool) -> void:
		for emitter in emitters:
			emitter.speed_scale = 0 if value else 1)
	var controls := HBoxContainer.new()
	box.add_child(controls)
	var seed_label := Label.new()
	seed_label.text = "种子（修改后重播）"
	controls.add_child(seed_label)
	seed_input = SpinBox.new()
	seed_input.min_value = 1
	seed_input.max_value = 999999
	controls.add_child(seed_input)
	identity = OptionButton.new()
	identity.add_item("NUMBER：每次出生换一组")
	identity.add_item("INDEX：每个槽位固定一组")
	identity.item_selected.connect(_set_identity)
	controls.add_child(identity)
	view = OptionButton.new()
	for label in ["成品", "x：年龄灰度", "y：相位灰度", "z：大小归一化", "w：类型颜色"]:
		view.add_item(label)
	view.item_selected.connect(_set_view)
	controls.add_child(view)
	var errors := HBoxContainer.new()
	box.add_child(errors)
	bad_random = _check(errors, "右侧：每步重抽属性", func(value: bool) -> void:
		emitters[1].process_material.set_shader_parameter("resample_each_step", value))
	bad_decode = _check(errors, "右侧：故意交换相位与大小通道", func(value: bool) -> void:
		emitters[1].material.set_shader_parameter("wrong_decode", value))
	status = Label.new()
	box.add_child(status)
	var note := Label.new()
	note.text = "调试视图使用固定大小、忽略淡出。修复右侧后请重播，重新初始化四个通道。"
	box.add_child(note)
	var captions := HBoxContainer.new()
	captions.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	captions.offset_top = 265
	add_child(captions)
	for caption in ["A / 出生确定，生命期内保持\nstart 写相位、大小和类型", "B / 可切换的错误对照\nprocess 重抽 / 绘制端错读"]:
		var label := Label.new()
		label.text = caption
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


func _reset() -> void:
	seed_input.value = 137
	bad_random.button_pressed = true
	bad_decode.button_pressed = false
	emitters[0].process_material.set_shader_parameter("resample_each_step", false)
	emitters[1].process_material.set_shader_parameter("resample_each_step", true)
	emitters[1].material.set_shader_parameter("wrong_decode", false)
	view.select(0)
	_set_view(0)
	identity.select(0)
	_set_identity(0)


func _smoke_test() -> void:
	assert(emitters[0].material != emitters[1].material)
	assert(emitters[0].process_material != emitters[1].process_material)
	for emitter in emitters:
		assert(emitter.amount == 12 and emitter.local_coords and emitter.use_fixed_seed)
	pause.button_pressed = true
	var before := clock
	_process(1)
	assert(clock == before and emitters[0].speed_scale == 0)
	bad_random.button_pressed = false
	assert(emitters[1].process_material.get_shader_parameter("resample_each_step") == false)
	_set_identity(1)
	assert(emitters[0].process_material.get_shader_parameter("use_number") == false)
	seed_input.value = 138
	_replay()
	assert(emitters[0].seed == 138 and emitters[1].seed == 138)
	_reset()
	print("LESSON_08_SMOKE_TEST_OK")
	get_tree().quit()


func _seek(seconds: float) -> void:
	pause.button_pressed = true
	clock = seconds
	for emitter in emitters:
		emitter.seed = int(seed_input.value)
		emitter.restart(true)
		emitter.speed_scale = 0
		emitter.request_particles_process(seconds)
	await _settle()


func _settle() -> void:
	for frame in range(2):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _snapshot(filename: String) -> Image:
	await _settle()
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png("res://tutorial/lessons/08_data_protocol/" + filename)
	assert(error == OK)
	return image


func _panel_bytes(image: Image, panel: int) -> PackedByteArray:
	# 排除 UI 和标题，只比较固定粒子区域；按实际截图尺寸换算。
	var scale_xy := Vector2(image.get_size()) / size
	var region := Rect2i(Vector2(size.x * (0.05 + 0.5 * panel), size.y * 0.63 - 140) * scale_xy,
		Vector2(size.x * 0.4, 280) * scale_xy)
	return image.get_region(region).get_data()


func _capture() -> void:
	await get_tree().create_timer(0.3).timeout
	await _seek(0.6)
	await _snapshot("preview.png")
	view.select(2)
	_set_view(2)
	var phase_a := await _snapshot("phase_a.png")
	# 不重播，继续同一批粒子，验证跨步稳定性。
	for emitter in emitters:
		emitter.request_particles_process(0.4)
	clock = 1.0
	var phase_b := await _snapshot("phase_b.png")
	assert(_panel_bytes(phase_a, 0) == _panel_bytes(phase_b, 0), "出生相位应跨步保持")
	assert(_panel_bytes(phase_a, 1) != _panel_bytes(phase_b, 1), "错误重抽应改变相位")
	await _seek(0.6)
	var replay := await _snapshot("same_seed.png")
	assert(_panel_bytes(phase_a, 0) == _panel_bytes(replay, 0), "固定种子重播应复现")
	seed_input.value = 138
	await _seek(0.6)
	var changed := await _snapshot("new_seed.png")
	assert(_panel_bytes(phase_a, 0) != _panel_bytes(changed, 0), "新种子应改变分布")
	seed_input.value = 137
	bad_random.button_pressed = false
	await _seek(3.6)
	var next_birth := await _snapshot("number_next_birth.png")
	assert(_panel_bytes(phase_a, 0) != _panel_bytes(next_birth, 0), "NUMBER 应区分自然重生")
	identity.select(1)
	_set_identity(1)
	await _seek(0.6)
	var slot_first := await _snapshot("index_first.png")
	await _seek(3.6)
	var slot_next := await _snapshot("index_next_birth.png")
	assert(_panel_bytes(slot_first, 0) == _panel_bytes(slot_next, 0), "INDEX 应复用槽位相位")
	view.select(1)
	_set_view(1)
	var reborn_age := await _snapshot("age_after_rebirth.png")
	await _seek(0.6)
	var first_age := await _snapshot("age_first.png")
	var pixel_scale := Vector2(first_age.get_size()) / size
	for slot in range(12):
		var local_position := Vector2(float(slot % 4) - 1.5, float(slot / 4) - 1.0) * Vector2(90, 100)
		var point := Vector2i((emitters[0].position + local_position) * pixel_scale)
		var first_value := first_age.get_pixelv(point).r
		var reborn_value := reborn_age.get_pixelv(point).r
		assert(first_value > 0.1 and first_value < 0.35, "年龄图必须显示年轻粒子")
		assert(absf(first_value - reborn_value) < 0.02, "自然重生应重新计龄")
	view.select(3)
	_set_view(3)
	await _snapshot("size_debug.png")
	view.select(4)
	_set_view(4)
	await _snapshot("kind_debug.png")
	view.select(0)
	_set_view(0)
	bad_decode.button_pressed = true
	await _snapshot("wrong_protocol.png")
	print("LESSON_08_CAPTURE_OK: stable phase, replay, new seed, NUMBER and INDEX rebirth")
	get_tree().quit()

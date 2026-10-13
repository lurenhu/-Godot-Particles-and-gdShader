extends Node3D

const NORMAL_BOUNDS := AABB(Vector3(-1.5, 0.0, -1.5), Vector3(3.0, 3.3, 3.0))
@onready var fixed: GPUParticles3D = $Fixed
@onready var facing: GPUParticles3D = $Billboard
@onready var camera: Camera3D = $Camera
@onready var environment: Environment = $WorldEnvironment.environment
var yaw_slider: HSlider
var energy_slider: HSlider
var pause_box: CheckBox
var glow_box: CheckBox
var light_box: CheckBox
var card_box: CheckBox
var color_box: CheckBox
var probe_box: CheckBox
var bounds_box: CheckBox
var wall_box: CheckBox
var order_option: OptionButton
var status: Label
var walls: Array[MeshInstance3D] = []


func _ready() -> void:
	_build_stage()
	_build_ui()
	_reset()
	if "--lesson-test" in OS.get_cmdline_user_args():
		call_deferred("_verify")


func _build_stage() -> void:
	_box(Vector3(10.0, 0.15, 7.0), Vector3(0.0, -0.15, 0.0), Color("26334b"))
	for x in [-1.8, 1.8]:
		_box(Vector3(2.7, 0.12, 2.7), Vector3(x, -0.02, 0.0), Color("455874"))
		walls.append(_box(Vector3(0.65, 2.1, 0.25), Vector3(x, 1.05, 0.0), Color("a5adb9")))
		var label := Label3D.new()
		label.text = "A · 固定 XY 卡片" if x < 0 else "B · 面向相机"
		label.position = Vector3(x, 3.1, 0.0)
		label.font_size = 48
		label.pixel_size = 0.006
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	add_child(instance)
	return instance


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 12)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "第十一课 · 3D 粒子与 Spatial Shader"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "同步重播", _replay)
	_button(row, "恢复基线", _reset)
	_button(row, "正面", func(): yaw_slider.value = 0.0)
	_button(row, "侧面 90°", func(): yaw_slider.value = 90.0)
	pause_box = _check(row, "冻结粒子", func(value):
		for emitter in [fixed, facing]:
			emitter.speed_scale = 0.0 if value else 1.0)
	row = HBoxContainer.new()
	box.add_child(row)
	glow_box = _check(row, "Glow", func(value): environment.glow_enabled = value)
	light_box = _check(row, "亮背景", func(value):
		environment.background_color = Color(0.65, 0.7, 0.8) if value else Color(0.018, 0.028, 0.06))
	card_box = _check(row, "显示方卡", func(value): _draw_parameter("show_card", value))
	color_box = _check(row, "错误：丢弃粒子颜色", func(value): _draw_parameter("ignore_particle_color", value))
	wall_box = _check(row, "不透明遮挡柱", func(value):
		for wall in walls:
			wall.visible = value)
	row = HBoxContainer.new()
	box.add_child(row)
	probe_box = _check(row, "B 原点移出镜头", func(_value): _configure_bounds())
	bounds_box = _check(row, "错误：B 极小包围盒", func(_value): _configure_bounds())
	order_option = OptionButton.new()
	order_option.add_item("按视深排序", GPUParticles3D.DRAW_ORDER_VIEW_DEPTH)
	order_option.add_item("按索引排序", GPUParticles3D.DRAW_ORDER_INDEX)
	order_option.item_selected.connect(func(index):
		for emitter in [fixed, facing]:
			emitter.draw_order = order_option.get_item_id(index))
	row.add_child(order_option)
	yaw_slider = _slider(box, "相机方位角（度）", -180.0, 180.0, 1.0)
	yaw_slider.value_changed.connect(_orbit)
	energy_slider = _slider(box, "Emission 强度", 0.0, 6.0, 0.1)
	energy_slider.value_changed.connect(func(value): _draw_parameter("emission_energy", value))
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


func _slider(parent: Control, caption: String, minimum: float, maximum: float, step: float) -> HSlider:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size.x = 180.0
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.custom_minimum_size.x = 390.0
	row.add_child(slider)
	return slider


func _orbit(degrees: float) -> void:
	var angle := deg_to_rad(degrees)
	camera.position = Vector3(sin(angle) * 10.5, 4.4, cos(angle) * 10.5)
	camera.look_at(Vector3(0.0, 1.6, 0.0))


func _process(_delta: float) -> void:
	status.text = "方位 %.0f°  |  Emission %.1f  |  80 × 2 颗  |  修改绘制参数无需重播\n包围盒实验会自动重播；冻结后仍可转动相机。" % [yaw_slider.value, energy_slider.value]


func _draw_parameter(parameter: String, value: Variant) -> void:
	for emitter in [fixed, facing]:
		var material: ShaderMaterial = emitter.draw_pass_1.material
		material.set_shader_parameter(parameter, value)


func _configure_bounds() -> void:
	var displacement := 14.0 if probe_box.button_pressed else 0.0
	facing.position.x = 1.8 + displacement
	facing.process_material.set_shader_parameter("spawn_offset_x", -displacement)
	var bounds := NORMAL_BOUNDS
	bounds.position.x -= displacement
	facing.visibility_aabb = AABB(Vector3(-0.05, 0.0, -0.05), Vector3.ONE * 0.1) if bounds_box.button_pressed else bounds
	_replay()


func _replay() -> void:
	pause_box.button_pressed = false
	for emitter in [fixed, facing]:
		emitter.speed_scale = 1.0
		emitter.restart(true)


func _reset() -> void:
	for check in [pause_box, glow_box, light_box, card_box, color_box, probe_box, bounds_box]:
		check.button_pressed = false
	wall_box.button_pressed = true
	order_option.select(0)
	for emitter in [fixed, facing]:
		emitter.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	yaw_slider.value = 0.0
	_orbit(0.0)
	energy_slider.value = 2.0
	_configure_bounds()


func _seek() -> void:
	_replay()
	pause_box.button_pressed = true
	for emitter in [fixed, facing]:
		emitter.request_particles_process(3.0)
	await _settle()


func _settle() -> void:
	for frame in range(3):
		await get_tree().process_frame
		await RenderingServer.frame_post_draw


func _snapshot(filename: String) -> void:
	await _settle()
	var error := get_viewport().get_texture().get_image().save_png("res://tutorial/lessons/11_spatial/" + filename)
	assert(error == OK)


func _verify() -> void:
	await get_tree().create_timer(0.4).timeout
	assert(fixed.draw_pass_1 != facing.draw_pass_1)
	assert(fixed.draw_pass_1.material != facing.draw_pass_1.material)
	assert(not fixed.draw_pass_1.material.get_shader_parameter("billboard"))
	assert(facing.draw_pass_1.material.get_shader_parameter("billboard"))
	await _seek()
	await _snapshot("preview.png")
	for emitter in [fixed, facing]:
		var bounds: AABB = emitter.capture_aabb()
		assert(bounds.position.is_finite() and bounds.size.is_finite())
		print(emitter.name, " capture_aabb=", bounds)
	card_box.button_pressed = true
	yaw_slider.value = 90.0
	await _snapshot("side_cards.png")
	card_box.button_pressed = false
	yaw_slider.value = 0.0
	energy_slider.value = 6.0
	await _snapshot("emission_only.png")
	glow_box.button_pressed = true
	await _snapshot("glow.png")
	glow_box.button_pressed = false
	light_box.button_pressed = true
	await _snapshot("light_background.png")
	_reset()
	probe_box.button_pressed = true
	assert(is_equal_approx(facing.position.x + float(facing.process_material.get_shader_parameter("spawn_offset_x")), 1.8))
	assert(facing.visibility_aabb.has_point(Vector3(-14.0, 1.6, 0.0)))
	await _seek()
	await _snapshot("bounds_correct.png")
	bounds_box.button_pressed = true
	assert(not facing.visibility_aabb.has_point(Vector3(-14.0, 1.6, 0.0)))
	await _seek()
	await _snapshot("bounds_wrong.png")
	_reset()
	await _seek()
	color_box.button_pressed = true
	await _snapshot("color_wrong.png")
	color_box.button_pressed = false
	wall_box.button_pressed = false
	await _snapshot("no_occluder.png")
	card_box.button_pressed = true
	order_option.select(1)
	order_option.item_selected.emit(1)
	assert(facing.draw_order == GPUParticles3D.DRAW_ORDER_INDEX)
	await _snapshot("index_order.png")
	assert(fixed.speed_scale == 0.0 and facing.speed_scale == 0.0)
	pause_box.button_pressed = false
	assert(fixed.speed_scale == 1.0 and facing.speed_scale == 1.0)
	_reset()
	assert(not probe_box.button_pressed and not bounds_box.button_pressed)
	assert(facing.visibility_aabb == NORMAL_BOUNDS)
	assert(facing.draw_order == GPUParticles3D.DRAW_ORDER_VIEW_DEPTH)
	assert(is_equal_approx(energy_slider.value, 2.0))
	print("LESSON_11_TEST_OK")
	get_tree().quit()

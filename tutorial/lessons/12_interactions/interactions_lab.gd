extends Node3D

@onready var flight: GPUParticles3D = $Flight
@onready var sparks: GPUParticles3D = $Sparks
@onready var motion: ParticleProcessMaterial = flight.process_material
@onready var trail_draw: StandardMaterial3D = flight.draw_pass_1.material
@onready var attractor: GPUParticlesAttractorSphere3D = $Attractor
var ribbon: RibbonTrailMesh
var tube: TubeTrailMesh
var dot: SphereMesh
var checks: Dictionary = {}
var mesh_option: OptionButton
var trail_slider: HSlider
var status: Label
var marker: MeshInstance3D
var turbulence_available := true


func _ready() -> void:
	$Camera.position = Vector3(8, 6, 11)
	$Camera.look_at(Vector3(0, 1.2, 0))
	_prepare_meshes()
	_build_ui()
	# 本机验证中 D3D12 在启用湍流后设备丢失；只在本课限制入口。
	turbulence_available = RenderingServer.get_current_rendering_driver_name() != "d3d12"
	checks["turbulence"].disabled = not turbulence_available
	checks["turbulence"].tooltip_text = "本课 D3D12 验证出现设备错误；湍流实验请使用讲义中的 Vulkan 启动方式。"
	_reset()
	if "--lesson-test" in OS.get_cmdline_user_args():
		call_deferred("_verify")


func _prepare_meshes() -> void:
	ribbon = flight.draw_pass_1
	tube = TubeTrailMesh.new()
	tube.radius = ribbon.size * 0.5
	tube.radial_steps = 6
	tube.sections = ribbon.sections
	tube.section_length = ribbon.section_length
	tube.section_rings = 3
	tube.curve = ribbon.curve
	tube.material = trail_draw
	dot = SphereMesh.new()
	dot.radius = 0.06
	dot.height = 0.12
	dot.radial_segments = 8
	dot.rings = 4
	var dot_draw := trail_draw.duplicate() as StandardMaterial3D
	dot_draw.use_particle_trails = false
	dot.material = dot_draw
	marker = MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.12
	marker_mesh.height = 0.24
	var marker_draw := StandardMaterial3D.new()
	marker_draw.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker_draw.albedo_color = Color("cf92ff")
	marker_mesh.material = marker_draw
	marker.mesh = marker_mesh
	attractor.add_child(marker)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 12)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "第十二课 · 拖尾与环境交互"
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)
	var row := HBoxContainer.new()
	box.add_child(row)
	_button(row, "重播", _replay)
	_button(row, "恢复基线", _reset)
	_button(row, "停止新发射", func(): flight.emitting = false)
	_button(row, "正面", func():
		$Camera.position = Vector3(0, 4, 12)
		$Camera.look_at(Vector3(0, 1.2, 0)))
	_button(row, "斜侧面", func():
		$Camera.position = Vector3(8, 6, 11)
		$Camera.look_at(Vector3(0, 1.2, 0)))
	row = HBoxContainer.new()
	box.add_child(row)
	_check(row, "collision", "粒子碰撞")
	_check(row, "sub", "二次火花")
	_check(row, "turbulence", "湍流")
	_check(row, "attractor", "吸引器")
	row = HBoxContainer.new()
	box.add_child(row)
	_check(row, "floor", "显示地面")
	_check(row, "wrong", "错误：材质未启用拖尾")
	_check(row, "inherit", "子粒子继承速度")
	row = HBoxContainer.new()
	box.add_child(row)
	mesh_option = OptionButton.new()
	for text in ["Ribbon 拖尾", "Tube 拖尾", "圆点（关闭拖尾）"]:
		mesh_option.add_item(text)
	mesh_option.item_selected.connect(func(_index): _apply())
	row.add_child(mesh_option)
	var label := Label.new()
	label.text = "拖尾历史 / 秒"
	row.add_child(label)
	trail_slider = HSlider.new()
	trail_slider.min_value = 0.1
	trail_slider.max_value = 0.8
	trail_slider.step = 0.05
	trail_slider.custom_minimum_size.x = 150
	trail_slider.value_changed.connect(func(_value): _apply())
	row.add_child(trail_slider)
	status = Label.new()
	box.add_child(status)
	var hint := Label.new()
	hint.text = "橙色：母粒子 / 青色：碰撞子粒子 / 紫球：吸引中心\n参数变更会重播；地面可见性独立于粒子碰撞。"
	box.add_child(hint)


func _button(row: HBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	row.add_child(button)


func _check(row: HBoxContainer, key: String, text: String) -> void:
	var check := CheckBox.new()
	check.text = text
	check.toggled.connect(func(_value): _apply())
	checks[key] = check
	row.add_child(check)


func _enabled(key: String) -> bool:
	return checks[key].button_pressed


func _reset() -> void:
	for key in checks:
		checks[key].set_pressed_no_signal(key in ["collision", "sub", "floor"])
	mesh_option.select(0)
	trail_slider.set_value_no_signal(0.35)
	$Camera.position = Vector3(8, 6, 11)
	$Camera.look_at(Vector3(0, 1.2, 0))
	_apply()


func _apply() -> void:
	# 同时停用检测节点，避免只关反弹却仍触发碰撞子发射。
	$ParticleFloor.visible = _enabled("collision")
	motion.collision_mode = ParticleProcessMaterial.COLLISION_RIGID if _enabled("collision") else ParticleProcessMaterial.COLLISION_DISABLED
	motion.sub_emitter_mode = ParticleProcessMaterial.SUB_EMITTER_AT_COLLISION if _enabled("sub") else ParticleProcessMaterial.SUB_EMITTER_DISABLED
	motion.turbulence_enabled = turbulence_available and _enabled("turbulence")
	motion.sub_emitter_keep_velocity = _enabled("inherit")
	attractor.strength = 8.0 if _enabled("attractor") else 0.0
	marker.visible = _enabled("attractor")
	$Floor.visible = _enabled("floor")
	trail_draw.use_particle_trails = not _enabled("wrong")
	flight.trail_enabled = mesh_option.selected != 2
	flight.draw_pass_1 = [ribbon, tube, dot][mesh_option.selected]
	flight.trail_lifetime = trail_slider.value
	status.text = "母粒子 24 / 子粒子容量 256 / 每次碰撞请求 6 / 拖尾 %.2f s" % trail_slider.value
	_replay()


func _replay() -> void:
	# 先清除旧子粒子，再开始新一轮母粒子；子发射链接始终保留。
	sparks.restart(true)
	sparks.emitting = false
	flight.restart(true)
	flight.emitting = true


func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("无法读取 GPU 画面，停止验证。")
		get_tree().quit(1)
		return
	assert(image.save_png("res://tutorial/lessons/12_interactions/" + file_name + ".png") == OK)


func _verify() -> void:
	assert(flight.get_node(flight.sub_emitter) == sparks)
	assert(not flight.local_coords and not sparks.local_coords)
	assert(flight.transform_align == GPUParticles3D.TRANSFORM_ALIGN_Y_TO_VELOCITY)
	await get_tree().create_timer(3.0).timeout
	await _capture("preview")
	print("BASELINE flight bounds: ", flight.capture_aabb())
	print("BASELINE sparks bounds: ", sparks.capture_aabb())
	checks["sub"].button_pressed = false
	await get_tree().create_timer(3.0).timeout
	await _capture("no_sub")
	_reset()
	checks["floor"].button_pressed = false
	assert($ParticleFloor.visible and not $Floor.visible)
	await get_tree().create_timer(2.8).timeout
	await _capture("invisible_floor")
	_reset()
	checks["collision"].button_pressed = false
	checks["floor"].button_pressed = false
	await get_tree().create_timer(2.8).timeout
	await _capture("no_collision")
	_reset()
	mesh_option.select(1)
	_apply()
	await get_tree().create_timer(2.8).timeout
	await _capture("tube")
	if turbulence_available:
		checks["turbulence"].button_pressed = true
		await get_tree().create_timer(2.8).timeout
		await _capture("turbulence")
	else:
		print("TURBULENCE_SKIPPED_D3D12: use Vulkan for the full lesson")
	_reset()
	checks["attractor"].button_pressed = true
	await get_tree().create_timer(2.8).timeout
	await _capture("attractor")
	_reset()
	checks["wrong"].button_pressed = true
	await get_tree().create_timer(2.8).timeout
	await _capture("wrong_trails")
	_reset()
	checks["inherit"].button_pressed = true
	assert(motion.sub_emitter_keep_velocity)
	await get_tree().create_timer(2.8).timeout
	await _capture("inherit_velocity")
	mesh_option.select(2)
	_apply()
	assert(not flight.trail_enabled)
	await get_tree().create_timer(2.8).timeout
	await _capture("dots")
	_reset()
	await get_tree().create_timer(2.0).timeout
	flight.emitting = false
	await get_tree().create_timer(5.0).timeout
	await _capture("stopped")
	assert(not flight.emitting)
	assert(trail_draw.use_particle_trails and not motion.turbulence_enabled)
	trail_slider.value = 0.8
	assert(is_equal_approx(flight.trail_lifetime, 0.8))
	trail_slider.value = 0.1
	assert(is_equal_approx(flight.trail_lifetime, 0.1))
	_reset()
	assert(is_equal_approx(flight.trail_lifetime, 0.35))
	assert(flight.emitting and attractor.strength == 0.0)
	print("LESSON_12_TEST_OK")
	get_tree().quit()

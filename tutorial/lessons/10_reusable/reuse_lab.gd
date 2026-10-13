extends Node2D
const IMPACT = preload("res://tutorial/lessons/10_reusable/impact.tscn")
const COLORS = [Color("55dcff"), Color("ffaf55"), Color("c985ff")]
var effects: Array[Node2D] = []
var shared_error: CheckBox
var pause_a: CheckBox
var status: Label
var finished_count := 0
var next_slot := 0

func _ready() -> void:
	for i in range(3):
		var effect = IMPACT.instantiate()
		add_child(effect)
		effects.append(effect)
		effect.finished.connect(func(): finished_count += 1)
	_build_ui()
	_replay()
	if "--lesson-test" in OS.get_cmdline_user_args(): _verify()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("101c30"))
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 190), Vector2(x, size.y), Color("233854"))
	for y in range(190, int(size.y), 32):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("233854"))

func _process(_delta: float) -> void:
	queue_redraw()
	var lines := ""
	for i in range(3):
		lines += "%s  t=%.2f  %s   " % [char(65 + i), effects[i].effect_time, "暂停" if effects[i].paused else ("播放" if effects[i].playing else "待机")]
	status.text = lines + "\n完成通知总数：%d（重播中断不计完成）" % finished_count

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 12)
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "第十课 · 可复用特效与控制接口"
	title.add_theme_font_size_override("font_size", 25)
	box.add_child(title)
	var help := Label.new()
	help.text = "点击网格：轮流复用 A / B / C；三组重播会恢复默认位置、颜色和强度。"
	box.add_child(help)
	var row := HBoxContainer.new()
	box.add_child(row)
	var replay := Button.new()
	replay.text = "三组重播 / 恢复基线"
	replay.pressed.connect(_replay)
	row.add_child(replay)
	var rapid := Button.new()
	rapid.text = "只重播 A"
	rapid.pressed.connect(func(): _play_slot(0, effects[0].position))
	row.add_child(rapid)
	pause_a = CheckBox.new()
	pause_a.text = "暂停 A"
	pause_a.toggled.connect(func(value): effects[0].set_paused(value))
	row.add_child(pause_a)
	shared_error = CheckBox.new()
	shared_error.text = "错误：共享爆点绘制材质"
	shared_error.toggled.connect(_sharing)
	row.add_child(shared_error)
	status = Label.new()
	box.add_child(status)

func _play_slot(index: int, at: Vector2) -> void:
	effects[index].play(at, Vector2.RIGHT.rotated(-0.4 * index), 0.7 + 0.2 * index, COLORS[index])
	if index == 0: pause_a.set_pressed_no_signal(false)

func _replay() -> void:
	if shared_error.button_pressed:
		shared_error.set_pressed_no_signal(false)
		for effect in effects: effect.burst.material = effect.burst.material.duplicate()
	var size := get_viewport_rect().size
	for i in range(3): _play_slot(i, Vector2(size.x * (0.23 + i * 0.27), size.y * 0.6))

func _sharing(enabled: bool) -> void:
	for i in range(1, 3):
		effects[i].burst.material = effects[0].burst.material if enabled else effects[i].burst.material.duplicate()
	# 最后播放的 C 将共享材质写成紫色；其他层仍独立。
	for i in range(3): _play_slot(i, effects[i].position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.position.y < 190: return
		_play_slot(next_slot, event.position)
		next_slot = (next_slot + 1) % 3

func _snapshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png("res://tutorial/lessons/10_reusable/" + filename)
	assert(error == OK)

func _verify() -> void:
	await get_tree().create_timer(0.25).timeout
	for i in range(1, 3):
		assert(effects[0].burst.material != effects[i].burst.material)
		assert(effects[0].burst.process_material != effects[i].burst.process_material)
		assert(effects[0].ring.material != effects[i].ring.material)
		assert(effects[i].burst.material.get_shader_parameter("tint") == COLORS[i])
	effects[0].set_paused(true)
	var frozen: float = effects[0].effect_time
	await _snapshot("preview.png")
	await get_tree().create_timer(0.3).timeout
	assert(effects[0].effect_time == frozen)
	assert(effects[1].effect_time > frozen)
	assert(effects[0].burst.speed_scale == 0.0)
	effects[0].set_paused(false)
	# 在旧 Tween 原本即将结束前替换它，确认旧回调不会清理新播放。
	_play_slot(0, effects[0].position)
	await get_tree().create_timer(0.12).timeout
	_play_slot(0, effects[0].position)
	await get_tree().create_timer(0.5).timeout
	assert(effects[0].playing and not effects[0].completed.has("visual"))
	await get_tree().create_timer(2.0).timeout
	assert(finished_count == 3, "每个最终播放应只通知一次完成")
	for effect in effects: assert(not effect.playing and not effect.visible)
	_sharing(true)
	assert(effects[0].burst.material == effects[2].burst.material)
	assert(effects[0].burst.material.get_shader_parameter("tint") == COLORS[2])
	await get_tree().create_timer(0.25).timeout
	await _snapshot("shared_error.png")
	_sharing(false)
	assert(effects[0].burst.material != effects[2].burst.material)
	# 重叠实例检验每个实例自己的屏幕拷贝顺序。
	for i in range(3): _play_slot(i, Vector2(540 + i * 65, 480))
	await get_tree().create_timer(0.25).timeout
	await _snapshot("overlap.png")
	var transient = IMPACT.instantiate()
	transient.free_on_finish = true
	add_child(transient)
	transient.play(Vector2(150, 400), Vector2.ZERO, 99.0, Color.WHITE)
	assert(transient.rotation == 0.0)
	assert(is_equal_approx(transient.ring.material.get_shader_parameter("intensity"), 1.2))
	await get_tree().create_timer(2.5).timeout
	assert(not is_instance_valid(transient))
	print("LESSON_10_TEST_OK: isolation, pause, replay, completion, sharing, clamp, free")
	get_tree().quit()

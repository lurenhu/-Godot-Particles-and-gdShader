# 组件接口与数据约定

[讲义](README.md) · [组件目录](../../final_project/arcane_spell/README.md)

## 实例化与调用

```gdscript
const SPELL = preload("res://tutorial/final_project/arcane_spell/spell.tscn")

func cast() -> void:
	var effect = SPELL.instantiate()
	add_child(effect)
	effect.impacted.connect(_on_visual_impact)
	effect.finished.connect(_on_visual_finished)
	var run_id: int = effect.play(Vector2(200, 350), Vector2(650, 350), {
		"color": Color("52bdff"),
		"intensity": 1.0,
		"radius": 120.0,
		"speed": 1.0,
		"quality": 2,
		"seed": 137
	})
	print("本实例第 ", run_id, " 次播放")


func _on_visual_impact(run_id: int, at: Vector2) -> void:
	print("视觉到达目标：", run_id, "，位置：", at)


func _on_visual_finished(run_id: int) -> void:
	print("自然结束：", run_id)
```

代码示例创建的组件默认保留；实际接入时保存引用以复用，或在 play 前设 `free_on_finish=true`，不要无限新建且不回收。

| 接口 | 语义 |
| --- | --- |
| play(from, to, options) → int | 必须先加入树且完成 ready；取消旧播放，复制并应用本次参数，返回递增的实例内 run_id |
| set_paused(bool) | 暂停本实例时钟与 GPU 模拟；其他实例继续 |
| cancel() | 立即隐藏、停模拟，不发送自然结束或补发命中事件 |
| free_on_finish | false：自然结束后隐藏复用；true：排队释放，再发 finished |
| impacted(run_id, at) | 时钟首次跨过 1.3 时发送；at 属于父级局部坐标，不是物理碰撞回调 |
| finished(run_id) | 自然到达 2.6 后发送一次；中断重播的旧一轮不会发此信号 |

`run_id` 只在单实例内递增，不是全局唯一 ID。信号接收方可以触发重播；组件用 run_id 防止旧调用继续结束新播放。若 `free_on_finish=true`，finished 回调中不要试图复用已经排队释放的节点。

## 参数表

| options 键 | 默认 / 允许值 | 实际影响 |
| --- | --- | --- |
| color | Color("52bdff")；传 Color | 两份绘制材质的 tint，含 alpha |
| intensity | 1.0，限制 0.5～1.5 | 核心亮度、粒子尺寸的平方根倍率，不改变数量 |
| radius | 120，本地像素，限制 60～180 | 旋入半径、扩散半径、绘制矩形和粒子包围盒 |
| speed | 1.0，限制 0.25～2.0 | 整条 CPU 视觉时钟的推进速度 |
| quality | 0=低、1=中、2=高，默认 2 | 数量 64/128/256，噪声次数 1/2/3，模拟频率 30/60/60 |
| seed | 整数 137 | 固定出生随机属性；restart 保留种子 |
| oversized_quad | false | 仅性能实验用；true 强制核心矩形 1024，不是质量档位 |

起终点必须有限，数值参数应传有限数字，类型错误、NaN/Infinity 不在公共接口承诺内。配置在播放开始时采样；直接修改原 options 字典不构成实时控制。需要换参数时重新 play，暂停用专用接口。

## 坐标与时间

`position=from`，GPU 局部目标为 `to-from`；核心 ColorRect 与粒子都在组件局部空间表达。若输入来自世界坐标，先由 effect 的父节点调用 `to_local(world_position)` 转换。

唯一视觉时间为 `effect_time`。CPU 每帧推进 `delta × speed`，两个 Shader 读取同一 uniform，没有全局 TIME。粒子解析轨迹会按 fixed_fps 更新，核心每个渲染帧更新；低频时可能存在一个模拟步长的视觉滞后，不能承诺完全逐帧重合。

GPU 槽位 lifetime=120 秒作为上限；可见生命周期由时钟 0～2.6 控制，并在结束后停模拟。最慢支持速度 0.25 时，活动播放约 10.4 秒，远小于上限。暂停时 GPU speed_scale=0。扩展长时间播放时必须重新核对上限，不等待粒子节点的 finished 信号来管理这个组件。

## 本课自定义通道

| 通道 | 定义 |
| --- | --- |
| CUSTOM.x | effect_time / 2.6，归一化视觉年龄；本例粒子同时出生 |
| CUSTOM.y | 出生确定的相位，范围 [0,1) |
| CUSTOM.z | 出生大小倍率，范围 [0.65,1.25) |
| CUSTOM.w | 0 软圆 / 1 小圆环，由 INDEX 奇偶决定 |

语义延续第八课，但 x 来自统一时钟而不是 DELTA 累加。不要与内置 ParticleProcessMaterial 的 y 年龄混接。本课 spark.gdshader 只需要读取 w，位置与透明度由过程 Shader 输出。

## 资源与清理

每个实例单独创建 motion、appearance、core_material；Shader、SVG 与噪声资源只读共享。停止后资源仍占内存，但 GPU 模拟停止。三个演示槽位不是无限自动扩容的对象池：第四次点击会替换最早轮到的槽位。

组件显式设为 PAUSABLE；演示 UI 使用 ALWAYS，允许全局暂停后继续点击恢复。全局暂停通知会同步 GPU speed_scale。没有使用 Tween 或 Timer 驱动旧回调，只有当前时钟与 run_id。

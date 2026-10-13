# 可复用组件：2D 奥术冲击

[完整课程](../../lessons/14_capstone/README.md) · [设计说明](../../lessons/14_capstone/DESIGN.md) · [调用接口](../../lessons/14_capstone/API.md)

`spell.tscn` 是组件，加载后默认隐藏；演示请运行 `tutorial/lessons/14_capstone/capstone_lab.tscn`。

```gdscript
var effect = preload("res://tutorial/final_project/arcane_spell/spell.tscn").instantiate()
add_child(effect)
effect.play(Vector2(200, 350), Vector2(650, 350), {
	"color": Color("52bdff"),
	"intensity": 1.0,
	"radius": 120.0,
	"speed": 1.0,
	"quality": 2
})
```

目录内包含所有运行资源，无其他课程资源依赖。迁移到其他项目时保持 `res://tutorial/final_project/arcane_spell/` 路径，或同步修改脚本中的 preload 路径；等待 Godot 导入 SVG。默认保留实例供重播，调用 `cancel()` 取消，或设置 `free_on_finish=true` 在自然结束后释放。

本例用于视觉表现，预设时刻的 `impacted` 信号不是物理碰撞或伤害判定。

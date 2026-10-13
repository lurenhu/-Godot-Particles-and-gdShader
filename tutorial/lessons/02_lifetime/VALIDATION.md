# 第二课验证记录

验证环境：Godot 4.7.1 stable，Windows，Forward+ / D3D12，NVIDIA GeForce RTX 5060 Ti。

- 场景、GDScript 和三份 `.tres` 在引擎中加载成功。
- 运行时参数检查覆盖：材质隔离、选中效果的寿命与爆发程度、大小曲线开关、透明度开关及源渐变保护、固定速度中点、预热、坐标模式、发射器移动、换种子、基线恢复。
- GPU 实际运行未报告 Shader 编译错误；截图检查确认三列布局、中文控件和三种效果正常可见。
- 截图为 `preview.png`；为同时展示三个效果，先运行连续效果 3 秒，再单独重触发爆点并等待约 0.22 秒。
- Mermaid 已核对代码块结构与图文逻辑，未使用独立 Mermaid 渲染器验证。

日志：`validation-runtime.log`、`validation-render.log`。自动检查验证参数和资源状态，实际画面检查覆盖基线外观；它们不替代用户完成每个时间对照实验，不代表跨设备视觉一致。

开发时可运行场景并传入用户参数 `--lesson-smoke-test` 执行检查，或传入 `--lesson-capture` 生成预览并自动退出。普通 F6 不进入这两个分支。

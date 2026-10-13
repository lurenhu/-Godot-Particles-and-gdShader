# 第五课验证记录

环境：Godot 4.7.1 stable，Windows，Forward+ / D3D12，NVIDIA GeForce RTX 5060 Ti。

- 场景、过程材质、Shader include 与两个混合入口成功加载。
- 运行时检查覆盖模拟材质共享、绘制材质隔离、寿命随机及动画偏移前提、冻结时钟与 speed_scale、溶解起点传参、切换 Shader 后的参数恢复、背景及基线恢复。
- GPU 实际渲染无 Shader 编译错误。
- 已查看基线、年龄灰度、相位灰度、浅背景加法与普通混合截图。年龄图确认左侧同值、右侧按高度不同；相位图确认对应粒子拥有不同相位。
- 已修复浅背景下标签与复选框文字对比不足，并复核最终浅背景截图。
- 通道语义核对 Godot 4.7 官方 CanvasItem 文档与 ParticleProcessMaterial 生成代码；本课明确限制寿命随机为 0、动画速度为 0、无动画曲线和序列帧。
- 相位跨帧稳定性依据上述配置和引擎生成公式；未进行 GPU 逐粒子跨帧追踪测试。
- Mermaid 已检查代码块与图文逻辑，未使用独立 Mermaid 渲染器验证。

日志：`validation-runtime.log`、`validation-render.log`。

截图：`preview.png`、`age_debug.png`、`phase_debug.png`、`add_dark.png`、`add_light.png`、`mix_light.png`，在运行约 5.4 秒后冻结同一状态进行对照。

开发检查用户参数：`--lesson-smoke-test` 或 `--lesson-capture`。普通 F6 不执行检查入口。截图和参数检查不替代学习者执行完整重播、闪烁和混合实验，也不保证跨硬件逐像素一致。

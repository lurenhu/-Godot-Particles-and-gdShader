# 第四课验证记录

环境：Godot 4.7.1 stable，Windows，Forward+ / D3D12，NVIDIA GeForce RTX 5060 Ti。

- 场景、脚本、噪声资源与 Shader 成功加载。
- 运行时检查覆盖噪声数据就绪、两侧材质隔离与效果类型、六个滑条传参、采样模式、暂停时间和恢复基线。
- GPU 渲染无 Shader 编译错误；已查看基线、原噪声、扭曲 UV、组合噪声及两个溶解端点的截图。
- GPU 端点检查：最终遮罩视图中，进度 0 的圆心为白色；进度 1 的左侧画布内部所有采样像素为黑色。进度 0 的完整轮廓另通过截图检查。
- 截图使用冻结的自定义时间 1 秒。像素检查按捕获图像尺寸换算逻辑画布坐标，并排除画布边界一圈像素。
- Mermaid 已检查代码块与图文逻辑，未使用独立 Mermaid 渲染器验证。

日志：`validation-runtime.log`、`validation-render.log`。

截图：`preview.png`、`debug_1.png`～`debug_4.png`、`endpoint_full.png`、`endpoint_empty.png`。

开发入口：运行场景并传入用户参数 `--lesson-smoke-test` 检查参数，或 `--lesson-capture` 生成截图并检查端点。普通 F6 不执行这些入口。

验证覆盖当前环境、基线视觉和指定参数行为，不代表所有硬件、采样配置与缩放下效果完全一致。动画方向按公式解释，仍应亲自执行讲义中的单层滚动对照。

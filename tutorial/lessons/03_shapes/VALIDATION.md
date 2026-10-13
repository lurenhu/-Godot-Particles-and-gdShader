# 第三课验证记录

环境：Godot 4.7.1 stable，Windows，Forward+ / D3D12，NVIDIA GeForce RTX 5060 Ti。

- 引擎成功加载场景、脚本与 Shader。
- 运行时检查覆盖两侧材质隔离、2:1 画布比例、画布尺寸传参、半径同步、宽高比开关、形状/调试模式切换、抗锯齿开关与基线恢复。
- GPU 渲染未报告 Shader 编译错误。
- 已查看基线、关闭宽高比校正、扇形、胶囊、并集、差集和有符号场的实际运行截图，确认对应形状与布局。
- Mermaid 已检查图文逻辑和代码块组织，未使用独立 Mermaid 渲染器验证。

日志：`validation-runtime.log`、`validation-render.log`。

截图：`preview.png`、`aspect_error.png`、`shape_1.png`～`shape_4.png`、`field.png`。

普通 F6 不执行测试入口。开发检查可传入用户参数 `--lesson-smoke-test`；截图检查使用 `--lesson-capture`，依次保存上述画面后退出。验证不代表所有硬件与缩放条件下的逐像素一致，也不替代讲义中的交互练习。

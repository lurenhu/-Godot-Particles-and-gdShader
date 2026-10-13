# 第七课验证记录

环境：Godot 4.7.1 stable，Windows，Forward+ / D3D12，NVIDIA GeForce RTX 5060 Ti。GPU 截图运行区域 1200 × 800。

## 已完成

- 场景、三份粒子 Shader 入口及公共 include 成功加载，GPU 渲染未报告 Shader 编译错误。
- 运行时检查：过程材质独立、绘制材质共享、数量及局部坐标前提、冻结、参数传递和恢复基线。
- 使用 `restart(true)`、speed_scale=0 和 `request_particles_process(0.7)` 推进到固定模拟时刻后截图。
- 自动位移与手动位移的 `capture_rect()` 相同：位置约 (-89.59262, -87.54999)，尺寸约 (179.1852, 68.29016)。断言比较位置与尺寸差小于 0.1。该结果验证包围盒，不等于逐粒子数据完全一致的证明。
- 已查看基线截图，A/B 对齐，C 相对原点位移更大；查看每步重设速度、年龄灰度和主动结束截图。
- 关闭淡出、end_age=0.5，推进到 1.2 秒后，画面与隐藏三组粒子的截图逐字节一致；结束由活动状态控制，不依赖 alpha 淡出。
- 对照顺序核对 Godot 4.7 Forward+ 使用的粒子计算实现；本课手动版匹配先位移后更新速度，并跳过出生首步位移。
- 转换练习提供内置材质原件及官方操作说明，学习者在个人副本中完成转换与另存。

## 限制

- 未进行逐粒子 GPU 状态回读，未验证所有固定频率与参数组合的数值误差。
- 未测试非本地坐标、外部手动发射、子发射器、碰撞、其他渲染后端和跨硬件一致性。
- `builtin_reference.tres` 尚未在本次验证中经编辑器 UI 转换；不把它或手写 Shader 冒充为引擎转换结果。
- Mermaid 已核对代码块与图文，未使用独立渲染器验证。
- 学习进度保持未勾选，转换阅读和独立变体由学习者完成。

日志：`validation-runtime.log`、`validation-render.log`。

截图：`preview.png`、`reset_velocity.png`、`zero_gravity.png`、`before_death.png`、`early_death.png`、`empty.png`、`age_debug.png`。

开发入口：`--lesson-smoke-test` 检查脚本状态；`--lesson-capture` 执行固定时间 GPU 截图与对照检查。普通 F6 仅运行交互实验。

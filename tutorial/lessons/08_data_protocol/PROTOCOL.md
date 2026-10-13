# Lesson08 粒子数据协议 v1

适用组合：`random_spawn.gdshader` → GPUParticles2D → `read_data.gdshader`。

本文件是读写双方的约定；`protocol.gdshaderinc` 保存共用的通道编号。v1 是文档版本名，没有占用额外 GPU 通道，也没有运行时自动版本校验。

| 通道 | 常量 | 内容和范围 | 写入者与时机 | 读取者 |
| --- | --- | --- | --- | --- |
| x | DATA_AGE | 归一化年龄，活动期通常 0～1 | start 归零；process 加 DELTA/LIFETIME | 模拟结束逻辑、绘制闪烁和调试 |
| y | DATA_PHASE | 初始相位 [0,1)，单位为周期 | start 写入后保持 | 绘制闪烁、相位调试 |
| z | DATA_SIZE | 初始大小倍率 [0.65,1.25) | start 写入后保持 | 绘制 vertex 缩放、大小调试 |
| w | DATA_KIND | 类型，浮点数精确保存 0 或 1 | start 写入后保持 | 0=圆点，1=圆环；类型调试 |

边界与不变量：

- start 每次完整赋值 CUSTOM 四个分量，并重设 TRANSFORM、VELOCITY、COLOR 和 ACTIVE。
- 正确路径中，process 仅改变 x；y/z/w 在同一生命期保持不变。
- 年龄到达 1 时结束当前粒子；节点保持循环发射，下一次出生再次执行 start。
- 本课使用统一寿命 3 秒，没有单粒子寿命随机；年龄增加量来自同一节点 LIFETIME。
- 调试视图用固定尺寸圆点、忽略 COLOR 淡出，避免把多个变量混合观察；成品保留输入颜色和淡出。
- 随机 identity 使用 NUMBER 或 INDEX，种子来自 RANDOM_SEED；相位、大小、类型分别使用 11、37、79 作为字段区分常数。
- 节点 amount 固定为 12；位置用 INDEX 排成四列三行。局部坐标、无移动、无碰撞，便于追踪同一槽位。
- 本课完全控制模拟和绘制，不使用内置 ParticleProcessMaterial 通道含义、CanvasItemMaterial 粒子序列帧、拖尾或 3D billboard 通道配置。

故意违反协议的两个开关：

1. `resample_each_step`：process 重新写 y/z/w，用于演示“出生属性”被持续改写。
2. `wrong_decode`：仅绘制端交换 y/z，用于演示读写语义不一致。GPU 原始 CUSTOM 没有被这个开关修改。

这两个开关默认只有右侧可用。修复第一种错误后应重播恢复出生数据；修复第二种错误无需重播即可恢复正确读取。

协议修改流程：先改本文与通道常量，再改写入和读取代码，最后用各通道视图检查出生、生命中段、自然重生与显式重播。不能只把一个读写端替换为其他课程的 Shader。

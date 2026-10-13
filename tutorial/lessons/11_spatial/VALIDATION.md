# 第十一课验证记录

日期：2026-09-23。

环境：Godot 4.7.1 stable（a13da4feb），Forward+，Windows D3D12，NVIDIA GeForce RTX 5060 Ti，1200 × 800。保持项目主场景及全局渲染设置不变。

运行 `spatial_lab.tscn` 并传入 `--lesson-test`。实际 GPU 执行完成，日志 [validation-render.log](validation-render.log) 包含 `LESSON_11_TEST_OK`，没有脚本或 Shader 编译错误。

自动检查：

- 两组网格和绘制材质独立，A billboard=false、B billboard=true。
- 冻结并额外模拟 3 秒后，两个系统 capture_aabb 相同且坐标、尺寸均有限；本次约为位置 (-1.285, 0.031, -1.242)、尺寸 (2.572, 2.499, 2.559)。
- B 原点平移与局部轨迹偏移抵消，粒子世界中心仍对应右平台；正确 AABB 包含偏移后的局部中心，错误 AABB 不包含。
- 按索引排序控件回调确实设置节点枚举。
- 冻结与恢复分别设置两组 speed_scale 为 0 和 1；恢复基线后包围盒、排序、强度及错误开关正确。

实际截图与人工观察：

- [preview.png](preview.png)：正面对照，灰柱及两组魔法尘。
- [side_cards.png](side_cards.png)：90° 侧面，A 接近细线，B 保持方卡。
- [emission_only.png](emission_only.png)、[glow.png](glow.png)：相同 Emission=6，比较 Glow 关闭和开启。
- [light_background.png](light_background.png)：亮背景，Glow 关闭。
- [bounds_correct.png](bounds_correct.png)、[bounds_wrong.png](bounds_wrong.png)：原点在镜头外，正确范围仍可见，错误范围导致 B 消失。
- [color_wrong.png](color_wrong.png)：丢弃粒子颜色后的白色与淡出丢失。
- [no_occluder.png](no_occluder.png)：隐藏灰柱后可以看到原本被挡住的粒子。
- [index_order.png](index_order.png)：方卡与按索引排序的诊断画面。

截图通过 restart、speed_scale=0、request_particles_process(3.0) 建立可重复的模拟时刻；随后改变绘制参数或相机。固定种子不保证跨硬件逐像素一致。当前 AABB 检查不是整个生命周期或全部参数的数学证明。

未验证：其他渲染器、导出包、所有窗口比例、VR、多相机、镜像/非均匀缩放/剪切、全局暂停、全生命周期逐粒子状态及性能；透明排序没有做逐像素正确性证明。没有碰撞、软粒子深度淡化或粒子投射阴影。Mermaid 已检查代码块、链接及图文关系，未逐图独立渲染。

`spatial_lab.gd` 使用第一课同样的每级一个 Tab 缩进；学习进度未自动勾选。

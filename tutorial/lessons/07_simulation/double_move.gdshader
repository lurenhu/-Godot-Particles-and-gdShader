shader_type particles;
// 故意遗漏 disable_velocity：引擎与 process 各移动一次。
#define MANUAL_MOVE
#include "simulation.gdshaderinc"

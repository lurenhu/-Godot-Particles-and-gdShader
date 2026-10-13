// Lesson08 协议 v1：仅用于配套的自定义模拟与绘制组合。
const int DATA_AGE = 0;   // x：归一化年龄，每步累加，出生归零。
const int DATA_PHASE = 1; // y：[0,1) 周期相位，出生确定。
const int DATA_SIZE = 2;  // z：[0.65,1.25) 初始大小倍率，出生确定。
const int DATA_KIND = 3;  // w：0=圆点，1=圆环，出生确定。

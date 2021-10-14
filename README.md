Magically Improved Pipeline Stages
===

Our awesome `MIPS` CPU written in `SystemVerilog` for Loongson Cup 2021

```
.
├── resources                <-- 资源
│   ├── 2021                 <-- 2021 资源包
│   ├── ping-pong-mips32     <-- 决赛项目 ping pong
│   └── system_top           <-- 决赛项目 ping pong 用的外围顶层
├── src                      <-- CPU设计代码
│   ├── AXI                  <-- AXI总线交互
│   ├── Cache                <-- Cache
│   ├── Core                 <-- CPU核心
│   ├── CP0                  <-- CP0 协处理器
│   ├── Gadgets              <-- 小部件
│   ├── include              <-- 头文件
│   ├── IP                   <-- 用到的IP
│   └── MMU                  <-- 地址转换单元
└── tools                    <-- 控制信号生成器
```

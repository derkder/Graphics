## GPGPU（General Purpose GPU）
利用处理图形任务的GPU来计算原本由CPU处理的通用计算任务
这样， 对于一些非图形应用也可以受益于GPU并行架构所提供的大量计算能力

## Compute Shader
要实现GPGPU编程，我们就需要一个方法来访问GPU从而实现数据并行算法，这里就需要使用到Compute Shader（后面简称为CS）。
CS允许我们访问GPU来实现数据并行算法，而不需要绘制任何东西。

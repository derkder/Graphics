## 定义:一组同时执行相同指令的线程

## 具体：
##### Warp是NVIDIA GPU架构中的术语，用于描述一组同时执行相同指令的线程。具体来说：
Warp：在NVIDIA的CUDA架构中，一个warp通常由32个线程组成。这些线程在同一个时钟周期内执行相同的指令，但可以操作不同的数据。
SIMT（Single Instruction, Multiple Threads）：Warp的执行模型是SIMT，即单指令多线程。所有线程在同一个warp中执行相同的指令，但可以有不同的控制流和数据。

##### Wavefront是AMD GPU架构中的术语，类似于NVIDIA的warp。具体来说：
Wavefront：在AMD的GPU架构中，一个wavefront通常由64个线程组成。这些线程也在同一个时钟周期内执行相同的指令。
SIMD（Single Instruction, Multiple Data）：Wavefront的执行模型是SIMD，即单指令多数据。所有线程在同一个wavefront中执行相同的指令，但可以操作不同的数据。


##### 背景
shader中要少用if else否则一组warp都在等一个线程

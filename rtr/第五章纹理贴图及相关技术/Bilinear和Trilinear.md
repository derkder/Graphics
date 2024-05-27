### Point（no filter）
默认过滤模式，其原理是取一个与pixel最近的texel信息，直接使用该texel数据。

### Bilinear（双线性过滤）
原理是先取得1个纹理Level，再以模型的pixel在纹理上相应位置的texel（或最近的texel）为准点，取得周围4个texel点位信息，再取得平均值，以该平均值的数据进行绘制。（基于性能和效果的考虑，是最为适用的一种过滤模式）


### Trilinear（三线性过滤）
原理与Bilinear一致，但是采样范围变为了在相近的两个Level各取4个texel点为信息，以8个数据进行平均值计算。



#### Bilinear和Trilinear 都需要依赖纹理的不同Level实现，所以需要开启Mipmap。

# Cluster 与 Z-Binning：视锥空间的光源剔除

> 相关笔记：[Froxel](<./Froxel[视锥体素·体积光的加速结构].md>) · [体积光](<./体积光[从ray-marching到froxel].md>)
>
> 本文中 URP 的实现细节均摘自 `com.unity.render-pipelines.universal@17.0.4` 公开源码。

**可交互 demo：[assets/volumetric-light.html](../assets/volumetric-light.html)**（浏览器打开，拖滑块看相位函数 / 深度分布 / 色带与抖动）

---

## 一、要解决的问题

一个场景里有 200 盏点光和聚光。屏幕上有 200 万个像素。

最朴素的做法是每个像素遍历所有灯：**4 亿次光照计算**，显然不可行。

但实际上绝大多数灯离绝大多数像素都很远，根本没有影响。所以真正的问题是：

> **怎么让每个着色点快速知道"哪几盏灯真的影响我"？**

这就是光源剔除（light culling）。所有后续的方案都是在回答这一个问题。

---

## 二、前史：Tiled Shading

2010~2011 年前后出现的方案（Frostbite 在 Battlefield 3 上的实践是代表）：

把屏幕切成 2D 格子（比如 16×16 像素一格），对每个格子算出"哪些灯的屏幕投影覆盖了它"，存一份光源列表。着色时，像素查自己所在格子的列表就行。

```
屏幕
┌────┬────┬────┬────┐
│ T0 │ T1 │ T2 │ T3 │   每个 tile 存一份光源列表
├────┼────┼────┼────┤   T5 = [3, 17, 42]
│ T4 │ T5 │ T6 │ T7 │
└────┴────┴────┴────┘
```

**它的致命缺陷是深度方向完全没有分辨力。**

一个 tile 在世界空间里是一根从近平面伸到远平面的长条。假设这个 tile 里近处有一面墙、远处有一座山：墙附近的灯和山附近的灯会被塞进**同一份列表**。渲染墙上的像素时，仍然要遍历那些只影响远处山的灯。

走廊、峡谷这类深度跨度大的场景，浪费尤其严重。

---

## 三、Clustered Shading：把 tile 拉成 3D

2012 年 Olsson 等人的 *Clustered Deferred and Forward Shading* 给出的答案很直接：

**既然深度方向缺分辨力，那就把深度也切开。**

2D 的 tile 变成 3D 的 cluster —— 一个跟着摄像机视锥走的三维网格：

```
                          ┌──┬──┬──┬──┐
                  ┌───┬───┼──┼──┼──┼──┤
          ┌───┬───┤   │   │  │  │  │  │
  相机   ●┼───┼───┼───┼───┼──┼──┼──┼──┤
          └───┴───┤   │   │  │  │  │  │
                  └───┴───┼──┼──┼──┼──┤
                          └──┴──┴──┴──┘
           近                          远
```

每个 cluster 单独存一份光源列表。墙所在的 cluster 和山所在的 cluster 是两个不同的格子，各自只装自己的灯。

**这个"跟着视锥切的三维网格"，就是后面 froxel 会复用的同一套空间结构。**

---

## 四、为什么深度要用对数分布

这是 clustered shading 里最值得理解的一个设计，而且能推出来。

### 一个几何事实

透视投影下，一个**固定像素大小**的 tile，它在世界空间覆盖的宽度随深度**线性增长**：

```
垂直 FOV = θ，屏幕高 H 像素，tile 边长 T 像素

深度 z 处，屏幕高度覆盖的世界高度 = 2·z·tan(θ/2)
一个 tile 覆盖的世界宽度  w(z) = T · 2·z·tan(θ/2) / H  ∝  z
```

深度翻倍，tile 的世界宽度就翻倍。

### 推导

我们希望一个 3D 格子在世界空间里**大致是立方体** —— 长宽高比例相当。

横向尺寸是 `w(z) ∝ z`，那深度厚度就该是：

```
Δz ∝ z
```

这是个微分方程，设 bin 编号为 k：

```
dz/dk = c·z
   ⇓
z(k) = near · e^(c·k)
   ⇓
k = (1/c)·ln(z/near)      ⟹   k ∝ log(z)
```

**深度方向按对数切分。**

### 为什么要立方体

因为光源的包围体是**球** —— 各向同性。用一个细长的针去和球做相交测试，会产生大量假阳性。

具体算一下（1080p、8 像素 tile、60° FOV、near=0.3、far=1000、4096 个 bin）：

**均匀分布**（每个 bin 固定厚 0.244 米）：

| 深度 | tile 世界宽度 | bin 厚度 | 形状 |
|---|---|---|---|
| 1 米 | 8.6 毫米 | 244 毫米 | 细针，长了 **28 倍** |
| 500 米 | 4.28 米 | 0.24 米 | 扁饼，扁了 **17 倍** |

**对数分布**（`Δz ≈ z × 0.00198`）：

| 深度 | tile 世界宽度 | bin 厚度 | 比例 |
|---|---|---|---|
| 1 米 | 8.6 毫米 | 2.0 毫米 | 4.3 |
| 500 米 | 4.28 米 | 0.99 米 | **4.3** |

**长宽比在整个深度范围内恒定。** 这才是对数分布真正的性质。

### 直观版：不用对数会浪费成什么样

同样配置，看**前 10 米**（绝大多数玩法内容所在）能分到多少 bin：

| 分布 | 前 10 米占的 bin |
|---|---|
| 均匀 | `(10−0.3)/(1000−0.3)` ≈ **1%** |
| 对数 | `log₂(10/0.3) / log₂(1000/0.3)` ≈ **43%** |

均匀分布把 **99% 的 bin 扔给了 10 米开外**，而那里通常空空如也。

---

## 五、Z-Binning：把 3D 网格因式分解

经典 cluster 有个现实问题：**存储量是 `O(X·Y·Z)`**。

1080p、8 像素 tile、24 个深度切片：

```
240 × 135 × 24 = 777,600 个格子
```

每个格子还要存一份变长的光源索引列表，加起来好几 MB。这个体量塞不进 constant buffer，只能用 structured buffer，而 structured buffer 在移动 GPU 上访问更慢、兼容性也更差。

**Z-Binning 的思路：不建 3D 网格，只存两张低维的表，查询时现场合成。**

```
Tile[x][y]  ── 2D，每个屏幕格子一个位掩码
ZBin[z]     ── 1D，每个深度段一个位掩码

Cluster[x][y][z]  ≈  Tile[x][y]  AND  ZBin[z]
```

举例（假设场景有 32 盏灯，编号 0~31）：

```
tile (12, 7) 的掩码：  0000 ... 0010 1101
                                 ↑  ↑ ↑↑
                    灯 0、2、3、5 覆盖了这个屏幕格子

zBin 34 的掩码：       0000 ... 0011 0100
                                 ↑↑ ↑
                    灯 2、4、5 的深度范围盖到这一段

           AND  →     0000 ... 0010 0100
                                 ↑  ↑
                    只有灯 2 和灯 5 真正需要算
```

存储量从 `O(X·Y·Z)` 降到 `O(X·Y + Z)`：

| | 格子数 | 存储 |
|---|---|---|
| 3D cluster（240×135×24） | 777,600 | ~3.1 MB |
| Z-Binning（240×135 + ~4000） | 36,400 | **~146 KB** |

**146 KB 意味着它能塞进 Constant Buffer。** 这才是这套设计真正的目的。

---

## 六、代价：假阳性，以及为什么可以接受

`AND` 是个**保守近似**。

一盏灯在某个深度覆盖了 tile T，又在某个屏幕位置覆盖了 bin Z，但它未必真的和三维单元 (T, Z) 相交。按位与判不出这种差别，会把它算进来。

### 数学根源

`Tile[x][y] AND ZBin[z]` 在数学上是**把三维布尔张量近似成两个低维张量的外积**。外积只能表达"可分离"的集合，不可分离的部分就是误差。

### 为什么误差可控

因为**光源的包围体本来就近似可分离**。

一盏点光是个球，在 (屏幕x, 屏幕y, 深度) 坐标系里：
- 屏幕上投影成一个圆盘 → `Tile[x][y]`
- 深度上占据一个区间 → `ZBin[z]`

两者求交，得到的其实是这个球的**包围盒**。而球在包围盒里的体积占比是：

```
(4/3)πr³ / (2r)³ = π/6 ≈ 52%
```

**假阳性大约在 2 倍以内，是有界的。**

用这点冗余换掉一个数量级的存储，非常划算。前提是光源形状不能太各向异性 —— 实时渲染里基本都是球和锥，所以成立。

---

## 七、URP 的实现

URP 的 Forward+ 用的正是 Z-Binning。以下代码摘自公开的 URP 17 源码。

### 数据布局

每个 z-bin 占 `2 + wordsPerTile` 个 `uint`：

```
┌──────────┬──────────┬────────┬────────┬─────┬────────┐
│ header0  │ header1  │ word 0 │ word 1 │ ... │ word N │
│ 灯的范围  │ 探针范围  │ ←──────── 位掩码 ──────────→   │
└──────────┴──────────┴────────┴────────┴─────┴────────┘
```

`header` 把两个 16 位整数打包进一个 uint，存的是**这个 bin 里涉及的实体编号的 min / max**：

```csharp
// Runtime/Tiling/ZBinningJob.cs
static uint EncodeHeader(uint min, uint max)
{
    return (min & 0xFFFF) | ((max & 0xFFFF) << 16);
}
```

初始值是 `EncodeHeader(ushort.MaxValue, ushort.MinValue)` —— `min > max` 天然表示空集合，不用额外标志位。

### CPU 侧：Burst Job，帧最开头

注意这是**纯 CPU 计算**，不是 compute shader。因为处理对象是"几百盏灯"而不是"几百万像素"，CPU 多线程一下就算完了。

```csharp
// Runtime/ForwardLights.cs
var lightMinMaxZHandle = lightMinMaxZJob.ScheduleParallel(...);  // ① 每盏灯的深度范围
var zBinningHandle     = zBinningJob.ScheduleParallel(...);      // ② 按深度分箱
var tileRangeHandle    = tilingJob.ScheduleParallel(...);        // ③ 每盏灯覆盖哪些 tile
var tilingHandle       = expansionJob.ScheduleParallel(...);     // ④ 展开成位掩码
JobHandle.ScheduleBatchedJobs();
```

分箱的核心循环：

```csharp
// Runtime/Tiling/ZBinningJob.cs
var minBin = (int)(log2(minMax.x) * zBinScale + zBinOffset);
var maxBin = (int)(log2(minMax.y) * zBinScale + zBinOffset);

var wordIndex = index / 32;
var bitMask   = 1u << (index % 32);

for (var binIndex = minBin; binIndex <= maxBin; binIndex++)
{
    // ① 把自己的编号并进 header 的 min/max 范围
    minIndex = math.min(minIndex, (uint)index);
    maxIndex = math.max(maxIndex, (uint)index);
    bins[baseIndex + headerIndex] = EncodeHeader(minIndex, maxIndex);

    // ② 在位掩码里点亮自己那一位
    bins[baseIndex + headerLength + wordIndex] |= bitMask;
}
```

对数分布在 scale/offset 里：

```csharp
m_ZBinScale  = binCount / (log2(far) - log2(near));
m_ZBinOffset = -log2(near) * m_ZBinScale;

// 于是 binIndex = log2(z)·scale + offset = scale · log2(z / near)
// 代入 z = far 得 binIndex = binCount，两端刚好对齐
```

### tile 尺寸是自适应的

从 8 像素起步，塞不下就翻倍，直到总字数满足 constant buffer 的预算：

```csharp
m_ActualTileWidth = 8 >> 1;
do {
    m_ActualTileWidth <<= 1;               // 8 → 16 → 32 …
    m_TileResolution = (screenResolution + m_ActualTileWidth - 1) / m_ActualTileWidth;
}
while ((m_TileResolution.x * m_TileResolution.y * m_WordsPerTile * viewCount) > maxTileWords);
```

结果上传成两个 **Constant Buffer**：

```csharp
cmd.SetGlobalConstantBuffer(m_ZBinsBuffer,    "urp_ZBinBuffer", ...);
cmd.SetGlobalConstantBuffer(m_TileMasksBuffer, "urp_TileBuffer", ...);
```

### GPU 侧：着色时查询

```hlsl
// ShaderLibrary/Clustering.hlsl
ClusterIterator ClusterInit(float2 normalizedScreenSpaceUV, float3 positionWS, int headerIndex)
{
    // 屏幕 UV → tile 索引
    uint2 tileId = uint2(normalizedScreenSpaceUV * URP_FP_TILE_SCALE);
    state.tileOffset = (tileId.y * URP_FP_TILE_COUNT_X + tileId.x) * URP_FP_WORDS_PER_TILE;

    // 世界坐标 → view 空间深度 → 对数 → zBin 索引
    float viewZ = dot(GetViewForwardDir(), positionWS - GetCameraPositionWS());
    uint zBinBaseIndex = (uint)((IsPerspectiveProjection() ? log2(viewZ) : viewZ)
                                * URP_FP_ZBIN_SCALE + URP_FP_ZBIN_OFFSET);
    ...
    // 两个掩码求交，再用 header 砍掉首尾多余的位
    state.tileMask =
        Select4(asuint(urp_Tiles[tileIndex / 4]), tileIndex % 4) &
        Select4(asuint(urp_ZBins[zBinIndex / 4]), zBinIndex % 4) &
        (0xFFFFFFFFu << (header & 0x1F)) &
        (0xFFFFFFFFu >> (31 - (header >> 16)));
}
```

迭代：每次取掩码里**最低位的那个 1**，处理完清掉：

```hlsl
bool hasNext  = it.tileMask != 0;
uint bitIndex = FIRST_BIT_LOW(it.tileMask);
it.tileMask  ^= (1 << bitIndex);
```

**遍历一盏灯的成本 ≈ 一条找最低位指令 + 一次异或。**

### header 的两个作用

**一、跳过整个 32 位 word。** 场景有 200 盏灯（7 个 word），但某个 bin 的 header 说"这里只涉及编号 96~120"，那 shader 只需要读第 3 个 word，其余六个碰都不用碰：

```hlsl
uint maxIndex = it.entityIndexNextMax >> 16;
[loop] while (it.tileMask == 0 && (it.entityIndexNextMax & 0xFFFF) <= maxIndex)
{
    uint wordIndex = ((it.entityIndexNextMax & 0xFFFF) >> 5);   // 除以 32
    ...
}
```

**二、砍掉首尾多余的位**（上面 `ClusterInit` 里那两个移位掩码）。

这背后的假设是：**光源按深度排序后，落在同一个 bin 里的灯，编号往往接近连续**。所以两个数字就能相当准确地圈出候选集合 —— 这正是 Z-Binning 最初的核心思想：**用两个数字近似表达一个集合**。

URP 在此基础上又加了位掩码做精确化，等于「粗范围跳 word + 位掩码精确判定」的组合拳。

### 对使用者透明

```hlsl
// ShaderLibrary/RealtimeLights.hlsl
#define LIGHT_LOOP_BEGIN(lightCount) { \
    uint lightIndex; \
    ClusterIterator _urp_internal_clusterIterator = \
        ClusterInit(inputData.normalizedScreenSpaceUV, inputData.positionWS, 0); \
    [loop] while (ClusterNext(_urp_internal_clusterIterator, lightIndex)) { \
        lightIndex += URP_FP_DIRECTIONAL_LIGHTS_COUNT; \
        ...
#define LIGHT_LOOP_END } }
```

调用方只要填好 `inputData.positionWS` 和 `inputData.normalizedScreenSpaceUV`，就能拿到"影响我的灯"。**底下是 3D 数组还是两张表求交，完全不用关心。**

这一点很重要 —— 体积光的 froxel 散射 shader 正是靠这个宏来剔除光源的，详见 [Froxel](<./Froxel[视锥体素·体积光的加速结构].md>)。

---

## 八、家谱与命名

```
Tiled Shading / Tiled Deferred  (2010~2011)
        屏幕切 2D 格子，每格一份光源列表
                    │
                    │  缺陷：深度方向零分辨力
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
  Clustered Shading         Z-Binning
   (2012, Olsson 等)         (2017 前后)
        │                       │
  真建 3D 网格              2D tile + 1D 深度表
  M[x][y][z]               查询时求交
```

**两者是兄弟不是父子** —— 对同一个问题（如何给 2D tile 加上深度感知）的两种不同答案。

但在 Unity 的语境里，Z-Binning 被当作 cluster 的一种**实现方式**：

| 东西 | URP 里的名字 |
|---|---|
| 文件 | `Clustering.hlsl` |
| 迭代器 | `ClusterIterator` |
| 初始化 | `ClusterInit()` |
| 迭代 | `ClusterNext()` |

所以说"Z-Binning 是 URP 实现 clustered lighting 的方式"是准确的。

另外，**对数深度分布是从 clustered shading 继承来的** —— Z-Binning 换掉了存储结构，但"深度该怎么切"这个问题的答案没变。

值得单独记住的是：Z-Binning 里"排序后用 min/max 索引范围表达集合"这个技巧本身是独立的，可以用在任何"实体沿某个轴有序分布"的剔除问题上，不一定要配 tile。

---

## 九、一句话总结

**Cluster 是一个"谁影响这里"的加速结构，装的是索引不是结果，读法是点查询。**

因为它只影响性能不影响正确性，所以可以大胆用有假阳性的近似（Z-Binning）换存储；也因为光源包围球各向同性，所以格子要尽量是立方体（对数深度分布）。

这两条约束推出了它几乎所有的设计。而当同样的视锥网格被拿去装"结果"而不是"索引"时，约束就完全变了 —— 那就是 [Froxel](<./Froxel[视锥体素·体积光的加速结构].md>)。

[https://zhuanlan.zhihu.com/p/369761748]

## PCF阴影简介
首先，使用shadowmap来生成实时阴影的话，阴影边缘会存在锯齿问题。因为拿场景中像素的深度值去shadowmap中对比时，结果要么在阴影中，要么不在阴影中，
这是一个非1即0的二值函数。      
为了解决这个问题，于是人们提出了percent closer filter。这本质上是一个滤波器的思想，即增加采样点，与depth做比较，得到若干的1或0，
然后进行加权平均。这样的话，最终的结果值将是一个0~1范围的值，于是便形成了阴影边缘的半透明过渡。


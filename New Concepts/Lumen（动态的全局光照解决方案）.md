好像是在photon maping的基础上（不从摄像机出发，从光源出发）
Lumen的想法是在屏幕空间放一大堆的 Probes，屏幕空间 的特点是紧贴那些要被渲染的物体表面，通过 Probe获取光照。比如每16 个 pixel 我放置一个Probe，每个像素去 Shading 的时候，它的高频信息可以通过表面法线产生，最后得到右边非常逼真的效果。

作者：GAMES104官方账号
链接：https://zhuanlan.zhihu.com/p/643337359
来源：知乎
著作权归作者所有。商业转载请联系作者获得授权，非商业转载请注明出处。

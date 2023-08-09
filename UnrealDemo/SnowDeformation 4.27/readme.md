### 来源
[https://www.kodeco.com/5760-creating-snow-trails-in-unreal-engine-4]


## 知识点【Scene Capture Component发射(这是一个相机) + RenderTarget接受 + CustomDepth Pass隔断】
1、cameras从底向顶照射，而不是从顶向底照射解决大肚子的问题
2、带有 Scene Capture Component 的 BP Capture预制体就是一个底向顶观察， 它带有后期处理材质which对所有渲染到**自定义深度开启Render CustomDepth Pass**（之前那个是用粒子层区分的）的对象进行遮罩

## 附：Scene Capture Component 2d + RenderTarget做小地图
https://www.cnblogs.com/timy/p/10018848.html
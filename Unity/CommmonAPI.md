### m_A.name = Shader.PropertyToID(name + "A"); -
参数name是属性名，返回值是标识该属性的唯一的int值。
为了提高效率，Unity为着色器属性的每个名称(例如，_MainTex或_Color)都分配一个唯一的整数，在整个游戏中保持不变。使用属性标识符比向所有物质属性函数传递字符串更有效。但是该数字在不同的游戏运行或不同机器之间不相同，所以不要存储或通过网络发送它们。

### m_A.rt.Init(name + "A");
这行代码是用名称name + "A"初始化一个渲染纹理。Init方法用于设置渲染纹理。

### cmd.GetTemporaryRT(m_C.name, descC, m_FilterMode); //这里的m_c是一个RTHandle
申请了一个临时rt，同时还将该rt与第一个参数"nameID"所代表的全局的ShaderProperty进行了绑定，也就是说之后的shader都可以用与nameID对应的名称使用该rt。  
但是这里在调用CommandBuffer.ReleaseTemporaryRT进行释放并不是将该纹理清空了，该纹理依旧在内存中，如果在之后重新调用CommandBuffer.GetTemporaryRT申请一个大小格式相同的临时纹理，会拿到该纹理，也就是说CommandBuffer.GetTemporaryRT得到的不一定是一张干净的纹理，很有可能是已经被写过的，所以必要的时侯要进行clear。
[https://zhuanlan.zhihu.com/p/533122801]

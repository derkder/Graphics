link :[https://github.com/GameTechDev/DynamicCheckerboardRendering]

CBR key:
1. 2张 1/4 RT  2x msaa
2. viewport offset       
之前Unity的实例项目模仿源工程只给viewport + 0.25/0.75，是不对的，因为Unity会自动拉伸，所以要通过改[projectionMatrix](https://www.songho.ca/opengl/gl_projectionmatrix.html)，通过看ProjectionMatrix的计算方式将l和r的值都加上（l - r） / 2 的偏移(这里l - r = screenwidth = 1920)     
3. Interpolation Modifier(给渲染物体用的standard shader中的片元着色器输出的uv加sample修饰符（不是改合并CBR的shader）)  
[https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl-struct]  
[https://learnopengl-cn.github.io/04%20Advanced%20OpenGL/11%20Anti%20Aliasing/]   （一个像素点只跑一次片元着色器）  
(之前主要是这里一直搞得不对，现象是16*16下测试，如果是真的搞了16个面片就可以对上，如果是搞了一整个plane里面的贴图是16*16的就对不上(Tecture2DMS.load第二个参数)，是因为不加上修饰符的话MSAA的结果就只会写入加权均值之后的，所以用load01根本拿不出来的  
但是为什么16个面片的情况就会处理对呢，可能是因为每个顶点经过MVP变换的时候，还是在同一个像素点写了两次，所以还是被TDMS记下来了
)
4. mipmap bias(解决模糊的问题)  (一篇有点关系的文章Texture Streaming)[https://zhuanlan.zhihu.com/p/544892912]_


（没错，所以和中途想的不能用mipmap和不能用power of 2都没什么关系）

https://blog.csdn.net/Le_Sam/article/details/84929740   
https://zhuanlan.zhihu.com/p/98642798    


## draw call是openGL的描绘次数  
一个简单的openGL的绘图次序是：设置颜色→绘图方式→顶点座标→绘制→结束。  
每帧都会重复以上的步骤。这就是一次draw call  
（真正的CPU消耗来自drawcall前的设置工作，而不是GPU drawcall本身；Drawcall只是一些Unity向GPU command buffer发送的bytes）  
  
## 批处理
批处理就是把渲染时**使用相同材质(Shader)、相同贴图**的3D模型的网格合并在一起，成为一个大网格，然后再调用一次Draw Call，直接渲染这一个大网格。  
动态合批与静态合批其本质是对将多次绘制请求，在允许的条件下进行合并处理，减少cpu对gpu绘制请求的次数，达到提高性能的目的。  
个人估计unity3d的dynamic batch,static batch都是通过一定的方法使不同的object的顶点座标能够结合成一个整体，达到减少draw calls的效果。  
但是有一定的要求限制，比如material要相同，mesh要相同并在300个面以内等等，这些都是为了保证openGl的状态值不改变。  


## Unity在 Player Setting 里的两个功能选项 Static Batching 与 Dynamic Batching。
### Static Batching 
   **并不减少drawcall数量**，虽然把每个子模型的vertex集合都合起来变成一个大vertex集合但是每个子模型还是一次drawcall；而是没有渲染状态的切换减少计算，即**减少的是SetPassCall**
  &nbsp;&nbsp;是将标明为 Static 的静态物件，如果在使用相同材质球的条件下，Unity 会自动帮你把这两个物件合并成一个 Batch，送往 GPU 来处理。这功能对效能上非常的有帮助。   
  &nbsp;&nbsp;运行时cpu不需要再次执行顶点变换操作，节约了少量的计算资源，并且这些子模型共享材质，所以在多次Draw call调用之间并没有渲染状态的切换，渲染API（Command Buffer）会缓存绘制命令，起到了渲染优化的目的（**每个子模型共用一个commandbuffer**）   
  &nbsp;&nbsp;但Static batching也会带来一些性能的负面影响。Static batching会导致应用打包之后体积增大，应用运行时所占用的内存体积也会增大。茂密的森林就不能用   
### Dynamic Batching   
  动态合批在运行时Unity自动把每一帧画面里符合条件（**物件小于300面的条件下(不论物件是否为静态或动态)，使用相同材质球**）的多个模型网格合并为一个，减少的就是drawcall了。  
  具体原理是，先把顶点信息变换到世界空间中（CPU），后通过一次Draw call绘制多个模型。  


## drawcall的数量等于批batches的数量

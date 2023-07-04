## 定义：
卡通着色就是使用一个多段的色带来渲染对象，而非使用连续的渐变。


## 来源
[https://zhuanlan.zhihu.com/p/338549713]


## 思路  
basic：计算法线和光线的点积，为点积设定阈值，可以定义多个色带  
develop：basic有其它的光源将不能影响卡通着色对象的问题，所以计算表面光照量来取代点积  

## 具体做法：
1、新建材质，其中蓝图：
    Desaturation节点将把Post Process Input和Diffuse Color转换成灰度图像，也就是去颜色      
    用Divide节点将Post Process Input除以Diffuse Color，是我们获得光照缓存。      
    Clamp节点是出数值介于0到1之间。     
    使用If节点，使光照值高于0.5的像素输出正常颜色，使小于0.5的像素输出亮度减半的颜色。      
2、使用后期处理材质Post Process Volume  
2、使后处理在tonemapping之前进行  
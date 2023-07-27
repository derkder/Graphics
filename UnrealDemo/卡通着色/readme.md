## 卡通着色：celshading
### 定义：
卡通着色就是使用一个多段的色带来渲染对象，而非使用连续的渐变。


### 来源
[https://zhuanlan.zhihu.com/p/338549713]


## 思路  
basic：计算法线和光线的点积，为点积设定阈值，可以定义多个色带  
develop：basic有其它的光源将不能影响卡通着色对象的问题，所以计算表面光照量来取代点积  

### 具体做法：
1、新建材质，其中蓝图：
    Desaturation节点将把Post Process Input和Diffuse Color（这个是没有任何光照和后处理的场景，和平常说的漫反射概念不一样）转换成灰度图像，也就是去颜色,留灰度（代表颜色的深浅(光找到就浅没照到就深)）  
    用Divide节点将Post Process Input除以Diffuse Color，是我们获得光照缓存。        
    Clamp节点是出数值介于0到1之间。       
    使用If节点，使光照值高于0.5的像素输出正常颜色，使小于0.5的像素输出亮度减半的颜色。      
2、使用后期处理材质Post Process Volume  
3、使后处理在tonemapping之前进行  
4、对比自定义深度和场景深度只将人物卡通渲染  
5、使用查找表lookoptable（LUT）对应的texture将灰度值放在三个区间里   

### 补充
最后的结果应该是同一个颜色根据该片元对应的灰度（光照量）不同，映射成三个灰度显示，而不是平滑过渡

---

## 卡通轮廓线（Toon Outlines）： 后期处理法
### 来源：这是我看过最清晰的卷积判断边缘的思路
[https://zhuanlan.zhihu.com/p/338549713]
### 补充：创建粗线
使用空洞卷积或膨胀卷积：  
在空洞卷积中，我们仅仅是把偏移量放得更远一点。  
### 补充四种实现轮廓线的方法：
对片元的灰度做卷积、深度测试、法线https://roystan.net/articles/outline-shader/

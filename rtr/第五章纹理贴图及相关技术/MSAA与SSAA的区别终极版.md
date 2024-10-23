### Intro
从Per Sample Shading做到了Per Piexl Shading。但是，对于4xMSAA来说，每个像素都会有4个Sample点。这样 Sample都有各自对应的 Color、Depth/Stencil 值，所以确实是有巨大的内存问题。

### 细一点来说
msaa把传统的着色步骤分成了两步。  
第一步对于一个像素生出四个采样点，对三角形图元去做一步coverage mask，用0011这种编码标注出来哪几个采样点被三角形覆盖了   
第二步，以像素而不是采样点为单位做着色，例如算blinn phong什么的，然后把这个结果给采样点的color buffer和depth什么的（所以深度测试什么的其实是用sample作为单位计算的）


### 传统的说法 ： msaa只处理边缘ssaa处理全部
这说法也没错，但是理解得实在太浅。   
根据上面的说法，在第一步中我们要算掩码，如果算出来是0000的话，就不会处理了
https://www.zhihu.com/question/496212252/answer/2632706776

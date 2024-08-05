## 重投影（静态物体）：
#### 问题描述
假设我有当前的屏幕坐标screenPos和上一帧与这一帧的投影矩阵变换view.ClipToPrevClip,我怎么求这一个像素点在上一帧的位置：
#### 步骤 
1.齐次化      
clipPos = float4(screenpos.xy, screenpos.z[当前像素的深度], 1);     
2.矩阵变换     
prevclip = mul(clipPos, view.ClipToPrevClip)   
3.再次投影到屏幕空间  
prevscreen = prevclip.xy / prevclip.w   


 
### 各个空间说明recap：    
局部空间  ->  世界空间  -> 视图空间(camera) -投影矩阵--> 剪裁空间（clip space）（齐次）[-1, 1] -> 屏幕空间[1920]
其中，剪裁空间到屏幕空间经历了有名的ndc    
剪裁空间[x, y, z, w] ----NDC---->[x/w, y/w, z/w] ---x = (x + 1) / 2 * ScreenX, y = ... --》 屏幕空间

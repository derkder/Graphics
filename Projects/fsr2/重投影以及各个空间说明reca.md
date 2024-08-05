## 重投影：
#### 问题描述
假设我有当前的屏幕坐标screenPos和上一帧与这一帧的投影矩阵变换view.ClipToPrevClip,我怎么求这一个像素点在上一帧的位置：
#### 步骤
1 齐次化
clipPos = float4(screenpos, 1);
2 矩阵变换
prevclip = mul(clipPos, view.ClipToPrevClip)
3 再次投影到屏幕空间
prevscreen = prevclip.xy / prevclip.w

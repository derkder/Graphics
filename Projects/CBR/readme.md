link :[https://github.com/GameTechDev/DynamicCheckerboardRendering]

CBR key:
1. 2张 1/4 RT  2x msaa
2. viewport offset 
3. Interpolation Modifier(sample)   
[之前主要是这里一直搞得不对，现象是16*16下测试，如果是真的搞了16个面片就可以对上，如果是搞了一整个plane里面的贴图是16*16的就对不上] 
5. mipmap bias

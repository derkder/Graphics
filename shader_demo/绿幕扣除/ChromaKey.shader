// Created by Oliver Davies. Enjoy. 
// oliver@psyfer.io
//在原来算法【http://gc-films.com/chromakey.html】转化成YCrCb的基础上，用高斯滤波平滑，并用Despill消除green bleeding，最后改亮度luminance来修正Despill算法得到的图像会偏暗
//现在的参数效果一级棒
//实践https://blog.csdn.net/newchenxf/article/details/119575690
Shader "Unlit/ChromaKey"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}//从视频里拿的每一帧texture
        _KeyColor("KeyColor", Color) = (0,1,0,0)
        _TintColor("TintColor", Color) = (1,1,1,1)
        _ColorCutoff("Cutoff", Range(0, 1)) = 0.2
        _ColorFeathering("ColorFeathering", Range(0, 1)) = 0.33
        _MaskFeathering("MaskFeathering", Range(0, 1)) = 1
        _Sharpening("Sharpening", Range(0, 1)) = 0.5

        _Despill("DespillStrength", Range(0, 1)) = 1
        _DespillLuminanceAdd("DespillLuminanceAdd", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="HDRenderPipeline"
            "RenderType"="HDUnlitShader"
            "Queue" = "Transparent+1"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        cull off

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				//float4 uvgrab : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float4 _MainTex_ST;
            float4 _KeyColor;
            float4 _TintColor;
            float _ColorCutoff;
            float _ColorFeathering;
            float _MaskFeathering;
            float _Sharpening;
            float _Despill;
            float _DespillLuminanceAdd;
			//sampler2D _GrabTexture;
			//float4 _GrabTexture_TexelSize;

			#define GRABXYPIXEL(kernelx, kernely) tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(float4(i.uvgrab.x + _GrabTexture_TexelSize.x * kernelx, i.uvgrab.y + _GrabTexture_TexelSize.y * kernely, i.uvgrab.z, i.uvgrab.w)))



            // Utility functions -----------

            float rgb2y(float3 c) 
            {
                return (0.299*c.r + 0.587*c.g + 0.114*c.b);
            }

            float rgb2cb(float3 c) 
            {
                return (0.5 + -0.168736*c.r - 0.331264*c.g + 0.5*c.b);
            }

            float rgb2cr(float3 c) 
            {
                return (0.5 + 0.5*c.r - 0.418688*c.g - 0.081312*c.b);
            }

            float colorclose(float Cb_p, float Cr_p, float Cb_key, float Cr_key, float tola, float tolb)
            {
                float temp = (Cb_key-Cb_p)*(Cb_key-Cb_p)+(Cr_key-Cr_p)*(Cr_key-Cr_p);
                float tola2 = tola*tola;
                float tolb2 = tolb*tolb;
                if (temp < tola2) return (0);
                if (temp < tolb2) return (temp-tola2)/(tolb2-tola2);
                return (1);
            }

            float maskedTex2D(sampler2D tex, float2 uv)
            {
                float4 color = tex2D(tex, uv);
                
                // Chroma key to CYK conversion
                float key_cb = rgb2cb(_KeyColor.rgb);
                float key_cr = rgb2cr(_KeyColor.rgb);
                float pix_cb = rgb2cb(color.rgb);
                float pix_cr = rgb2cr(color.rgb);

                return colorclose(pix_cb, pix_cr, key_cb, key_cr, _ColorCutoff, _ColorFeathering);//像keycolour的地方返回0，超级不像的返回1，中间的返回(temp-tola2)/(tolb2-tola2)
            }

            //-------------------------

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				//o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y) + o.vertex.w) * 0.5;
				//o.uvgrab.zw = o.vertex.zw;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // Get pixel width
                float2 pixelWidth = float2(1.0 / _MainTex_TexelSize.z, 0);
                float2 pixelHeight = float2(0, 1.0 / _MainTex_TexelSize.w);


				//float2 uv = i.uv.xy;
				//half4 grab = GRABXYPIXEL(0,0);

                // Unmodified MainTex
                float4 color = tex2D(_MainTex, i.uv);

                // Unfeathered mask
                float mask = maskedTex2D(_MainTex, i.uv);

                // Feathering & smoothing高斯平滑，用来降噪的好像是
                float c = mask;
		//下面把句话相当于用一个卷积（也就是一个3*3的举证去扫描这个像素，用得到的邻域内像素的加权平均灰度值去替代模板中心像素点的值）
                float r = maskedTex2D(_MainTex, i.uv + pixelWidth);
                float l = maskedTex2D(_MainTex, i.uv - pixelWidth);
                float d = maskedTex2D(_MainTex, i.uv + pixelHeight); 
                float u = maskedTex2D(_MainTex, i.uv - pixelHeight);
                float rd = maskedTex2D(_MainTex, i.uv + pixelWidth + pixelHeight) * .707;//https://www.cnblogs.com/L707/p/17053415.html
                float dl = maskedTex2D(_MainTex, i.uv - pixelWidth + pixelHeight) * .707;
                float lu = maskedTex2D(_MainTex, i.uv - pixelHeight - pixelWidth) * .707;
                float ur = maskedTex2D(_MainTex, i.uv + pixelWidth - pixelHeight) * .707;
                float blurContribution = (r + l + d + u + rd + dl + lu + ur + c) * 0.12774655;//高斯滤波的出来的一个模糊参数
                float smoothedMask = smoothstep(_Sharpening, 1, lerp(c, blurContribution, _MaskFeathering));
                ////此函数采用与 Lerp 相似的方式在 min 与 max 之间进行插值。 但是，插值会从起点逐渐加速，然后朝着终点减慢。不知道这个公式哪里来的
                float4 result = color * smoothedMask;//本来应该是*Mask，上面用一个奇怪的算法[或许是高斯滤波平滑？]优化mask是的它smooth了

                // Despill,关了之后周边有绿光，但是不泛红了，double blue average
                float v = (2*result.b+result.r)/3;//按公式来说是除3，但是作者写的除4，不知道为嘛，我又给他改回来了
                if(result.g > v) result.g = lerp(result.g, v, _Despill);
		//改亮度luminance来修正Despill算法得到的图像会片暗，https://benmcewan.com/blog/2018/05/20/understanding-despill-algorithms/
                float4 dif = (color - result);
                float desaturatedDif = rgb2y(dif.xyz);
                result += lerp(0, desaturatedDif, _DespillLuminanceAdd);
                
                return float4(result.xyz, smoothedMask);
            }
            ENDCG
        }
    }
}

Shader "Custom/BlackAndWhite"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Cull Off
            ZWrite Off
            ZTest Always

            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
            #pragma target 4.5
            #include "Assets/ShaderDebugger/debugger.cginc"
 
            #include "UnityCG.cginc"
 
            uniform sampler2D _MainTex;
            uniform float _bwBlend;
 
            float4 frag(v2f_img i) : COLOR
            {
                uint root = DebugFragment(i.pos);
                float4 c = tex2D(_MainTex, i.uv);
                DbgSetColor(root, c);
                DbgDisc(root, 7);

                float lum = c.r*.3 + c.g*.59 + c.b*.11;

                float3 bw = float3( lum, lum, lum );
 
                c.rgb = bw;
                return c;
            }
            ENDCG
        }
    }
}

Shader "Custom/DebugDemo"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            #pragma target 4.5
            #include "Assets/ShaderDebugger/debugger.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
                float4 localPosition : float4;
            };

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPosition = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                float red = i.localPosition.x;
            
                uint root = DebugFragment(i.vertex);
                DbgSetColor(root, float4(1, i.localPosition.x, 0, 1));
                DbgVectorO3(root, i.localPosition.xyz);
                
                DbgChangePosByO3(root, i.localPosition.xyz);
                DbgValue1(root, i.localPosition.x);

                return fixed4(red, 0, 0, 1);
			}
			ENDCG
		}
	}
}

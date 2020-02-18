Shader "Custom/DemoVertex"
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
                float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
                float4 localPosition : float4;
            };

			v2f vert (appdata v)
			{
				v2f o;
                uint root = DebugVertexO4(v.vertex);
                DbgSetColor(root, float4(1, v.vertex.x, 0, 1));
                DbgVectorO3(root, v.normal * 0.25);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.localPosition = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                float green = i.localPosition.x;
                return fixed4(0, green, 0, 1);
			}
			ENDCG
		}
	}
}

Shader "Custom/HitShader"
{
    Properties
    {
        _Color("Color", Color) = (1, 0, 0, 1)
        _HitPoint("HitPoint", Vector) = (0, 0, 0, 0)
    }
    
    SubShader
    {
        Tags {
            "RenderType" = "Transparent" 
            "Queue" = "Transparent"
        }
        LOD 100

        Pass
        {
            ZWrite off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma target 4.5
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            #include "Assets/ShaderDebugger/debugger.cginc"

            struct incoming
            {
                float4 vertex : POSITION;
            };

            struct v2g
            {
                float4 pos : SV_POSITION;
                float4 vertex : TEXCOORD0;
            };

            struct g2f
            {
                float4 pos : SV_POSITION;
                fixed4 col : COLOR0;
            };

            v2g vert(incoming v) {
                v2g o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.vertex = v.vertex;
                return o;
            }

            fixed4 _Color;
            float4 _HitPoint;

            [maxvertexcount(3)]
            void geom(triangle v2g p[3], inout TriangleStream<g2f> triangleStream)
            {
                float4 center = (p[0].vertex + p[1].vertex + p[2].vertex) * (1 / 3.0);
                uint root = DebugVertexO4(center);
                DbgSetColor(root, fixed4(0, 0, 1, 1));
                DbgVectorO3(root, _HitPoint.xyz-center.xyz);

                float t = (_Time.y * 4) % 6;
                float dist = 3 * distance(center.xyz, _HitPoint.xyz) - t;
                fixed4 col = _Color * (1 - abs(dist));

                g2f o;
                o.col = col;
                o.pos = p[0].pos; triangleStream.Append(o);
                o.pos = p[1].pos; triangleStream.Append(o);
                o.pos = p[2].pos; triangleStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
        
            ENDCG
        }
    }
}

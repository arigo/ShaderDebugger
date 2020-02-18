Shader "Custom/MagicShader"
{
    Properties
    {
    }
    
    SubShader
    {
        Tags {
            "RenderType" = "Opaque" 
            "ForceNoShadowCasting" = "True"
        }
        LOD 100

        Pass
        {
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

            fixed4 getcolor(float r)
            {
                float f = sin((r + _Time.y) * 3.3) * 0.5 + 0.5;
                float f2 = sin((r + _Time.y) * 4.2) * 0.5 + 0.5;
                return fixed4(fixed3(f2, 0.1, 1) * f, 1);
            }

            [maxvertexcount(12)]
            void geom(triangle v2g p[3], inout TriangleStream<g2f> triangleStream)
            {
                g2f o;

                float4 v0 = p[0].pos;
                float4 v1 = p[1].pos;
                float4 v2 = p[2].pos;

                float4 v01 = UnityObjectToClipPos((p[0].vertex + p[1].vertex) * 0.5);
                float4 v02 = UnityObjectToClipPos((p[0].vertex + p[2].vertex) * 0.5);
                float4 v12 = UnityObjectToClipPos((p[1].vertex + p[2].vertex) * 0.5);

                o.col = getcolor(1);
                o.pos = v0; triangleStream.Append(o);
                o.pos = v01; triangleStream.Append(o);
                o.pos = v02; triangleStream.Append(o);
                triangleStream.RestartStrip();

                uint root = DebugVertexO4(p[0].vertex);
                DbgSetColor(root, o.col);
                float3 orthogonal = normalize(cross(p[1].vertex - p[0].vertex, p[2].vertex - p[0].vertex));
                DbgVectorO3(root, orthogonal * 0.5);
                DbgChangePosByO3(root, orthogonal * 0.5);
                DbgValue3(root, o.col.rgb);

                o.col = getcolor(2);
                o.pos = v1; triangleStream.Append(o);
                o.pos = v12; triangleStream.Append(o);
                o.pos = v01; triangleStream.Append(o);
                triangleStream.RestartStrip();

                o.col = getcolor(3);
                o.pos = v2; triangleStream.Append(o);
                o.pos = v02; triangleStream.Append(o);
                o.pos = v12; triangleStream.Append(o);
                triangleStream.RestartStrip();

                o.col = getcolor(4);
                o.pos = v12; triangleStream.Append(o);
                o.pos = v02; triangleStream.Append(o);
                o.pos = v01; triangleStream.Append(o);
            }

            fixed4 frag(g2f i) : SV_Target
            {
                return i.col;
            }
        
            ENDCG
        }
    }
}

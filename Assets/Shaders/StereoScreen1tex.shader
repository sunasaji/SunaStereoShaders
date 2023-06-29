//StereoScreen1tex.shader
//Copyright (c) 2022 sunasaji
//SPDX-License-Identifier: MIT

Shader "Unlit/StereoScreen1tex" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _ExtendX("Extend X", float) = 0.5
        _LeftShiftX("Left Shift X", float) = 0
        _RightShiftX("Right Shift X", float) = 0.5
        _ExtendY("Extend Y", float) = 1
        _LeftShiftY("Left Shift Y", float) = 0
        _RightShiftY("Right Shift Y", float) = 0
        [Toggle]_IsAVPRO("AVPro", Int) = 0
        // (_ExtendX, _LeftShiftX, _RightShiftX, _ExtendY, _LeftShiftY, _RightShiftY) : Explanation
        // (1,   0,   0,   1,   0,   0  ) : Normal Screen
        // (0.5, 0,   0.5, 1,   0,   0  ) : SBS(LR)
        // (0.5, 0.5, 0,   1,   0,   0  ) : SBS(RL)
        // (1,   0,   0,   0.5, 0.5, 0  ) : OverUnder(LeftOver)
        // (1,   0,   0,   0.5, 0,   0.5) : UnderOver(LeftUnder)
    }
    SubShader {
        Tags{ "RenderType"="Opaque" "IgnoreProjector"="True" "ForceNoShadowCasting"="True" "PreviewType"="Plane" }
        LOD 200
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float _ExtendX, ShiftX, _RightShiftX, _LeftShiftX, _ExtendY, ShiftY, _RightShiftY, _LeftShiftY;
            int _IsAVPRO;

            v2f vert (appdata v) {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                ShiftX = lerp(_LeftShiftX, _RightShiftX, unity_StereoEyeIndex);
                ShiftY = lerp(_LeftShiftY, _RightShiftY, unity_StereoEyeIndex);
                float2 ExtendedPos = float2(i.uv.x * _ExtendX + ShiftX, lerp(i.uv.y, 1-i.uv.y, _IsAVPRO) * _ExtendY + ShiftY);
                fixed4 e = tex2D(_MainTex, ExtendedPos);
                e.rgb = lerp(e.rgb, pow(e.rgb,2.2), _IsAVPRO);
                return e;
            }
            ENDCG
        }
    }
}

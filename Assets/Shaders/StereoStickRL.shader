// StereoStickRL Shader
// This shader sticks _LeftEyeTexture to the left half of a camera render texture and _RightEyeTexture to the right half.
// It can be used to capture Side-by-side(SBS) image by the camera.
// It works when the below conditions are satisfied.
// - Distance between object and camera is less than _Distance
// - Aspect ratio of the target camera is nearly equal to _TargetScreenRatio, defaults to 1.777 (16:9)
// - Red channel of _SwitchTex (0,0) is not zero, this is used to avoid interfering with other players in vrchat
//
// Copyright (c) 2021 sunasaji
// Copyright (c) 2019 yukatayu-vrc https://github.com/yukatayu-vrc/HUD_shader/blob/master/LICENSE
// This code is licensed under the MIT License.

Shader "Unlit/StereoStickRL" {
	Properties {
		_LeftEyeTexture ("Left Eye Texture", 2D) = "white" {}
		_RightEyeTexture ("Right Eye Texture", 2D) = "white" {}
		_SwitchTex ("Switch", 2D) = "white" {}
		_Distance ("Stick Distance", Float) = 1.0
		_TargetScreenRatio ("Target Screen Ratio, X/Y", Float) = 1.777
	}

	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Overlay+4000" "IgnoreProjector"="True"}
		ZTest Always
		Cull Off

		Pass {
			// Meta
			CGPROGRAM
			#include "UnityCG.cginc"

			// Struct
			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			// Param
			sampler2D _LeftEyeTexture;
			float4 _LeftEyeTexture_ST;
			sampler2D _RightEyeTexture;
			float4 _RightEyeTexture_ST;
			sampler2D _SwitchTex;
			float _Distance;
			float _TargetScreenRatio;

			// Vertex
			#pragma vertex vert
			v2f vert (appdata v) {
				v2f o;
				// Hide vertex to other players
				half4 showBoolTex = tex2Dlod(_SwitchTex, float4(0, 0, 0, 0));
				bool showFlag = showBoolTex.r != 0;
				// Hide vertex if screen ratio is different from _TargetScreenRatio. Default is 1.777,  16:9
				if(0.01 < abs(_TargetScreenRatio - 1.0 * _ScreenParams.x/_ScreenParams.y)) showFlag = 0;
				// Hide vertex if distance between the object and camera is larger than _Distance
				if(_Distance < length(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, float4(0,0,0,1)))) showFlag = 0;
				o.vertex = float4 (v.vertex.x * 2, v.vertex.y * -2 * _ProjectionParams.x, 1, 1) * showFlag;
				// Adjust uv.x for each eye
				if (v.uv.x < 0.5)
				{
					o.uv = TRANSFORM_TEX(float2(v.uv.x * 2, v.uv.y), _LeftEyeTexture);
				}
				else
				{
					o.uv = TRANSFORM_TEX(float2((v.uv.x - 0.5)*2, v.uv.y), _RightEyeTexture);
				}
				return o;
			}

			// Fragment
			#pragma fragment frag
			fixed4 frag (v2f i) : SV_Target {
				fixed4 col = fixed4(0, 0, 0, 0);
				fixed2 p = fixed2 (i.uv * float2(1, -1) + float2(0, 1));
				if (p.x < 0.5)
				{
					col = tex2D(_LeftEyeTexture, float2(p.x * 2, p.y));
				}
				else
				{
					col = tex2D(_RightEyeTexture, float2((p.x - 0.5) * 2, p.y));
				}
				return col;
			}
			ENDCG
		}
	}
}

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader"Ragnarok/CharacterSpriteShader"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
//		[PerRendererData] _PalTex("Palette Texture", 2D) = "white" {}
		[PerRendererData] _Color("Tint", Color) = (1,1,1,1)
		[PerRendererData] _EnvColor("Environment", Color) = (1,1,1,1)
		[PerRendererData] _Offset("Offset", Float) = 0
		[PerRendererData] _Width("Width", Float) = 0
		[PerRendererData] _VPos("VerticalPos", Float) = 0
		_ColorDrain("Color Drain", Range(0,1)) = 0
		_Rotation("Rotation", Range(0,360)) = 0
	}

	SubShader
	{
//		Tags
//		{
//			"Queue" = "Transparent"
//			"IgnoreProjector" = "True"
//			"RenderType" = "Transparent"
//			"PreviewType" = "Plane"
//			"CanUseSpriteAtlas" = "True"
//			"ForceNoShadowCasting" = "True"
//			"DisableBatching" = "true"
//		}
		
		Tags{ "Queue" = "Transparent" "LIGHTMODE" = "Vertex" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True"  }

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha
		
		
		Pass {
			ZWrite On
			Blend Zero One
//			AlphaToMask On


			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Billboard.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
			};


			sampler2D _MainTex;
			fixed4 _Color;
			fixed _VPos;

			
			v2f vert(appdata_t v)
			{
				v2f o;

				v.vertex.y += _VPos;

			//--------------------------------------------------------------------------------------------
			//start of billboard code
			//--------------------------------------------------------------------------------------------

			float2 pos = v.vertex.xy;

			float3 worldPos = mul(unity_ObjectToWorld, float4(pos.x, pos.y, 0, 1)).xyz;
			float3 originPos = mul(unity_ObjectToWorld, float4(pos.x, 0, 0, 1)).xyz; //world position of origin
			float3 upPos = originPos + float3(0, 1, 0); //up from origin

			float outDist = abs(pos.y); //distance from origin should always be equal to y

			float angleA = Angle(originPos, upPos, worldPos); //angle between vertex position, origin, and up
			float angleB = Angle(worldPos, _WorldSpaceCameraPos.xyz, originPos); //angle between vertex position, camera, and origin

			float camDist = distance(_WorldSpaceCameraPos.xyz, worldPos.xyz);

			if (pos.y > 0)
			{
				angleA = 90 - (angleA - 90);
				angleB = 90 - (angleB - 90);
			}

			float angleC = 180 - angleA - angleB; //the third angle

			float fixDist = 0;
			if (pos.y > 0)
				fixDist = (outDist / sin(radians(angleC))) * sin(radians(angleA)); //supposedly basic trigonometry

			//determine move as a % of the distance from the point to the camera
			float decRate = (fixDist * 0.7 + 0.1) / camDist; //where does the value come from? Who knows!
			float decRateNoOffset = (fixDist * 0.7) / camDist; //where does the value come from? Who knows!
			float decRate2 = (fixDist) / camDist; //where does the value come from? Who knows!


			float4 view = mul(UNITY_MATRIX_V, float4(worldPos, 1));

			float4 pro = mul(UNITY_MATRIX_P, view);

			#if UNITY_UV_STARTS_AT_TOP
				// Windows - DirectX
				view.z -= abs(UNITY_NEAR_CLIP_VALUE - view.z) * decRate2;
				pro.z -= abs(UNITY_NEAR_CLIP_VALUE - pro.z) * decRate;
			#else
				// WebGL - OpenGL
				view.z += abs(UNITY_NEAR_CLIP_VALUE) * decRate2;
				pro.z += abs(UNITY_NEAR_CLIP_VALUE) * decRate;
			#endif

			o.pos = pro;

			//--------------------------------------------------------------------------------------------
			//end of billboard code
			//--------------------------------------------------------------------------------------------
	

				//o.pos = Billboard2(v.vertex, 0);
				
				o.color = v.color * _Color;
				o.texcoord = v.texcoord;
				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				fixed4 c = tex2D(_MainTex, i.texcoord);
				c *= i.color;

				clip(c.a - 0.5);
				
				return c;
				return half4 (1,1,1,1);
			}
			ENDCG
		}
	
		Pass
		{
			Tags { "LIGHTMODE" = "Vertex" }
			
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			//#pragma multi_compile _ PIXELSNAP_ON
			//#pragma multi_compile _ PALETTE_ON
			#pragma multi_compile _ SMOOTHPIXEL
			#pragma multi_compile _ BLINDEFFECT_ON
			#pragma shader_feature _ WATER_OFF
			#pragma shader_feature _ COLOR_DRAIN

			//#define SMOOTHPIXEL
		

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"
			#include "Billboard.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				#if BLINDEFFECT_ON
				fixed4 color : COLOR0;
				fixed4 color2 : COLOR1;
				#else
				fixed4 color : COLOR;
				#endif
				float2 texcoord  : TEXCOORD0;
				float4 screenPos : TEXCOORD1;
				half4  worldPos : TEXCOORD2;
				UNITY_FOG_COORDS(3)
				UNITY_VERTEX_OUTPUT_STEREO

			};

			fixed4 _Color;
			fixed4 _EnvColor;
			fixed _Offset;
			fixed _Rotation;
			fixed _Width;
			fixed _ColorDrain;
			fixed _VPos;


			sampler2D _MainTex;
			// sampler2D _PalTex;

			float4 _ClipRect;
			float4 _MainTex_ST;
			float4 _MainTex_TexelSize;
			sampler2D _WaterDepth;
			sampler2D _WaterImageTexture;
			float4 _WaterImageTexture_ST;
								
			float _MaskSoftnessX;
			float _MaskSoftnessY;

			//from our globals
			float4 _RoAmbientColor;
			float4 _RoDiffuseColor;

			float4 unity_Lightmap_ST;

			#ifdef BLINDEFFECT_ON
				float4 _RoBlindFocus;
				float _RoBlindDistance;
			#endif

			float4 Rotate(float4 vert)
			{
				float4 vOut = vert;
				vOut.x = vert.x * cos(radians(_Rotation)) - vert.y * sin(radians(_Rotation));
				vOut.y = vert.x * sin(radians(_Rotation)) + vert.y * cos(radians(_Rotation));
				return vOut;
			}

			v2f vert(appdata_t v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID()
				UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO()
				
				//v.vertex = Rotate(v.vertex);
				v.vertex.y += _VPos;
		
				//--------------------------------------------------------------------------------------------
				//start of billboard code
				//--------------------------------------------------------------------------------------------

				float2 pos = v.vertex.xy;
	
				float3 worldPos = mul(unity_ObjectToWorld, float4(pos.x, pos.y, 0, 1)).xyz;
				float3 originPos = mul(unity_ObjectToWorld, float4(pos.x, 0, 0, 1)).xyz; //world position of origin
				float3 upPos = originPos + float3(0, 1, 0); //up from origin

				float outDist = abs(pos.y); //distance from origin should always be equal to y

				float angleA = Angle(originPos, upPos, worldPos); //angle between vertex position, origin, and up
				float angleB = Angle(worldPos, _WorldSpaceCameraPos.xyz, originPos); //angle between vertex position, camera, and origin

				float camDist = distance(_WorldSpaceCameraPos.xyz, worldPos.xyz);

				if (pos.y > 0)
				{
					angleA = 90 - (angleA - 90);
					angleB = 90 - (angleB - 90);
				}

				float angleC = 180 - angleA - angleB; //the third angle

				float fixDist = 0;
				if (pos.y > 0)
					fixDist = (outDist / sin(radians(angleC))) * sin(radians(angleA)); //supposedly basic trigonometry

				//determine move as a % of the distance from the point to the camera
				float decRate = (fixDist * 0.7 - _Offset/4) / camDist; //where does the value come from? Who knows!
				float decRateNoOffset = (fixDist * 0.7) / camDist; //where does the value come from? Who knows!
				float decRate2 = (fixDist) / camDist; //where does the value come from? Who knows!

				float4 view = mul(UNITY_MATRIX_V, float4(worldPos, 1));

				float4 pro = mul(UNITY_MATRIX_P, view);

				#if UNITY_UV_STARTS_AT_TOP
					// Windows - DirectX
					view.z -= abs(UNITY_NEAR_CLIP_VALUE - view.z) * decRate2;
					pro.z -= abs(UNITY_NEAR_CLIP_VALUE - pro.z) * decRate;
				#else
					// WebGL - OpenGL
					view.z += abs(UNITY_NEAR_CLIP_VALUE) * decRate2;
					pro.z += abs(UNITY_NEAR_CLIP_VALUE) * decRate;
				#endif

				o.vertex = pro;

				//--------------------------------------------------------------------------------------------
				//end of billboard code
				//--------------------------------------------------------------------------------------------
		
				//o.texcoord = v.texcoord;
				o.color = v.color * _Color;

				//old lightprobe code
				//o.envColor = clamp(float4(ShadeSH9(fixed4(0,1,0,1)),1) * 0.5, 0, 0.35);

				//o.envColor = float4(ShadeSH9(fixed4(0,1,0,1)),1);
				//o.envColor = float4(_EnvColor.rgb,1);
				
				float4 tempVertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o, tempVertex);
	
				//smoothpixelshader stuff here
				#ifdef SMOOTHPIXEL
				float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
				float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
				o.texcoord = float4(v.texcoord.x, v.texcoord.y, maskUV.x, maskUV.y);
				#else
				o.texcoord = v.texcoord;
				#endif

				#ifdef VERTEXLIGHT_ON
				float4 light = float4(ShadeVertexLightsFull(v.vertex, float3(0,1,0), 8, true), 1.0);
				#else
				float4 light = float4(0, 0, 0, 0); 
				#endif

				light += float4(_EnvColor.rgb * min(_EnvColor.a, 1),0);
				float lmax = max(light.r, max(light.g, light.b));
				//lmax = clamp(lmax, 0, 0.5);
				
				//light -= light/lmax;
				if(lmax > 0)
					o.color.rgb = o.color.rgb * ((light.rgb / lmax + 0.2)/1.2);
				//o.color.rgb = _EnvColor.rgb;
				//o.color.a = v.color;
				
				// o.light = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				
				//
				// o.lighting.xy = v.uv1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				// o.lighting.ba = v.uv1.xy * unity_Lightmap_ST.xy + unity_Lightmap_ST.zw;

				//end of smooth pixel
				#ifndef WATER_OFF

					//this mess fully removes the rotation from the matrix	
					float3 scale = float3(
						length(unity_ObjectToWorld._m00_m10_m20),
						length(unity_ObjectToWorld._m01_m11_m21),
						length(unity_ObjectToWorld._m02_m12_m22)
					);

					unity_ObjectToWorld._m00_m10_m20 = float3(scale.x, 0, 0);
					unity_ObjectToWorld._m01_m11_m21 = float3(0, scale.y, 0);
					unity_ObjectToWorld._m02_m12_m22 = float3(0, 0, scale.z);

					//build info needed for water line
					worldPos = mul(unity_ObjectToWorld, float4(pos.x, pos.y*1.5, 0, 1)).xyz; //fudge y sprite height 
					o.screenPos = ComputeScreenPos(o.vertex);
					o.worldPos = float4(pos.x, worldPos.y, 0, 0);
				#endif

				#if BLINDEFFECT_ON
					float d = distance(worldPos, _RoBlindFocus);
					//d = 1.2 - d / _RoBlindDistance;
					d = 1.5 - (d / _RoBlindDistance) * 1.5 + clamp((_RoBlindDistance-50)/120, -0.2, 0);
					o.color2.rgb = clamp(1 * d, -1, 1);
				#endif
								
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//environment ambient contribution disabled for now as it muddies the sprite
				//todo: turn ambient contribution back on if fog is disabled.
				 float4 env = float4(1,1,1,1);
				//return i.color;
				//float4 env = 1 - ((1 - _RoDiffuseColor) * (1 - _RoAmbientColor));
				//env = env * 0.3 + 0.7;// + saturate(0.5 + i.envColor);
					
				//smoothpixel
				// apply anti-aliasing
				#ifdef SMOOTHPIXEL
				float2 texturePosition = i.texcoord * _MainTex_TexelSize.zw;
				float2 nearestBoundary = round(texturePosition);
				float2 delta = float2(abs(ddx(texturePosition.x)) + abs(ddx(texturePosition.y)),
					abs(ddy(texturePosition.x)) + abs(ddy(texturePosition.y)));
	
				float2 samplePosition = (texturePosition - nearestBoundary) / delta;
				samplePosition = clamp(samplePosition, -0.5, 0.5) + nearestBoundary;

				fixed4 diff = tex2D(_MainTex, samplePosition * _MainTex_TexelSize.xy);
				#else
				fixed4 diff = tex2D(_MainTex,i.texcoord.xy);
				#endif
				// fixed4 diff = tex2D(_MainTex,i.texcoord.xy);
				//endsmoothpixel

				// //#ifdef PALETTE_ON
				// diff *= 256;
				// diff = floor(diff);
				// diff /= 256;
				// diff = float4(tex2D(_PalTex, float2((diff.r+diff.g+diff.b)/3, 0.5)).rgb, diff.a);
				// //#endif

				// fixed4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap, i.light.xy);
				// half3 bakedColor = DecodeLightmap(lm);

				//return float4(i.color.rgb/2, 1);

				//The UNITY_APPLY_FOG can't be called twice so we'll store it to re-use later
				float4 fogColor = float4(1,1,1,1);

				
				float avg = (diff.r + diff.g + diff.b) / 3;
				diff.rgb = lerp(diff.rgb, float3(avg, avg, avg), _ColorDrain);

				fixed4 c = diff * min(1.35, fogColor * i.color * float4(env.rgb,1)); // + float4(i.light.rgb,0);
				c = saturate(c);

				if(c.a < 0.001)
					discard;

				
	
				#ifndef WATER_OFF
					float2 uv = (i.screenPos.xy / i.screenPos.w);
					float4 water = tex2D(_WaterDepth, uv);
					float2 wateruv = TRANSFORM_TEX(water.xy, _WaterImageTexture);
				
					if (water.a < 0.1)
						return c;
	
					float4 waterTex = tex2D(_WaterImageTexture, wateruv);
					float height = water.z;
					
					waterTex = float4(0.5, 0.5, 0.5, 1) + (waterTex * 0.6);
	
					float simHeight = i.worldPos.y - abs(i.worldPos.x)/(_Width)*0.5;
	
					simHeight = clamp(simHeight, i.worldPos.y - 0.4, i.worldPos.y);
					waterTex *= fogColor;
					
					if (height-0 > simHeight)
						c.rgb *= lerp(float3(1, 1, 1), waterTex.rgb, saturate(((height - 0) - simHeight) * 10));

				#endif

				UNITY_APPLY_FOG(i.fogCoord, c);
				c.rgb *= c.a;



				#ifdef BLINDEFFECT_ON
				c.rgb = saturate(c.rgb * i.color2);
				#endif

				return c;
			}
		ENDCG
		}
	}
}

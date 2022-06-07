// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TFE/Toon/Lightning PBR Dissolve"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		[Header(Toonificator)]_GradientMainLight("GradientMainLight", 2D) = "white" {}
		_GradientOtherLights("GradientOtherLights", 2D) = "white" {}
		_MinGradient("MinGradient", Range( 0 , 1)) = 0
		[Space(20)]_MaxGradient("MaxGradient", Range( 0 , 1)) = 1
		[Header(Overall Tex)]_Tiling("Tiling", Float) = 1
		_FallOff("FallOff", Float) = 0.5
		[Enum(Color,0,Texture,1,Triplanar,2)][Header(Base Color)]_BaseColorType("BaseColor Type", Float) = 0
		_BaseColor("BaseColor", 2D) = "white" {}
		_MainColor("Main Color", Color) = (1,0.3537736,0.3537736,0)
		[Header(Normal)][Toggle]_UseMeshNormal("Use Mesh Normal", Float) = 0
		[Normal]_NormalTex("NormalTex", 2D) = "bump" {}
		[Space(20)]_NormalScale("NormalScale", Float) = 1
		[Header(Glossiness)]_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_SmoothnessMultiplier("SmoothnessMultiplier", Float) = 1
		_MaxGlossiness("MaxGlossiness", Float) = 1
		_GlossMap("GlossMap", 2D) = "white" {}
		[Toggle]_GlossInAlbedoAlpha("GlossInAlbedoAlpha", Float) = 1
		[Header(Metalness)]_Metalness("Metalness", Range( 0 , 1)) = 0
		[Enum(Total,0,Diffuse,1,Specular,2,Debug,3)]_OutputSelection("Output Selection", Float) = 0
		_AmbientLightInfluence("AmbientLight Influence", Range( 0 , 0.5)) = 0.2
		_MetalMap("MetalMap", 2D) = "white" {}
		[Header(Dissolve)]_DissolveTexture("DissolveTexture", 2D) = "white" {}
		[HDR]_DissolveBorderColor("DissolveBorderColor", Color) = (1,1,1,0)
		_Value("Value", Range( 0 , 1)) = 1
		_BorderMask("BorderMask", Float) = 0.05
		_DissolveTilingRemapValue("DissolveTilingRemapValue", Vector) = (0,0,0,0)
		_TriplanarDissolvelGradientBorder("TriplanarDissolvelGradientBorder", Float) = 0
		_TriplanarVerticalGradientMinMaxOffset("TriplanarVerticalGradientMinMaxOffset", Vector) = (0,0,0,0)
		[Enum(R,0,G,1,B,2,A,3)]_DissolveChannel("DissolveChannel", Int) = 0
		_StepValue("StepValue", Range( 0 , 1)) = 0
		[Toggle]_GlobalValue("GlobalValue", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#define ASE_TEXTURE_PARAMS(textureName) textureName

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_texcoord;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float4 _DissolveBorderColor;
		uniform float _StepValue;
		uniform float _BorderMask;
		uniform int _DissolveChannel;
		uniform sampler2D _DissolveTexture;
		uniform float4 _DissolveTilingRemapValue;
		uniform float _GlobalValue;
		uniform float _Value;
		uniform float BossDissolve;
		uniform float _TriplanarDissolvelGradientBorder;
		uniform float3 _TriplanarVerticalGradientMinMaxOffset;
		uniform float _OutputSelection;
		uniform float _UseMeshNormal;
		uniform float _BaseColorType;
		uniform sampler2D _NormalTex;
		uniform float _Tiling;
		uniform float _FallOff;
		uniform float _NormalScale;
		uniform float _GlossInAlbedoAlpha;
		uniform sampler2D _GlossMap;
		uniform sampler2D _BaseColor;
		uniform float4 _MainColor;
		uniform float _Smoothness;
		uniform sampler2D _GradientOtherLights;
		uniform sampler2D _GradientMainLight;
		uniform float _MinGradient;
		uniform float _MaxGradient;
		uniform float _SmoothnessMultiplier;
		uniform sampler2D _MetalMap;
		uniform float _Metalness;
		uniform float _MaxGlossiness;
		uniform float _AmbientLightInfluence;
		uniform float _Cutoff = 0.5;


		inline float4 TriplanarSamplingSF( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		inline float3 TriplanarSamplingSNF( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.zy * float2( nsign.x, 1.0 ) ) );
			yNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xz * float2( nsign.y, 1.0 ) ) );
			zNorm = ( tex2D( ASE_TEXTURE_PARAMS( topTexMap ), tiling * worldPos.xy * float2( -nsign.z, 1.0 ) ) );
			xNorm.xyz = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2( nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2( nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			float temp_output_3_0_g26 = _BorderMask;
			float temp_output_27_0_g26 = (-temp_output_3_0_g26 + (_StepValue - 0.0) * (( 1.005 + temp_output_3_0_g26 ) - -temp_output_3_0_g26) / (1.0 - 0.0));
			int temp_output_4_0_g19 = _DissolveChannel;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float4 triplanar237 = TriplanarSamplingSF( _DissolveTexture, ase_worldPos, ase_worldNormal, 0.5, (_DissolveTilingRemapValue).xy, 1.0, 0 );
			float temp_output_7_0_g19 = (( (float)temp_output_4_0_g19 == 0.0 ) ? triplanar237.x :  triplanar237.y );
			float temp_output_12_0_g19 = (( (float)temp_output_4_0_g19 == 2.0 ) ? triplanar237.z :  temp_output_7_0_g19 );
			float temp_output_3_0_g23 = (( (float)temp_output_4_0_g19 == 3.0 ) ? triplanar237.w :  temp_output_12_0_g19 );
			float temp_output_275_0 = (_DissolveTilingRemapValue.z + ((( _GlobalValue )?( BossDissolve ):( _Value )) - 0.0) * (_DissolveTilingRemapValue.w - _DissolveTilingRemapValue.z) / (1.0 - 0.0));
			float temp_output_257_0 = max( _TriplanarDissolvelGradientBorder , 0.05 );
			float temp_output_4_0_g23 = temp_output_257_0;
			float temp_output_6_0_g23 = (-temp_output_4_0_g23 + (temp_output_275_0 - 0.0) * (( temp_output_4_0_g23 + 1.0 ) - -temp_output_4_0_g23) / (1.0 - 0.0));
			float temp_output_9_0_g23 = ( temp_output_6_0_g23 - temp_output_4_0_g23 );
			float temp_output_2_0_g25 = temp_output_9_0_g23;
			float temp_output_11_0_g23 = ( temp_output_6_0_g23 + temp_output_4_0_g23 );
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float temp_output_3_0_g20 = saturate( (0.0 + (( ase_vertex3Pos.y + _TriplanarVerticalGradientMinMaxOffset.z ) - _TriplanarVerticalGradientMinMaxOffset.x) * (1.0 - 0.0) / (_TriplanarVerticalGradientMinMaxOffset.y - _TriplanarVerticalGradientMinMaxOffset.x)) );
			float temp_output_4_0_g20 = temp_output_257_0;
			float temp_output_6_0_g20 = (-temp_output_4_0_g20 + (temp_output_275_0 - 0.0) * (( temp_output_4_0_g20 + 1.0 ) - -temp_output_4_0_g20) / (1.0 - 0.0));
			float temp_output_9_0_g20 = ( temp_output_6_0_g20 - temp_output_4_0_g20 );
			float temp_output_2_0_g22 = temp_output_9_0_g20;
			float temp_output_11_0_g20 = ( temp_output_6_0_g20 + temp_output_4_0_g20 );
			float temp_output_249_0 = saturate( ( ( temp_output_3_0_g20 - temp_output_2_0_g22 ) / ( temp_output_11_0_g20 - temp_output_2_0_g22 ) ) );
			float temp_output_273_0 = ( saturate( ( ( temp_output_3_0_g23 - temp_output_2_0_g25 ) / ( temp_output_11_0_g23 - temp_output_2_0_g25 ) ) ) * temp_output_249_0 );
			float temp_output_1_0_g26 = temp_output_273_0;
			float temp_output_8_0_g26 = step( ( temp_output_27_0_g26 - temp_output_3_0_g26 ) , temp_output_1_0_g26 );
			float temp_output_233_9 = saturate( temp_output_8_0_g26 );
			float DissolveMask221 = temp_output_233_9;
			float temp_output_4_0_g27 = _OutputSelection;
			float Debug167 = temp_output_233_9;
			float4 temp_cast_7 = (Debug167).xxxx;
			float3 normalizeResult171 = normalize( ( _WorldSpaceLightPos0.xyz - ase_worldPos ) );
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch173 = _WorldSpaceLightPos0.xyz;
			#else
				float3 staticSwitch173 = normalizeResult171;
			#endif
			float3 LightDir188 = staticSwitch173;
			float3 normalizeResult190 = normalize( LightDir188 );
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 normalizeResult126 = normalize( ( normalizeResult190 + ase_worldViewDir ) );
			float DisplayType69 = _BaseColorType;
			float temp_output_4_0_g17 = DisplayType69;
			float2 appendResult49 = (float2(_Tiling , _Tiling));
			float2 Tiling73 = appendResult49;
			float2 temp_output_13_0_g15 = Tiling73;
			float TriplanarFallOffg74 = _FallOff;
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float temp_output_11_0_g15 = _NormalScale;
			float3 triplanar17_g15 = TriplanarSamplingSNF( _NormalTex, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, temp_output_13_0_g15, temp_output_11_0_g15, 0 );
			float3 tanTriplanarNormal17_g15 = mul( ase_worldToTangent, triplanar17_g15 );
			float3 newWorldNormal4_g15 = normalize( (WorldNormalVector( i , tanTriplanarNormal17_g15 )) );
			float temp_output_11_0_g16 = _NormalScale;
			float2 temp_output_13_0_g16 = Tiling73;
			float3 newWorldNormal4_g16 = normalize( (WorldNormalVector( i , UnpackScaleNormal( tex2D( _NormalTex, ( temp_output_13_0_g16 * i.uv_texcoord ) ), temp_output_11_0_g16 ) )) );
			float3 temp_output_94_0 = newWorldNormal4_g16;
			float4 temp_output_7_0_g17 = (( temp_output_4_0_g17 == 0.0 ) ? float4( temp_output_94_0 , 0.0 ) :  float4( temp_output_94_0 , 0.0 ) );
			float4 temp_output_12_0_g17 = (( temp_output_4_0_g17 == 2.0 ) ? float4( newWorldNormal4_g15 , 0.0 ) :  temp_output_7_0_g17 );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float4 WorldNormal27 = (( _UseMeshNormal )?( float4( ase_normWorldNormal , 0.0 ) ):( temp_output_12_0_g17 ));
			float dotResult130 = dot( float4( normalizeResult126 , 0.0 ) , WorldNormal27 );
			float NdotH146 = dotResult130;
			float2 UV61 = ( i.uv_texcoord * Tiling73 );
			float temp_output_4_0_g18 = DisplayType69;
			float4 triplanar46 = TriplanarSamplingSF( _BaseColor, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, Tiling73, 1.0, 0 );
			float4 temp_output_7_0_g18 = (( temp_output_4_0_g18 == 0.0 ) ? _MainColor :  tex2D( _BaseColor, UV61 ) );
			float4 temp_output_12_0_g18 = (( temp_output_4_0_g18 == 2.0 ) ? triplanar46 :  temp_output_7_0_g18 );
			float4 temp_output_67_0 = temp_output_12_0_g18;
			float AlbedoAlpha164 = (temp_output_67_0).w;
			float e134 = exp2( ( (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )) * 12.0 * _Smoothness ) );
			float dotResult3 = dot( WorldNormal27 , float4( staticSwitch173 , 0.0 ) );
			float temp_output_4_0 = (dotResult3*0.5 + 0.5);
			float2 appendResult9 = (float2(temp_output_4_0 , 0.0));
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch55 = (tex2D( _GradientMainLight, appendResult9 )).rgb;
			#else
				float3 staticSwitch55 = (tex2D( _GradientOtherLights, appendResult9 )).rgb;
			#endif
			float3 temp_cast_16 = (_MinGradient).xxx;
			float3 temp_cast_17 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float3 temp_output_113_0 = (temp_cast_16 + (staticSwitch55 - float3( 0,0,0 )) * (temp_cast_17 - temp_cast_16) / (float3( 1,1,1 ) - float3( 0,0,0 )));
			float3 desaturateInitialColor185 = temp_output_113_0;
			float desaturateDot185 = dot( desaturateInitialColor185, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar185 = lerp( desaturateInitialColor185, desaturateDot185.xxx, 1.0 );
			float NdotL104 = (desaturateVar185).x;
			float temp_output_140_0 = ( pow( NdotH146 , e134 ) * ( ( e134 * 0.125 ) + 1.0 ) * NdotL104 );
			float lerpResult208 = lerp( temp_output_140_0 , ( _SmoothnessMultiplier * temp_output_140_0 ) , (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )));
			float3 temp_cast_18 = (_MinGradient).xxx;
			float3 temp_cast_19 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float4 BaseColor83 = temp_output_67_0;
			float lerpResult205 = lerp( 0.0 , 0.7 , _Metalness);
			float Metalness151 = ( tex2D( _MetalMap, UV61 ).r * lerpResult205 );
			float4 Diffuse21 = ( float4( temp_output_113_0 , 0.0 ) * BaseColor83 * ( 1.0 - Metalness151 ) );
			float4 lerpResult141 = lerp( float4( 0.05,0.05,0.05,0 ) , Diffuse21 , Metalness151);
			float4 Specular150 = ( lerpResult208 * lerpResult141 );
			float4 temp_cast_21 = (_MaxGlossiness).xxxx;
			float4 clampResult212 = clamp( Specular150 , float4( 0,0,0,0 ) , temp_cast_21 );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 temp_output_160_0 = ( UNITY_LIGHTMODEL_AMBIENT * BaseColor83 * _AmbientLightInfluence );
			float4 temp_output_7_0_g27 = (( temp_output_4_0_g27 == 0.0 ) ? ( ( ( saturate( Diffuse21 ) + clampResult212 ) * float4( ( ase_lightColor.rgb * ase_lightAtten ) , 0.0 ) ) + temp_output_160_0 ) :  Diffuse21 );
			float4 temp_output_12_0_g27 = (( temp_output_4_0_g27 == 2.0 ) ? Specular150 :  temp_output_7_0_g27 );
			float4 Output162 = (( temp_output_4_0_g27 == 3.0 ) ? temp_cast_7 :  temp_output_12_0_g27 );
			c.rgb = Output162.xyz;
			c.a = 1;
			clip( DissolveMask221 - _Cutoff );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
			float temp_output_3_0_g26 = _BorderMask;
			float temp_output_27_0_g26 = (-temp_output_3_0_g26 + (_StepValue - 0.0) * (( 1.005 + temp_output_3_0_g26 ) - -temp_output_3_0_g26) / (1.0 - 0.0));
			int temp_output_4_0_g19 = _DissolveChannel;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float4 triplanar237 = TriplanarSamplingSF( _DissolveTexture, ase_worldPos, ase_worldNormal, 0.5, (_DissolveTilingRemapValue).xy, 1.0, 0 );
			float temp_output_7_0_g19 = (( (float)temp_output_4_0_g19 == 0.0 ) ? triplanar237.x :  triplanar237.y );
			float temp_output_12_0_g19 = (( (float)temp_output_4_0_g19 == 2.0 ) ? triplanar237.z :  temp_output_7_0_g19 );
			float temp_output_3_0_g23 = (( (float)temp_output_4_0_g19 == 3.0 ) ? triplanar237.w :  temp_output_12_0_g19 );
			float temp_output_275_0 = (_DissolveTilingRemapValue.z + ((( _GlobalValue )?( BossDissolve ):( _Value )) - 0.0) * (_DissolveTilingRemapValue.w - _DissolveTilingRemapValue.z) / (1.0 - 0.0));
			float temp_output_257_0 = max( _TriplanarDissolvelGradientBorder , 0.05 );
			float temp_output_4_0_g23 = temp_output_257_0;
			float temp_output_6_0_g23 = (-temp_output_4_0_g23 + (temp_output_275_0 - 0.0) * (( temp_output_4_0_g23 + 1.0 ) - -temp_output_4_0_g23) / (1.0 - 0.0));
			float temp_output_9_0_g23 = ( temp_output_6_0_g23 - temp_output_4_0_g23 );
			float temp_output_2_0_g25 = temp_output_9_0_g23;
			float temp_output_11_0_g23 = ( temp_output_6_0_g23 + temp_output_4_0_g23 );
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float temp_output_3_0_g20 = saturate( (0.0 + (( ase_vertex3Pos.y + _TriplanarVerticalGradientMinMaxOffset.z ) - _TriplanarVerticalGradientMinMaxOffset.x) * (1.0 - 0.0) / (_TriplanarVerticalGradientMinMaxOffset.y - _TriplanarVerticalGradientMinMaxOffset.x)) );
			float temp_output_4_0_g20 = temp_output_257_0;
			float temp_output_6_0_g20 = (-temp_output_4_0_g20 + (temp_output_275_0 - 0.0) * (( temp_output_4_0_g20 + 1.0 ) - -temp_output_4_0_g20) / (1.0 - 0.0));
			float temp_output_9_0_g20 = ( temp_output_6_0_g20 - temp_output_4_0_g20 );
			float temp_output_2_0_g22 = temp_output_9_0_g20;
			float temp_output_11_0_g20 = ( temp_output_6_0_g20 + temp_output_4_0_g20 );
			float temp_output_249_0 = saturate( ( ( temp_output_3_0_g20 - temp_output_2_0_g22 ) / ( temp_output_11_0_g20 - temp_output_2_0_g22 ) ) );
			float temp_output_273_0 = ( saturate( ( ( temp_output_3_0_g23 - temp_output_2_0_g25 ) / ( temp_output_11_0_g23 - temp_output_2_0_g25 ) ) ) * temp_output_249_0 );
			float temp_output_1_0_g26 = temp_output_273_0;
			float temp_output_8_0_g26 = step( ( temp_output_27_0_g26 - temp_output_3_0_g26 ) , temp_output_1_0_g26 );
			float temp_output_5_0_g26 = step( temp_output_27_0_g26 , temp_output_1_0_g26 );
			float4 BorderMask227 = ( _DissolveBorderColor * saturate( ( temp_output_8_0_g26 - temp_output_5_0_g26 ) ) );
			o.Emission = BorderMask227.rgb;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				UnityGI gi;
				UNITY_INITIALIZE_OUTPUT( UnityGI, gi );
				o.Alpha = LightingStandardCustomLighting( o, worldViewDir, gi ).a;
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17402
2245;38;1279;959;4705.892;4168.664;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;81;-5258.795,2701.032;Inherit;False;2242.203;843.1564;Comment;17;83;67;17;46;19;61;16;63;62;69;66;73;74;49;48;47;165;Base Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-5012.565,3361.689;Inherit;False;Property;_Tiling;Tiling;7;0;Create;True;0;0;False;1;Header(Overall Tex);1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-4779.794,3335.943;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-4357.794,3398.943;Inherit;False;Property;_FallOff;FallOff;8;0;Create;True;0;0;False;0;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-4601.682,3335.188;Inherit;False;Tiling;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-4224.682,3402.188;Inherit;False;TriplanarFallOffg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-3771.079,2751.032;Inherit;False;Property;_BaseColorType;BaseColor Type;9;1;[Enum];Create;True;3;Color;0;Texture;1;Triplanar;2;0;False;2;Header(Base Color);;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;82;-6330.826,-1094.389;Inherit;False;1730.243;477.6984;Comment;11;75;76;70;27;59;68;24;94;93;45;14;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-6280.826,-1044.389;Inherit;True;Property;_NormalTex;NormalTex;13;1;[Normal];Create;True;0;0;False;0;ea423bfa3028414449f0585c59cb25c5;7d008090ba9f10143a51e64dcd13849e;True;bump;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;69;-3581.769,2751.372;Inherit;False;DisplayType;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-6166.845,-863.3413;Inherit;False;Property;_NormalScale;NormalScale;14;0;Create;True;0;0;False;1;Space(20);1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;-6172.361,-717.4608;Inherit;False;74;TriplanarFallOffg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;-6176.173,-795.1467;Inherit;False;73;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;-5578.334,-966.7823;Inherit;False;69;DisplayType;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;93;-5847.821,-890.9803;Inherit;False;Blend World and NormalTex;-1;;15;a41941b1668fdfa4886041bd0a82573b;1,16,1;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;168;-6747.615,865.6872;Inherit;False;881.2809;354.0424;Comment;5;173;172;171;170;169;L;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;94;-5844.867,-1028.353;Inherit;False;Blend World and NormalTex;-1;;16;a41941b1668fdfa4886041bd0a82573b;1,16,0;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceLightPos;169;-6697.615,1084.731;Inherit;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.TexCoordVertexDataNode;62;-4659.07,3151.85;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;24;-5392.615,-797.8915;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;172;-6692.624,914.1416;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;68;-5405.226,-955.9498;Inherit;False;Switch Vector;-1;;17;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;170;-6456.563,927.7354;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-4382.374,3210.935;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;59;-5080.671,-880.4727;Inherit;False;Property;_UseMeshNormal;Use Mesh Normal;12;0;Create;True;0;0;False;1;Header(Normal);0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.NormalizeNode;171;-6293.912,915.6871;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-4773.262,-879.6666;Inherit;False;WorldNormal;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-4298.999,2949.674;Inherit;True;Property;_BaseColor;BaseColor;10;0;Create;True;0;0;False;0;da342a520889920408bdfa1aab8f912d;380080585a1d8fe40bf49c90d3cf127f;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-4251.923,3204.693;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-6037.35,600.7868;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;173;-6168.335,1051.031;Inherit;False;Property;_Keyword0;Keyword 0;0;0;Create;True;0;0;False;0;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;17;-3946.63,2784.162;Inherit;False;Property;_MainColor;Main Color;11;0;Create;False;0;0;False;0;1,0.3537736,0.3537736,0;0.9528301,0.8001212,0.2561854,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TriplanarNode;46;-3992.795,3168.943;Inherit;True;Spherical;World;False;Top Texture 2;_TopTexture2;white;-1;None;Mid Texture 2;_MidTexture2;white;-1;None;Bot Texture 2;_BotTexture2;white;-1;None;Triplanar Sampler;False;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;19;-4030.665,2962.701;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;67;-3527.079,2986.032;Inherit;False;Switch Vector;-1;;18;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DotProductOpNode;3;-5834.023,631.0428;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-5617.15,620.2428;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;127;-6023.427,-2300.76;Inherit;False;2679.096;1018.77;;22;150;145;141;140;133;144;139;136;147;138;146;137;131;151;149;148;193;205;206;208;213;214;Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.ComponentMaskNode;165;-3345.598,3192.536;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;164;-3157.153,3195.001;Inherit;False;AlbedoAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;213;-5975.213,-2201.592;Inherit;True;Property;_GlossMap;GlossMap;18;0;Create;True;0;0;False;0;None;None;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;214;-5916.639,-2016.948;Inherit;False;61;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;149;-5883.525,-2209.227;Inherit;False;1393.177;372.9427;e;7;163;134;135;108;99;107;166;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-5908.08,1028.539;Inherit;False;LightDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;7;-5242.783,-325.8135;Inherit;True;Property;_GradientMainLight;GradientMainLight;3;0;Create;True;0;0;False;1;Header(Toonificator);e6a5d6275c9d36549938f1ca543838a5;c94667fabf22d024883f43d404d2ac07;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.TexturePropertyNode;52;-5261.35,352.6472;Inherit;True;Property;_GradientOtherLights;GradientOtherLights;4;0;Create;True;0;0;False;0;da342a520889920408bdfa1aab8f912d;4c5da171e688edf4f810f05d6d66771d;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;-5293.985,620.2397;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;148;-4351.722,-2212.889;Inherit;False;586.4131;396.9957;H;7;126;125;129;124;128;189;190;;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;-4308.72,-2157.01;Inherit;False;188;LightDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-5675.951,-1971.087;Inherit;False;164;AlbedoAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-4955,635.7177;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;115;-4403.271,360.4275;Inherit;False;Property;_MaxGradient;MaxGradient;6;0;Create;True;0;0;False;1;Space(20);1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;56;-4949.518,375.0251;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;114;-4488.428,211.9059;Inherit;False;Property;_MinGradient;MinGradient;5;0;Create;True;0;0;False;0;0;0.124;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;107;-5744.989,-2159.227;Inherit;True;Property;_GlossTex;GlossTex;13;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;190;-4160.269,-2148.175;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;57;-4604.625,365.9621;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;215;-5372.189,-1424.13;Inherit;True;Property;_MetalMap;MetalMap;27;0;Create;True;0;0;False;0;None;184601dfc51948b45b09a2b7b0b651dc;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;99;-5306.298,-1967.04;Inherit;False;Property;_Smoothness;Smoothness;15;0;Create;True;0;0;False;1;Header(Glossiness);0.5;0.425;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-5038.97,-1220.712;Inherit;False;Property;_Metalness;Metalness;23;0;Create;True;0;0;False;1;Header(Metalness);0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;217;-5316.189,-1198.13;Inherit;False;61;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;116;-4176.425,208.1058;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;163;-5310.082,-2126.343;Inherit;False;Property;_GlossInAlbedoAlpha;GlossInAlbedoAlpha;22;0;Create;True;0;0;False;0;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;58;-4649.249,637.0026;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;124;-4256.863,-2003.893;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-5022.749,-2070.387;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;12;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;205;-4712.686,-1374.176;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;125;-4061.53,-2065.975;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-4067.23,247.906;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.001;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;55;-4351.444,481.2981;Inherit;False;Property;_Keyword0;Keyword 0;12;0;Create;True;0;0;False;0;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;216;-5097.189,-1425.13;Inherit;True;Property;_TextureSample4;Texture Sample 4;26;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;218;-4511.225,-1407.89;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;113;-3960.428,311.9059;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-3937.162,-1895.621;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.NormalizeNode;126;-3937.302,-2054.583;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Exp2OpNode;135;-4837.902,-2069.563;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;131;-3746.143,-2022.459;Inherit;False;202;185;;1;130;NdotH;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-4369.334,-1394.578;Inherit;False;Metalness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;134;-4714.348,-2075.401;Inherit;False;e;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;185;-3746.082,206.3301;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;130;-3696.143,-1972.459;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-3984.47,551.3463;Inherit;False;151;Metalness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-3289.48,2968.566;Inherit;False;BaseColor;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;186;-3491.111,187.7445;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-5114.978,-1613.872;Inherit;False;134;e;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-3536.132,-1976.326;Inherit;False;NdotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;153;-3814.882,557.6832;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-3961.499,468.6038;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;147;-5135.512,-1714.28;Inherit;False;146;NdotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-4893.539,-1565.043;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.125;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-3287.95,186.2898;Inherit;False;NdotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-4737.435,-1553.142;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3529.993,494.9496;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PowerNode;136;-4921.285,-1699.727;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;-5148.376,-1541.764;Inherit;False;104;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;236;-4455.853,-4395.312;Inherit;False;3855.544;971.2129;Comment;29;267;222;224;254;221;227;232;228;167;233;269;234;268;249;265;257;223;237;226;263;256;262;272;273;274;275;276;278;279;OpacityMask;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;248;-5274.935,-3950.795;Inherit;False;743.2527;459.959;Comment;5;247;241;246;239;258;VerticalGradientRemap;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-3252.778,565.9901;Inherit;False;Diffuse;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector3Node;258;-5209.983,-3875.569;Inherit;False;Property;_TriplanarVerticalGradientMinMaxOffset;TriplanarVerticalGradientMinMaxOffset;34;0;Create;True;0;0;False;0;0,0,0;0,2.23,1.25;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;206;-4241.976,-1730.101;Inherit;False;Property;_SmoothnessMultiplier;SmoothnessMultiplier;16;0;Create;True;0;0;False;0;1;0.58;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;239;-5224.935,-3711.083;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;140;-4602.288,-1668.601;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;262;-4369.417,-4270.82;Inherit;False;Property;_DissolveTilingRemapValue;DissolveTilingRemapValue;32;0;Create;True;0;0;False;0;0,0,0,0;1,1,0.069,0.41;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;246;-5016.748,-3657.697;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;226;-4381.811,-4073.213;Inherit;True;Property;_DissolveTexture;DissolveTexture;28;0;Create;True;0;0;False;1;Header(Dissolve);358f2b2518e507e4da371639cb74e406;21e963bfee72a604d819126999fd5ccf;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-4309.352,-1475.765;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;278;-4426.892,-3749.664;Inherit;False;Global;BossDissolve;BossDissolve;37;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;-3985.325,-1717.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;223;-4409.735,-3825.595;Inherit;False;Property;_Value;Value;30;0;Create;True;0;0;False;0;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;263;-4112.355,-4234.966;Inherit;False;True;True;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;276;-4128.189,-3788.622;Inherit;False;Property;_GlobalValue;GlobalValue;37;0;Create;True;0;0;False;0;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;-4323.27,-3546.36;Inherit;False;Property;_TriplanarDissolvelGradientBorder;TriplanarDissolvelGradientBorder;33;0;Create;True;0;0;False;0;0;0.77;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;141;-4099.382,-1487.272;Inherit;False;3;0;FLOAT4;0.05,0.05,0.05,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;208;-3833.739,-1710.885;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;241;-4851.203,-3703.443;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;237;-3858.383,-4202.839;Inherit;True;Spherical;World;False;Top Texture 3;_TopTexture3;white;-1;None;Mid Texture 3;_MidTexture3;white;-1;None;Bot Texture 3;_BotTexture3;white;-1;None;Triplanar Sampler;False;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;2,2;False;4;FLOAT;0.5;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.IntNode;265;-3757.44,-4332.333;Inherit;False;Property;_DissolveChannel;DissolveChannel;35;1;[Enum];Create;True;4;R;0;G;1;B;2;A;3;0;False;0;0;2;0;1;INT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;145;-3883.294,-1549.51;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TFHCRemapNode;275;-4013.889,-3935.422;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;247;-4675.947,-3705.297;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;268;-3446.802,-4203.487;Inherit;False;Switch;-1;;19;ef8df9ee20085f74db0149565f949658;5,28,0,30,0,29,0,15,0,9,2;17;4;INT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;257;-3974.344,-3629.095;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;249;-3568.174,-3753.279;Inherit;True;Gradient Filler;-1;;20;c122245c5a2a9fa42a229f3b2183f655;1,15,0;3;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;272;-3545.944,-3997.224;Inherit;True;Gradient Filler;-1;;23;c122245c5a2a9fa42a229f3b2183f655;1,15,0;3;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.25;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;150;-3610.463,-1539.372;Inherit;False;Specular;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;235;-3313.361,1400.9;Inherit;False;2258.359;1018.617;Comment;25;155;154;211;6;180;212;5;11;161;198;156;159;157;160;158;177;178;174;176;175;162;181;182;183;184;Final Output;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;211;-3241.379,1863.134;Inherit;False;Property;_MaxGlossiness;MaxGlossiness;17;0;Create;True;0;0;False;0;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;273;-3155.782,-3923.112;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-3263.361,1713.841;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;155;-3248.136,1794.75;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RelayNode;274;-2230.097,-3874.977;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;234;-1973.002,-3853.522;Inherit;False;Property;_BorderMask;BorderMask;31;0;Create;True;0;0;False;0;0.05;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;6;-2994.857,1919.239;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.RangedFloatNode;269;-2114.006,-4229.021;Inherit;False;Property;_StepValue;StepValue;36;0;Create;True;0;0;False;0;0;0.805;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;180;-2996.893,1724.125;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LightAttenuation;5;-3046.181,2025.919;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;212;-3014.685,1800.328;Inherit;False;3;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;1,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;-2438.174,2047.971;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;233;-1664.336,-4001.964;Inherit;True;MaskAndBorder;0;;26;9293e3882682a034aad4a12404095a1a;1,23,1;3;1;FLOAT;0;False;2;FLOAT;0.05;False;3;FLOAT;0.05;False;2;FLOAT;9;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;156;-2724.577,1796.328;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-2731.864,1925.214;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;198;-2528.786,2123.17;Inherit;False;Property;_AmbientLightInfluence;AmbientLight Influence;25;0;Create;True;0;0;False;0;0.2;0.257;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;159;-2512.209,1969.212;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-2562.461,1869.334;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;160;-2231.005,2005.145;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;-1436.338,-4167.475;Inherit;False;Debug;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-2072.089,1877.971;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-1881.677,2068.785;Inherit;False;167;Debug;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;176;-1965.75,1549.026;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-1960.75,1616.026;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;228;-1657.585,-4360.011;Inherit;False;Property;_DissolveBorderColor;DissolveBorderColor;29;1;[HDR];Create;True;0;0;False;0;1,1,1,0;1.500617,1.034908,2.639016,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;174;-1998.288,1450.9;Inherit;False;Property;_OutputSelection;Output Selection;24;1;[Enum];Create;True;4;Total;0;Diffuse;1;Specular;2;Debug;3;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;232;-1260.873,-3913.929;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;175;-1670.96,1776.608;Inherit;False;Switch;-1;;27;ef8df9ee20085f74db0149565f949658;5,28,3,30,3,29,3,15,3,9,2;17;4;FLOAT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;227;-1142.179,-3921.518;Inherit;False;BorderMask;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;221;-1249.484,-4019.779;Inherit;False;DissolveMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;-1279.001,1779.294;Inherit;False;Output;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;2;-6355.027,454.8681;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.OneMinusNode;204;-5606.669,956.3811;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;35;-2389.385,-1993.187;Inherit;False;Property;_FresnelInfo;FresnelInfo;19;0;Create;True;0;0;False;0;0,0,0;0,1.04,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;30;-2293.437,-2142.009;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ToggleSwitchNode;203;-5390.867,765.2813;Inherit;False;Property;_InvertGradient;Invert Gradient;26;0;Create;True;0;0;False;0;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;181;-2070.194,2195.517;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;37;-1136.348,-1539.482;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;196;-4205.586,-2436.263;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;44;-815.368,-1964.386;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-2753.217,1078.544;Inherit;False;40;FresnelMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-1394.545,-1683.339;Inherit;False;Property;_FresnelStep;FresnelStep;20;0;Create;True;0;0;False;0;0;0.375;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;572.8715,389.974;Inherit;False;167;Debug;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;26;-2155.006,-1951.47;Inherit;False;Standard;WorldNormal;ViewDir;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;36;-1624.545,-1683.339;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;31;-1502.071,-2274.753;Inherit;True;Property;_TextureSample2;Texture Sample 2;5;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-587.2805,-1977.032;Inherit;False;FresnelMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;129;-4301.722,-2162.89;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;193;-4648.221,-2416.938;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TFHCCompareEqual;279;-4252.892,-3642.664;Inherit;False;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;195;-4363.749,-2517.139;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LerpOp;267;-2751.438,-3963.725;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;22;558.765,312.3562;Inherit;False;162;Output;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;43;-1262.809,-1904.249;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;34;-1941.582,-1940.68;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;194;-4657.626,-2554.163;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;33;-1731.143,-1941.905;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;187;-5708.203,555.8374;Inherit;False;NdotLpreToon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;184;-2401.998,2212.517;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;254;-2470.479,-4023.383;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;183;-2557.997,2209.317;Inherit;False;104;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;224;-2056.909,-4113.971;Inherit;True;InverseLerp;-1;;28;7edf33933dd9e13498bc7ad3635ab6f9;0;3;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;222;-2266.993,-4055.716;Inherit;False;Constant;_Float1;Float 1;17;0;Create;True;0;0;False;0;0.75;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;39;-1077.682,-1942.024;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;229;565.1571,110.2905;Inherit;False;227;BorderMask;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-1528.809,-1900.249;Inherit;False;Property;_FresnelShadowing;FresnelShadowing;21;0;Create;True;0;0;False;0;0;0.955;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;182;-2226.096,2214.417;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;553.6463,237.2272;Inherit;False;221;DissolveMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;768.5718,61.5391;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;TFE/Toon/Lightning PBR Dissolve;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;True;Opaque;;AlphaTest;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.02;0,0,0,0;VertexOffset;False;False;Cylindrical;False;Relative;0;;2;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;49;0;47;0
WireConnection;49;1;47;0
WireConnection;73;0;49;0
WireConnection;74;0;48;0
WireConnection;69;0;66;0
WireConnection;93;13;76;0
WireConnection;93;10;14;0
WireConnection;93;11;45;0
WireConnection;93;19;75;0
WireConnection;94;13;76;0
WireConnection;94;10;14;0
WireConnection;94;11;45;0
WireConnection;68;4;70;0
WireConnection;68;2;94;0
WireConnection;68;3;94;0
WireConnection;68;5;93;0
WireConnection;170;0;169;1
WireConnection;170;1;172;0
WireConnection;63;0;62;0
WireConnection;63;1;73;0
WireConnection;59;0;68;0
WireConnection;59;1;24;0
WireConnection;171;0;170;0
WireConnection;27;0;59;0
WireConnection;61;0;63;0
WireConnection;173;1;171;0
WireConnection;173;0;169;1
WireConnection;46;0;16;0
WireConnection;46;3;73;0
WireConnection;46;4;74;0
WireConnection;19;0;16;0
WireConnection;19;1;61;0
WireConnection;67;4;69;0
WireConnection;67;2;17;0
WireConnection;67;3;19;0
WireConnection;67;5;46;0
WireConnection;3;0;28;0
WireConnection;3;1;173;0
WireConnection;4;0;3;0
WireConnection;165;0;67;0
WireConnection;164;0;165;0
WireConnection;188;0;173;0
WireConnection;9;0;4;0
WireConnection;8;0;7;0
WireConnection;8;1;9;0
WireConnection;56;0;52;0
WireConnection;56;1;9;0
WireConnection;107;0;213;0
WireConnection;107;1;214;0
WireConnection;190;0;189;0
WireConnection;57;0;56;0
WireConnection;116;0;114;0
WireConnection;116;1;115;0
WireConnection;163;0;107;1
WireConnection;163;1;166;0
WireConnection;58;0;8;0
WireConnection;108;0;163;0
WireConnection;108;2;99;0
WireConnection;205;2;142;0
WireConnection;125;0;190;0
WireConnection;125;1;124;0
WireConnection;117;0;116;0
WireConnection;55;1;57;0
WireConnection;55;0;58;0
WireConnection;216;0;215;0
WireConnection;216;1;217;0
WireConnection;218;0;216;1
WireConnection;218;1;205;0
WireConnection;113;0;55;0
WireConnection;113;3;114;0
WireConnection;113;4;117;0
WireConnection;126;0;125;0
WireConnection;135;0;108;0
WireConnection;151;0;218;0
WireConnection;134;0;135;0
WireConnection;185;0;113;0
WireConnection;130;0;126;0
WireConnection;130;1;128;0
WireConnection;83;0;67;0
WireConnection;186;0;185;0
WireConnection;146;0;130;0
WireConnection;153;0;152;0
WireConnection;138;0;137;0
WireConnection;104;0;186;0
WireConnection;139;0;138;0
WireConnection;20;0;113;0
WireConnection;20;1;84;0
WireConnection;20;2;153;0
WireConnection;136;0;147;0
WireConnection;136;1;137;0
WireConnection;21;0;20;0
WireConnection;140;0;136;0
WireConnection;140;1;139;0
WireConnection;140;2;133;0
WireConnection;246;0;239;2
WireConnection;246;1;258;3
WireConnection;207;0;206;0
WireConnection;207;1;140;0
WireConnection;263;0;262;0
WireConnection;276;0;223;0
WireConnection;276;1;278;0
WireConnection;141;1;144;0
WireConnection;141;2;151;0
WireConnection;208;0;140;0
WireConnection;208;1;207;0
WireConnection;208;2;163;0
WireConnection;241;0;246;0
WireConnection;241;1;258;1
WireConnection;241;2;258;2
WireConnection;237;0;226;0
WireConnection;237;3;263;0
WireConnection;145;0;208;0
WireConnection;145;1;141;0
WireConnection;275;0;276;0
WireConnection;275;3;262;3
WireConnection;275;4;262;4
WireConnection;247;0;241;0
WireConnection;268;4;265;0
WireConnection;268;2;237;1
WireConnection;268;3;237;2
WireConnection;268;5;237;3
WireConnection;268;6;237;4
WireConnection;257;0;256;0
WireConnection;249;2;275;0
WireConnection;249;3;247;0
WireConnection;249;4;257;0
WireConnection;272;2;275;0
WireConnection;272;3;268;0
WireConnection;272;4;257;0
WireConnection;150;0;145;0
WireConnection;273;0;272;0
WireConnection;273;1;249;0
WireConnection;274;0;273;0
WireConnection;180;0;154;0
WireConnection;212;0;155;0
WireConnection;212;2;211;0
WireConnection;233;1;274;0
WireConnection;233;2;269;0
WireConnection;233;3;234;0
WireConnection;156;0;180;0
WireConnection;156;1;212;0
WireConnection;11;0;6;1
WireConnection;11;1;5;0
WireConnection;157;0;156;0
WireConnection;157;1;11;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;160;2;198;0
WireConnection;167;0;233;9
WireConnection;158;0;157;0
WireConnection;158;1;160;0
WireConnection;232;0;228;0
WireConnection;232;1;233;0
WireConnection;175;4;174;0
WireConnection;175;24;158;0
WireConnection;175;25;176;0
WireConnection;175;26;177;0
WireConnection;175;27;178;0
WireConnection;227;0;232;0
WireConnection;221;0;233;9
WireConnection;162;0;175;0
WireConnection;204;0;4;0
WireConnection;203;0;4;0
WireConnection;203;1;204;0
WireConnection;181;0;160;0
WireConnection;181;1;182;0
WireConnection;37;0;38;0
WireConnection;37;1;36;0
WireConnection;196;0;195;0
WireConnection;44;0;39;0
WireConnection;26;1;35;1
WireConnection;26;2;35;2
WireConnection;26;3;35;3
WireConnection;36;0;34;0
WireConnection;31;0;7;0
WireConnection;31;1;33;0
WireConnection;40;0;44;0
WireConnection;279;0;278;0
WireConnection;279;3;278;0
WireConnection;195;0;194;0
WireConnection;195;1;193;0
WireConnection;267;0;273;0
WireConnection;267;1;249;0
WireConnection;267;2;249;0
WireConnection;43;0;42;0
WireConnection;34;0;26;0
WireConnection;33;0;34;0
WireConnection;187;0;3;0
WireConnection;184;0;183;0
WireConnection;254;0;267;0
WireConnection;224;1;254;0
WireConnection;224;3;222;0
WireConnection;39;0;36;0
WireConnection;39;1;43;0
WireConnection;39;2;38;0
WireConnection;182;0;184;0
WireConnection;0;2;229;0
WireConnection;0;10;231;0
WireConnection;0;13;22;0
ASEEND*/
//CHKSM=352D29B9DAB9C83AAEBB747C29E11810C89EEEF6
// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TFE/Toon/GeneralToonLightning"
{
	Properties
	{
		[Header(Toonificator)]_GradientMainLight("GradientMainLight", 2D) = "white" {}
		_GradientOtherLights("GradientOtherLights", 2D) = "white" {}
		_MinGradient("MinGradient", Range( 0 , 1)) = 0
		[Space(20)]_MaxGradient("MaxGradient", Range( 0 , 1)) = 1
		[Header(Overall Tex)]_Tiling("Tiling", Float) = 1
		_FallOff("FallOff", Float) = 0.5
		[Enum(Color,0,Texture,1,Triplanar,2)][Header(Base Color)]_BaseColorType("BaseColor Type", Float) = 0
		_BaseColor("BaseColor", 2D) = "white" {}
		_Color0("Main Color", Color) = (1,0.3537736,0.3537736,0)
		[Header(Normal)][Toggle]_UseMeshNormal("Use Mesh Normal", Float) = 1
		[Normal]_NormalTex("NormalTex", 2D) = "bump" {}
		[Space(20)]_NormalScale("NormalScale", Float) = 1
		[Header(Glossiness)][Toggle]_UseGlossiness("Use Glossiness", Float) = 0
		_GlossTex("GlossTex", 2D) = "white" {}
		_GlossinessModification("GlossinessModification", Range( 0 , 1)) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
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
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
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

		uniform float _UseGlossiness;
		uniform sampler2D _GradientOtherLights;
		uniform float _UseMeshNormal;
		uniform float _BaseColorType;
		uniform sampler2D _NormalTex;
		uniform float _Tiling;
		uniform float _FallOff;
		uniform float _NormalScale;
		uniform sampler2D _GradientMainLight;
		uniform float _MinGradient;
		uniform float _MaxGradient;
		uniform sampler2D _BaseColor;
		uniform float4 _Color0;
		uniform sampler2D _GlossTex;
		SamplerState sampler_GlossTex;
		uniform float4 _GlossTex_ST;
		uniform float _GlossinessModification;


		inline float3 TriplanarSampling17_g11( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			xNorm.xyz  = half3( UnpackScaleNormal( xNorm, normalScale.y ).xy * float2(  nsign.x, 1.0 ) + worldNormal.zy, worldNormal.x ).zyx;
			yNorm.xyz  = half3( UnpackScaleNormal( yNorm, normalScale.x ).xy * float2(  nsign.y, 1.0 ) + worldNormal.xz, worldNormal.y ).xzy;
			zNorm.xyz  = half3( UnpackScaleNormal( zNorm, normalScale.y ).xy * float2( -nsign.z, 1.0 ) + worldNormal.xy, worldNormal.z ).xyz;
			return normalize( xNorm.xyz * projNormal.x + yNorm.xyz * projNormal.y + zNorm.xyz * projNormal.z );
		}


		inline float4 TriplanarSampling46( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = tex2D( topTexMap, tiling * worldPos.zy * float2(  nsign.x, 1.0 ) );
			yNorm = tex2D( topTexMap, tiling * worldPos.xz * float2(  nsign.y, 1.0 ) );
			zNorm = tex2D( topTexMap, tiling * worldPos.xy * float2( -nsign.z, 1.0 ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
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
			float DisplayType69 = _BaseColorType;
			float temp_output_4_0_g13 = DisplayType69;
			float2 appendResult49 = (float2(_Tiling , _Tiling));
			float2 Tiling73 = appendResult49;
			float2 temp_output_13_0_g11 = Tiling73;
			float TriplanarFallOffg74 = _FallOff;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float temp_output_11_0_g11 = _NormalScale;
			float3 triplanar17_g11 = TriplanarSampling17_g11( _NormalTex, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, temp_output_13_0_g11, temp_output_11_0_g11, 0 );
			float3 tanTriplanarNormal17_g11 = mul( ase_worldToTangent, triplanar17_g11 );
			float3 newWorldNormal4_g11 = normalize( (WorldNormalVector( i , tanTriplanarNormal17_g11 )) );
			float2 temp_output_13_0_g12 = Tiling73;
			float temp_output_11_0_g12 = _NormalScale;
			float3 newWorldNormal4_g12 = normalize( (WorldNormalVector( i , UnpackScaleNormal( tex2D( _NormalTex, ( temp_output_13_0_g12 * i.uv_texcoord ) ), temp_output_11_0_g12 ) )) );
			float3 temp_output_94_0 = newWorldNormal4_g12;
			float4 temp_output_7_0_g13 = ( temp_output_4_0_g13 == 0.0 ? float4( temp_output_94_0 , 0.0 ) : float4( temp_output_94_0 , 0.0 ) );
			float4 temp_output_12_0_g13 = ( temp_output_4_0_g13 == 0.0 ? float4( newWorldNormal4_g11 , 0.0 ) : temp_output_7_0_g13 );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float4 WorldNormal27 = (( _UseMeshNormal )?( float4( ase_normWorldNormal , 0.0 ) ):( temp_output_12_0_g13 ));
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult3 = dot( WorldNormal27 , float4( ase_worldlightDir , 0.0 ) );
			float2 appendResult9 = (float2((dotResult3*0.5 + 0.5) , 0.0));
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch55 = (tex2D( _GradientMainLight, appendResult9 )).rgb;
			#else
				float3 staticSwitch55 = (tex2D( _GradientOtherLights, appendResult9 )).rgb;
			#endif
			float3 temp_cast_5 = (_MinGradient).xxx;
			float3 temp_cast_6 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			UnityGI gi12 = gi;
			float3 diffNorm12 = WorldNormal27.xyz;
			gi12 = UnityGI_Base( data, 1, diffNorm12 );
			float3 indirectDiffuse12 = gi12.indirect.diffuse + diffNorm12 * 0.0001;
			float temp_output_4_0_g14 = DisplayType69;
			float4 triplanar46 = TriplanarSampling46( _BaseColor, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, Tiling73, 1.0, 0 );
			float2 UV61 = ( i.uv_texcoord * Tiling73 );
			float4 temp_output_7_0_g14 = ( temp_output_4_0_g14 == 0.0 ? _Color0 : tex2D( _BaseColor, UV61 ) );
			float4 temp_output_12_0_g14 = ( temp_output_4_0_g14 == 0.0 ? triplanar46 : temp_output_7_0_g14 );
			float4 BaseColor83 = temp_output_12_0_g14;
			float4 temp_output_20_0 = ( float4( ( ( (temp_cast_5 + (staticSwitch55 - float3( 0,0,0 )) * (temp_cast_6 - temp_cast_5) / (float3( 1,1,1 ) - float3( 0,0,0 ))) * ( ase_lightColor.rgb * ase_lightAtten ) ) + indirectDiffuse12 ) , 0.0 ) * BaseColor83 );
			float3 temp_cast_11 = (_MinGradient).xxx;
			float3 temp_cast_12 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float3 temp_output_8_0_g15 = WorldNormal27.xyz;
			float3 normalizeResult25_g15 = normalize( ( _WorldSpaceLightPos0.xyz - ase_worldPos ) );
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch18_g15 = _WorldSpaceLightPos0.xyz;
			#else
				float3 staticSwitch18_g15 = normalizeResult25_g15;
			#endif
			float3 normalizeResult23_g15 = normalize( ( _WorldSpaceCameraPos - ase_worldPos ) );
			float3 normalizeResult13_g15 = normalize( ( staticSwitch18_g15 + normalizeResult23_g15 ) );
			float dotResult15_g15 = dot( temp_output_8_0_g15 , normalizeResult13_g15 );
			float temp_output_5_0_g15 = dotResult15_g15;
			float2 uv_GlossTex = i.uv_texcoord * _GlossTex_ST.xy + _GlossTex_ST.zw;
			float temp_output_1_0_g15 = saturate( ( tex2D( _GlossTex, uv_GlossTex ).r * _GlossinessModification ) );
			float temp_output_30_0_g15 = pow( 2.0 , ( temp_output_1_0_g15 * 12.0 ) );
			float NdotL104 = dotResult3;
			float4 Debug21 = (( _UseGlossiness )?( ( temp_output_20_0 + ( pow( temp_output_5_0_g15 , temp_output_30_0_g15 ) * NdotL104 * ( ( temp_output_30_0_g15 * 0.125 ) + 1.0 ) ) ) ):( temp_output_20_0 ));
			c.rgb = Debug21.xyz;
			c.a = 1;
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
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows noshadow exclude_path:deferred 

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
Version=18500
356;73;1097;663;108.4087;-65.76599;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;81;-4110.222,1133.289;Inherit;False;1813.203;817.1564;Comment;14;48;49;66;74;73;69;17;61;62;63;46;67;16;19;Base Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-4257.073,1780.884;Inherit;False;Property;_Tiling;Tiling;4;0;Create;True;0;0;False;1;Header(Overall Tex);False;1;1.63;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-3638.221,1831.2;Inherit;False;Property;_FallOff;FallOff;5;0;Create;True;0;0;False;0;False;0.5;2.17;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-4060.221,1768.2;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-3505.109,1834.445;Inherit;False;TriplanarFallOffg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;82;-6330.826,-1094.389;Inherit;False;1721.563;668.6467;Comment;14;68;93;24;94;90;92;91;27;59;70;14;75;45;76;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-3882.109,1767.445;Inherit;False;Tiling;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-3051.505,1183.289;Inherit;False;Property;_BaseColorType;BaseColor Type;6;1;[Enum];Create;True;3;Color;0;Texture;1;Triplanar;2;0;False;2;Header(Base Color);;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-6280.826,-1044.389;Inherit;True;Property;_NormalTex;NormalTex;10;1;[Normal];Create;True;0;0;False;0;False;None;None;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;45;-6166.845,-863.3413;Inherit;False;Property;_NormalScale;NormalScale;11;0;Create;True;0;0;False;1;Space(20);False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;-6142.777,-683.8398;Inherit;False;74;TriplanarFallOffg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;69;-2862.195,1183.629;Inherit;False;DisplayType;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;-6188.276,-770.9399;Inherit;False;73;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;-5820.334,-607.7823;Inherit;False;69;DisplayType;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;93;-5847.821,-890.9803;Inherit;False;Blend World and NormalTex;-1;;11;a41941b1668fdfa4886041bd0a82573b;1,16,1;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;94;-5844.867,-1028.353;Inherit;False;Blend World and NormalTex;-1;;12;a41941b1668fdfa4886041bd0a82573b;1,16,0;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;24;-5392.615,-797.8915;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;68;-5405.226,-955.9498;Inherit;False;Switch Vector;-1;;13;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ToggleSwitchNode;59;-5080.671,-880.4727;Inherit;False;Property;_UseMeshNormal;Use Mesh Normal;9;0;Create;True;0;0;False;1;Header(Normal);False;1;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-4833.262,-879.6666;Inherit;False;WorldNormal;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-5832.658,595.1692;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;2;-5867.092,720.3063;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;3;-5659.317,635.8075;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-5497.744,638.4426;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;7;-5251.608,-219.9308;Inherit;True;Property;_GradientMainLight;GradientMainLight;0;0;Create;True;0;0;False;1;Header(Toonificator);False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;52;-5261.35,352.6472;Inherit;True;Property;_GradientOtherLights;GradientOtherLights;1;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexCoordVertexDataNode;62;-3939.497,1584.107;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;9;-5297.185,642.6396;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;115;-4396.428,404.9059;Inherit;False;Property;_MaxGradient;MaxGradient;3;0;Create;True;0;0;False;1;Space(20);False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;56;-4949.518,375.0251;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;8;-4981.704,635.7177;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;114;-4488.428,211.9059;Inherit;False;Property;_MinGradient;MinGradient;2;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-3662.801,1643.192;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-3579.426,1381.931;Inherit;True;Property;_BaseColor;BaseColor;7;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-3532.351,1636.95;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComponentMaskNode;57;-4604.625,365.9621;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;116;-4150.428,254.9059;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;58;-4688.415,667.2692;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-4020.428,221.9059;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.001;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;5;-4256.562,847.4258;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;6;-4275.457,671.3564;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SamplerNode;19;-3311.091,1394.958;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;17;-3324.658,1206.818;Inherit;False;Property;_Color0;Main Color;8;0;Create;False;0;0;False;0;False;1,0.3537736,0.3537736,0;0.3545746,0.8813478,0.9056604,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;55;-4325.444,511.1978;Inherit;False;Property;_Keyword0;Keyword 0;12;0;Create;True;0;0;False;0;False;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TriplanarNode;46;-3273.221,1601.2;Inherit;True;Spherical;World;False;Top Texture 2;_TopTexture2;white;-1;None;Mid Texture 2;_MidTexture2;white;-1;None;Bot Texture 2;_BotTexture2;white;-1;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;99;-3100.906,1002.271;Inherit;False;Property;_GlossinessModification;GlossinessModification;14;0;Create;True;0;0;False;0;False;0.5;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;113;-3960.428,311.9059;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;107;-3135.106,806.9275;Inherit;True;Property;_GlossTex;GlossTex;13;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-4041.498,697.5753;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;67;-2807.505,1418.289;Inherit;False;Switch Vector;-1;;14;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;29;-3082.615,627.5382;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-5546.512,510.4734;Inherit;False;NdotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-2533.987,1387.762;Inherit;False;BaseColor;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-2550.656,977.829;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;12;-2866.391,630.8075;Inherit;False;World;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-3675.859,509.4869;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;105;-2262.993,1108.916;Inherit;False;104;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;100;-2278.38,1174.806;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;111;-2387.339,976.7335;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;15;-2474.093,535.4513;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-2430.424,678.6377;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-2044.286,550.071;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;106;-2084.356,1096.763;Inherit;False;GetGlossiness;-1;;15;62e5dc4f9ea737545928ae51607e1e26;0;4;1;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;8;FLOAT3;0,0,0;False;2;FLOAT;0;FLOAT;6
Node;AmplifyShaderEditor.SimpleAddOpNode;109;-1886.138,907.7314;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ToggleSwitchNode;112;-1745.384,882.8477;Inherit;False;Property;_UseGlossiness;Use Glossiness;12;0;Create;True;0;0;False;1;Header(Glossiness);False;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-1490.341,890.1956;Inherit;False;Debug;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;44;-844.0277,-474.1997;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;43;-1291.469,-414.0627;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;36;-1653.205,-193.1522;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-2322.096,-651.8225;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FresnelNode;26;-2183.665,-461.2834;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-1759.803,-451.7182;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-615.9402,-486.8458;Inherit;False;FresnelMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;42;-1557.469,-410.0627;Inherit;False;Property;_FresnelShadowing;FresnelShadowing;17;0;Create;True;0;0;False;0;False;0;0.955;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-1423.205,-193.1522;Inherit;False;Property;_FresnelStep;FresnelStep;16;0;Create;True;0;0;False;0;False;0;0.375;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;37;-1165.008,-49.29542;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;91;-6243.486,-572.7458;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;22;597.3269,299.3369;Inherit;False;21;Debug;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SaturateNode;34;-1970.242,-450.4933;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;39;-1106.342,-451.8373;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-2818.674,746.2183;Inherit;False;40;FresnelMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;90;-5774.445,-737.4641;Inherit;True;Property;_TextureSample4;Texture Sample 4;14;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;35;-2358.275,-443.2307;Inherit;False;Property;_FresnelInfo;FresnelInfo;15;0;Create;True;0;0;False;0;False;0,0,0;0,1.04,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;31;-1536.731,-779.5664;Inherit;True;Property;_TextureSample2;Texture Sample 2;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-5962.687,-597.4459;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;768.5718,61.5391;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;TFE/Toon/GeneralToonLightning;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.02;0,0,0,0;VertexOffset;False;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;49;0;47;0
WireConnection;49;1;47;0
WireConnection;74;0;48;0
WireConnection;73;0;49;0
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
WireConnection;59;0;68;0
WireConnection;59;1;24;0
WireConnection;27;0;59;0
WireConnection;3;0;28;0
WireConnection;3;1;2;0
WireConnection;4;0;3;0
WireConnection;9;0;4;0
WireConnection;56;0;52;0
WireConnection;56;1;9;0
WireConnection;8;0;7;0
WireConnection;8;1;9;0
WireConnection;63;0;62;0
WireConnection;63;1;73;0
WireConnection;61;0;63;0
WireConnection;57;0;56;0
WireConnection;116;0;114;0
WireConnection;116;1;115;0
WireConnection;58;0;8;0
WireConnection;117;0;116;0
WireConnection;19;0;16;0
WireConnection;19;1;61;0
WireConnection;55;1;57;0
WireConnection;55;0;58;0
WireConnection;46;0;16;0
WireConnection;46;3;73;0
WireConnection;46;4;74;0
WireConnection;113;0;55;0
WireConnection;113;3;114;0
WireConnection;113;4;117;0
WireConnection;11;0;6;1
WireConnection;11;1;5;0
WireConnection;67;4;69;0
WireConnection;67;2;17;0
WireConnection;67;3;19;0
WireConnection;67;5;46;0
WireConnection;104;0;3;0
WireConnection;83;0;67;0
WireConnection;108;0;107;1
WireConnection;108;1;99;0
WireConnection;12;0;29;0
WireConnection;25;0;113;0
WireConnection;25;1;11;0
WireConnection;111;0;108;0
WireConnection;15;0;25;0
WireConnection;15;1;12;0
WireConnection;20;0;15;0
WireConnection;20;1;84;0
WireConnection;106;1;111;0
WireConnection;106;4;105;0
WireConnection;106;8;100;0
WireConnection;109;0;20;0
WireConnection;109;1;106;6
WireConnection;112;0;20;0
WireConnection;112;1;109;0
WireConnection;21;0;112;0
WireConnection;44;0;39;0
WireConnection;43;0;42;0
WireConnection;36;0;34;0
WireConnection;26;1;35;1
WireConnection;26;2;35;2
WireConnection;26;3;35;3
WireConnection;33;0;34;0
WireConnection;40;0;44;0
WireConnection;37;0;38;0
WireConnection;37;1;36;0
WireConnection;34;0;26;0
WireConnection;39;0;36;0
WireConnection;39;1;43;0
WireConnection;39;2;38;0
WireConnection;90;0;14;0
WireConnection;90;1;92;0
WireConnection;90;5;45;0
WireConnection;31;0;7;0
WireConnection;31;1;33;0
WireConnection;92;0;76;0
WireConnection;92;1;91;0
WireConnection;0;13;22;0
ASEEND*/
//CHKSM=0CA300E9509F4F9A4A545DC9098D5D04916E087E
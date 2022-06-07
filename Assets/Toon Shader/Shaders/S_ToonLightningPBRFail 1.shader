// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TFE/Toon/Lightning PBR Fail"
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
		[Header(Normal)][Toggle]_UseMeshNormal("Use Mesh Normal", Float) = 0
		[Normal]_NormalTex("NormalTex", 2D) = "bump" {}
		[Space(20)]_NormalScale("NormalScale", Float) = 1
		_GlossTex("GlossTex", 2D) = "white" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		_Metalness("Metalness", Range( 0 , 1)) = 0
		[Toggle]_GlossInAlbedoAlpha("GlossInAlbedoAlpha", Float) = 1
		[Enum(Total,0,Diffuse,1,Specular,2,Debug,3)]_OutputSelection("Output Selection", Float) = 0
		_AmbientLightInfluence("AmbientLight Influence", Range( 0 , 0.5)) = 0.2
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
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

		uniform float _OutputSelection;
		uniform float _UseMeshNormal;
		uniform float _BaseColorType;
		uniform sampler2D _NormalTex;
		uniform float _Tiling;
		uniform float _FallOff;
		uniform float _NormalScale;
		uniform float _GlossInAlbedoAlpha;
		uniform sampler2D _GlossTex;
		uniform float4 _GlossTex_ST;
		uniform sampler2D _BaseColor;
		uniform float4 _Color0;
		uniform float _Smoothness;
		uniform sampler2D _GradientOtherLights;
		uniform sampler2D _GradientMainLight;
		uniform float _MinGradient;
		uniform float _MaxGradient;
		uniform float _Metalness;
		uniform float _AmbientLightInfluence;


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
			float temp_output_4_0_g17 = _OutputSelection;
			float3 ase_worldPos = i.worldPos;
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
			float dotResult206 = dot( normalizeResult190 , normalizeResult126 );
			float temp_output_242_0 = saturate( dotResult206 );
			float Debug167 = temp_output_242_0;
			float4 temp_cast_0 = (Debug167).xxxx;
			float DisplayType69 = _BaseColorType;
			float temp_output_4_0_g15 = DisplayType69;
			float2 appendResult49 = (float2(_Tiling , _Tiling));
			float2 Tiling73 = appendResult49;
			float2 temp_output_13_0_g18 = Tiling73;
			float TriplanarFallOffg74 = _FallOff;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float temp_output_11_0_g18 = _NormalScale;
			float3 triplanar17_g18 = TriplanarSamplingSNF( _NormalTex, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, temp_output_13_0_g18, temp_output_11_0_g18, 0 );
			float3 tanTriplanarNormal17_g18 = mul( ase_worldToTangent, triplanar17_g18 );
			float3 newWorldNormal4_g18 = normalize( (WorldNormalVector( i , tanTriplanarNormal17_g18 )) );
			float3 normalizeResult21_g18 = normalize( newWorldNormal4_g18 );
			float temp_output_11_0_g19 = _NormalScale;
			float2 temp_output_13_0_g19 = Tiling73;
			float3 newWorldNormal4_g19 = normalize( (WorldNormalVector( i , UnpackScaleNormal( tex2D( _NormalTex, ( temp_output_13_0_g19 * i.uv_texcoord ) ), temp_output_11_0_g19 ) )) );
			float3 normalizeResult21_g19 = normalize( newWorldNormal4_g19 );
			float3 temp_output_245_0 = normalizeResult21_g19;
			float4 temp_output_7_0_g15 = (( temp_output_4_0_g15 == 0.0 ) ? float4( temp_output_245_0 , 0.0 ) :  float4( temp_output_245_0 , 0.0 ) );
			float4 temp_output_12_0_g15 = (( temp_output_4_0_g15 == 2.0 ) ? float4( normalizeResult21_g18 , 0.0 ) :  temp_output_7_0_g15 );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float4 WorldNormal27 = (( _UseMeshNormal )?( float4( ase_normWorldNormal , 0.0 ) ):( temp_output_12_0_g15 ));
			float dotResult130 = dot( float4( normalizeResult126 , 0.0 ) , WorldNormal27 );
			float NdotHpreToon146 = saturate( dotResult130 );
			float2 uv_GlossTex = i.uv_texcoord * _GlossTex_ST.xy + _GlossTex_ST.zw;
			float temp_output_4_0_g16 = DisplayType69;
			float4 triplanar46 = TriplanarSamplingSF( _BaseColor, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, Tiling73, 1.0, 0 );
			float2 UV61 = ( i.uv_texcoord * Tiling73 );
			float4 temp_output_7_0_g16 = (( temp_output_4_0_g16 == 0.0 ) ? _Color0 :  tex2D( _BaseColor, UV61 ) );
			float4 temp_output_12_0_g16 = (( temp_output_4_0_g16 == 2.0 ) ? triplanar46 :  temp_output_7_0_g16 );
			float4 temp_output_67_0 = temp_output_12_0_g16;
			float AlbedoAlpha164 = (temp_output_67_0).w;
			float temp_output_108_0 = ( (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossTex, uv_GlossTex ).r )) * _Smoothness );
			float e134 = exp2( ( temp_output_108_0 * 12.0 ) );
			float dotResult3 = dot( WorldNormal27 , float4( staticSwitch173 , 0.0 ) );
			float temp_output_4_0 = (dotResult3*0.5 + 0.5);
			float2 appendResult9 = (float2(temp_output_4_0 , 0.0));
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch55 = (tex2D( _GradientMainLight, appendResult9 )).rgb;
			#else
				float3 staticSwitch55 = (tex2D( _GradientOtherLights, appendResult9 )).rgb;
			#endif
			float3 temp_cast_9 = (_MinGradient).xxx;
			float3 temp_cast_10 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float3 temp_output_113_0 = (temp_cast_9 + (staticSwitch55 - float3( 0,0,0 )) * (temp_cast_10 - temp_cast_9) / (float3( 1,1,1 ) - float3( 0,0,0 )));
			float4 BaseColor83 = temp_output_67_0;
			float lerpResult254 = lerp( 0.0 , 0.7 , _Metalness);
			float Metalness151 = lerpResult254;
			float4 Diffuse21 = ( float4( temp_output_113_0 , 0.0 ) * BaseColor83 * ( 1.0 - Metalness151 ) );
			float4 lerpResult141 = lerp( float4( 0.05,0.05,0.05,0 ) , Diffuse21 , Metalness151);
			float4 Specular150 = ( ( pow( NdotHpreToon146 , e134 ) * NdotHpreToon146 * ( ( e134 * 0.125 ) + 1.0 ) ) * lerpResult141 );
			float dotResult210 = dot( float4( ase_worldViewDir , 0.0 ) , (( _UseMeshNormal )?( float4( ase_normWorldNormal , 0.0 ) ):( temp_output_12_0_g15 )) );
			float NdotV212 = dotResult210;
			float Glossiness232 = temp_output_108_0;
			float3 _MinSpec = float3(0.05,0.05,0.05);
			float4 temp_output_218_0 = ( ( Metalness151 * ( BaseColor83 - float4( _MinSpec , 0.0 ) ) ) + float4( _MinSpec , 0.0 ) );
			float LdotHpretoon209 = temp_output_242_0;
			float temp_output_222_0 = ( 1.0 - LdotHpretoon209 );
			float temp_output_224_0 = ( temp_output_222_0 * temp_output_222_0 );
			float4 Fresnel40 = ( temp_output_218_0 + ( ( 1.0 - temp_output_218_0 ) * ( temp_output_224_0 * temp_output_224_0 ) ) );
			float4 FinalSpecular236 = ( ( ( NdotV212 * ( 1.0 - Glossiness232 ) ) + Glossiness232 ) * Specular150 * Fresnel40 );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 temp_output_7_0_g17 = (( temp_output_4_0_g17 == 0.0 ) ? ( ( ( saturate( Diffuse21 ) + saturate( FinalSpecular236 ) ) * float4( ( ase_lightColor.rgb * ase_lightAtten ) , 0.0 ) ) + ( UNITY_LIGHTMODEL_AMBIENT * BaseColor83 * _AmbientLightInfluence ) ) :  Diffuse21 );
			float4 temp_output_12_0_g17 = (( temp_output_4_0_g17 == 2.0 ) ? Specular150 :  temp_output_7_0_g17 );
			float4 Output162 = (( temp_output_4_0_g17 == 3.0 ) ? temp_cast_0 :  temp_output_12_0_g17 );
			c.rgb = Output162.xyz;
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
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows exclude_path:deferred 

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
Version=17402
240;73;1311;576;8470.784;3941.75;5.186131;True;False
Node;AmplifyShaderEditor.CommentaryNode;81;-5258.795,2701.032;Inherit;False;2242.203;843.1564;Comment;17;83;67;17;46;19;61;16;63;62;69;66;73;74;49;48;47;165;Base Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-5012.565,3361.689;Inherit;False;Property;_Tiling;Tiling;4;0;Create;True;0;0;False;1;Header(Overall Tex);1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-4779.794,3335.943;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-4357.794,3398.943;Inherit;False;Property;_FallOff;FallOff;5;0;Create;True;0;0;False;0;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-3771.079,2751.032;Inherit;False;Property;_BaseColorType;BaseColor Type;6;1;[Enum];Create;True;3;Color;0;Texture;1;Triplanar;2;0;False;2;Header(Base Color);;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-4224.682,3402.188;Inherit;False;TriplanarFallOffg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-4601.682,3335.188;Inherit;False;Tiling;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;82;-7944.607,-2368.721;Inherit;False;1730.243;477.6984;Comment;9;75;76;70;27;59;68;24;45;14;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;168;-6776.924,744.7913;Inherit;False;881.2809;354.0424;Comment;5;173;172;171;170;169;L;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;75;-7786.142,-1991.792;Inherit;False;74;TriplanarFallOffg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;-7789.954,-2069.478;Inherit;False;73;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-7894.607,-2318.721;Inherit;True;Property;_NormalTex;NormalTex;10;1;[Normal];Create;True;0;0;False;0;ea423bfa3028414449f0585c59cb25c5;0587dd26aaf801b40b0ce2fd1eb8bd34;True;bump;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;69;-3581.769,2751.372;Inherit;False;DisplayType;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;62;-4659.07,3151.85;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightPos;169;-6726.924,963.8355;Inherit;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.WorldPosInputsNode;172;-6721.933,793.2457;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;45;-7780.626,-2137.673;Inherit;False;Property;_NormalScale;NormalScale;11;0;Create;True;0;0;False;1;Space(20);1;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-4382.374,3210.935;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;-7192.115,-2241.114;Inherit;False;69;DisplayType;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;170;-6485.872,806.8395;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;244;-7461.602,-2165.312;Inherit;False;Blend World and NormalTex;-1;;18;a41941b1668fdfa4886041bd0a82573b;1,16,1;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;245;-7458.648,-2302.685;Inherit;False;Blend World and NormalTex;-1;;19;a41941b1668fdfa4886041bd0a82573b;1,16,0;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-4298.999,2949.674;Inherit;True;Property;_BaseColor;BaseColor;7;0;Create;True;0;0;False;0;da342a520889920408bdfa1aab8f912d;19a5f4582b7c2f2428d755bad78171b5;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.NormalizeNode;171;-6323.221,794.7911;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-4251.923,3204.693;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldNormalVector;24;-7006.396,-2072.223;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;68;-7019.007,-2230.282;Inherit;False;Switch Vector;-1;;15;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.StaticSwitch;173;-6197.644,930.1354;Inherit;False;Property;_Keyword0;Keyword 0;0;0;Create;True;0;0;False;0;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;59;-6694.452,-2154.804;Inherit;False;Property;_UseMeshNormal;Use Mesh Normal;9;0;Create;True;0;0;False;1;Header(Normal);0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;19;-4030.665,2962.701;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TriplanarNode;46;-3992.795,3168.943;Inherit;True;Spherical;World;False;Top Texture 2;_TopTexture2;white;-1;None;Mid Texture 2;_MidTexture2;white;-1;None;Bot Texture 2;_BotTexture2;white;-1;None;Triplanar Sampler;False;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;17;-3946.63,2784.162;Inherit;False;Property;_Color0;Main Color;8;0;Create;False;0;0;False;0;1,0.3537736,0.3537736,0;1,0.3537735,0.3537735,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;127;-5881.65,-2944.21;Inherit;False;2700.053;1047.587;;6;146;131;148;149;205;207;Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;148;-4215.833,-2852.414;Inherit;False;586.4131;396.9957;H;6;126;125;124;128;189;190;H;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;67;-3527.079,2986.032;Inherit;False;Switch Vector;-1;;16;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-5838.612,1050.566;Inherit;False;LightDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-6387.043,-2153.999;Inherit;False;WorldNormal;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-6131.79,617.6508;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;165;-3345.598,3192.536;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;189;-4200.469,-2790.535;Inherit;False;188;LightDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;164;-3157.153,3195.001;Inherit;False;AlbedoAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;149;-5741.749,-2852.677;Inherit;False;1378.777;354.6453;e;8;259;134;135;108;99;163;166;232;e;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalizeNode;190;-4024.379,-2787.7;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;124;-4189.974,-2639.418;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;3;-5834.023,631.0428;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-5617.15,620.2428;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-5735.206,-2624.698;Inherit;False;164;AlbedoAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;125;-3925.64,-2705.5;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;107;-5744.212,-2810.677;Inherit;True;Property;_GlossTex;GlossTex;12;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;205;-4695.194,-2443.087;Inherit;False;1453.507;522.8407;Comment;15;147;136;140;144;139;138;151;142;150;145;141;133;137;220;221;Output Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;99;-5417.708,-2687.93;Inherit;False;Property;_Smoothness;Smoothness;13;0;Create;True;0;0;False;0;0.5;0.784;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;52;-5261.35,352.6472;Inherit;True;Property;_GradientOtherLights;GradientOtherLights;1;0;Create;True;0;0;False;0;da342a520889920408bdfa1aab8f912d;c94667fabf22d024883f43d404d2ac07;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.NormalizeNode;126;-3801.412,-2694.108;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;7;-5610.599,383.7263;Inherit;True;Property;_GradientMainLight;GradientMainLight;0;0;Create;True;0;0;False;1;Header(Toonificator);e6a5d6275c9d36549938f1ca543838a5;93510be2925775f40956aa832ca742c9;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.ToggleSwitchNode;163;-5446.235,-2781.632;Inherit;False;Property;_GlossInAlbedoAlpha;GlossInAlbedoAlpha;15;0;Create;True;0;0;False;0;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;9;-5293.985,620.2397;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-4802.194,-2047.162;Inherit;False;Property;_Metalness;Metalness;14;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;56;-4949.518,375.0251;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;115;-4519.221,203.2775;Inherit;False;Property;_MaxGradient;MaxGradient;3;0;Create;True;0;0;False;1;Space(20);1;0.932;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-4955,635.7177;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;114;-4532.378,126.7559;Inherit;False;Property;_MinGradient;MinGradient;2;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;206;-3666.331,-3037.829;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-5074.209,-2770.145;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;12;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;254;-4517.556,-2061.631;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;229;-4749.903,-1831.45;Inherit;False;1430.615;580.4368;Comment;9;219;222;223;224;225;227;226;228;40;Fresnel;1,1,1,1;0;0
Node;AmplifyShaderEditor.ComponentMaskNode;57;-4638.126,381.8319;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-4357.625,-2036.246;Inherit;False;Metalness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;242;-3524.916,-3040.111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;259;-4920.157,-2773.966;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;12;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-3289.48,2968.566;Inherit;False;BaseColor;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-3801.272,-2535.146;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;131;-3610.253,-2661.984;Inherit;False;202;185;;1;130;NdotH;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;116;-4184.425,144.1058;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;58;-4649.249,637.0026;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;219;-4699.903,-1781.45;Inherit;False;873.6489;296.1309;Comment;5;214;215;216;218;213;F0;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;215;-4417.254,-1714.882;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DotProductOpNode;130;-3597.463,-2617.708;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-3984.47,551.3463;Inherit;False;151;Metalness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;209;-2876.37,-3045.078;Inherit;False;LdotHpretoon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;213;-4649.903,-1673.319;Inherit;False;Constant;_MinSpec;MinSpec;22;0;Create;True;0;0;False;0;0.05,0.05,0.05;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.StaticSwitch;55;-4385.058,474.4582;Inherit;False;Property;_Keyword0;Keyword 0;12;0;Create;True;0;0;False;0;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-4067.23,247.906;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.001;False;1;FLOAT;0
Node;AmplifyShaderEditor.Exp2OpNode;135;-4764.593,-2768.846;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;113;-3931.428,279.9059;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;207;-3420.269,-2597.588;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;223;-4660.111,-1417.013;Inherit;False;209;LdotHpretoon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-3961.499,468.6038;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;216;-4222.254,-1622.882;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;134;-4641.04,-2774.684;Inherit;False;e;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;153;-3814.882,557.6832;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-3271.356,-2612.813;Inherit;False;NdotHpreToon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-4588.194,-2320.379;Inherit;False;134;e;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-3666.698,389.9793;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;220;-4560.613,-2186.041;Inherit;False;Constant;_Float0;Float 0;22;0;Create;True;0;0;False;0;0.125;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;214;-4139.365,-1731.45;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;222;-4475.111,-1422.013;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-3299.784,365.2608;Inherit;False;Diffuse;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;147;-4574.729,-2413.787;Inherit;False;146;NdotHpreToon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;221;-4355.013,-2115.541;Inherit;False;Constant;_Float1;Float 1;22;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-4357.896,-2204.307;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.125;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;218;-3978.254,-1673.882;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;211;-6680.004,-2551.077;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;224;-4300.111,-1386.013;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;232;-4930.597,-2653.011;Inherit;False;Glossiness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;226;-3969.61,-1448.413;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DotProductOpNode;210;-6471.412,-2529.5;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;237;-4722.091,-1211.876;Inherit;False;994.2864;377.579;Comment;9;236;239;238;241;235;234;233;231;230;GeoVis + Final Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;225;-4147.111,-1399.013;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-4176.956,-2094.827;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-4177.076,-2201.933;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;136;-4325.001,-2403.168;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;212;-6331.151,-2536.692;Inherit;False;NdotV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;227;-3813.712,-1423.513;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;231;-4669.491,-1088.097;Inherit;False;232;Glossiness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;140;-4031.696,-2281.625;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;141;-3957.604,-2130.722;Inherit;False;3;0;FLOAT4;0.05,0.05,0.05,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;233;-4495.205,-1083.127;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;228;-3663.712,-1441.713;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;230;-4664.56,-1161.876;Inherit;False;212;NdotV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;145;-3741.517,-2192.96;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;150;-3596.507,-2193.107;Inherit;False;Specular;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-3543.29,-1443.298;Inherit;False;Fresnel;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;234;-4344.205,-1151.128;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;235;-4190.205,-1115.128;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;-4258.156,-1015.426;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;-4259.156,-942.4255;Inherit;False;40;Fresnel;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;241;-4058.877,-1024.224;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;236;-3923.205,-1042.327;Inherit;False;FinalSpecular;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;155;-2761.685,-211.3848;Inherit;False;236;FinalSpecular;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-2733.489,-342.1873;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LightColorNode;6;-2603.521,-129.2466;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SaturateNode;179;-2590,-217.8312;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LightAttenuation;5;-2609.845,-16.5661;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;180;-2562.699,-321.8313;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-2423.562,-114.0278;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;156;-2416.275,-242.9142;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;198;-2689.27,302.2294;Inherit;False;Property;_AmbientLightInfluence;AmbientLight Influence;17;0;Create;True;0;0;False;0;0.2;0.383;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;159;-2642.693,115.2715;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;-2647.658,210.0305;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;-2878.321,-3197.044;Inherit;False;Debug;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;160;-2311.489,160.2049;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-2254.159,-169.9081;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-1806.447,-293.0983;Inherit;False;Property;_OutputSelection;Output Selection;16;1;[Enum];Create;True;4;Total;0;Diffuse;1;Specular;2;Debug;3;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-1871.573,-42.96955;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-1768.909,-127.9724;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;176;-1773.909,-194.9724;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-1746.061,6.639339;Inherit;False;167;Debug;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;175;-1470.445,-144.3323;Inherit;False;Switch;-1;;17;ef8df9ee20085f74db0149565f949658;5,28,3,30,3,29,3,15,3,9,2;17;4;FLOAT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;-1245.976,-152.0629;Inherit;False;Output;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DesaturateOpNode;185;-3753.046,125.0782;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-3305.914,121.0379;Inherit;False;NdotLpostToon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;-4374.092,-2279.971;Inherit;False;104;NdotLpostToon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;250;-3187.127,-3125.281;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;249;-3348.732,-3189.924;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;208;-5779.412,566.6027;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;2;-6355.027,454.8681;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ToggleSwitchNode;203;-5390.867,765.2813;Inherit;False;Property;_InvertGradient;Invert Gradient;18;0;Create;True;0;0;False;0;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;186;-3508.075,121.4926;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;22;598.2496,297.2593;Inherit;False;162;Output;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SmoothstepOpNode;251;-3037.431,-3113.374;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;248;-3522.104,-3214.412;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;252;434.9013,412.961;Inherit;False;209;LdotHpretoon;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;246;-3377.119,-3295.886;Inherit;False;2;2;0;FLOAT;2;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;204;-5606.669,956.3811;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;187;-5699.576,476.9318;Inherit;False;NdotLpreToon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;243;-3179.677,-3241.151;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;768.5718,61.5391;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;TFE/Toon/Lightning PBR Fail;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.02;0,0,0,0;VertexOffset;False;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;49;0;47;0
WireConnection;49;1;47;0
WireConnection;74;0;48;0
WireConnection;73;0;49;0
WireConnection;69;0;66;0
WireConnection;63;0;62;0
WireConnection;63;1;73;0
WireConnection;170;0;169;1
WireConnection;170;1;172;0
WireConnection;244;13;76;0
WireConnection;244;10;14;0
WireConnection;244;11;45;0
WireConnection;244;19;75;0
WireConnection;245;13;76;0
WireConnection;245;10;14;0
WireConnection;245;11;45;0
WireConnection;171;0;170;0
WireConnection;61;0;63;0
WireConnection;68;4;70;0
WireConnection;68;2;245;0
WireConnection;68;3;245;0
WireConnection;68;5;244;0
WireConnection;173;1;171;0
WireConnection;173;0;169;1
WireConnection;59;0;68;0
WireConnection;59;1;24;0
WireConnection;19;0;16;0
WireConnection;19;1;61;0
WireConnection;46;0;16;0
WireConnection;46;3;73;0
WireConnection;46;4;74;0
WireConnection;67;4;69;0
WireConnection;67;2;17;0
WireConnection;67;3;19;0
WireConnection;67;5;46;0
WireConnection;188;0;173;0
WireConnection;27;0;59;0
WireConnection;165;0;67;0
WireConnection;164;0;165;0
WireConnection;190;0;189;0
WireConnection;3;0;28;0
WireConnection;3;1;173;0
WireConnection;4;0;3;0
WireConnection;125;0;190;0
WireConnection;125;1;124;0
WireConnection;126;0;125;0
WireConnection;163;0;107;1
WireConnection;163;1;166;0
WireConnection;9;0;4;0
WireConnection;56;0;52;0
WireConnection;56;1;9;0
WireConnection;8;0;7;0
WireConnection;8;1;9;0
WireConnection;206;0;190;0
WireConnection;206;1;126;0
WireConnection;108;0;163;0
WireConnection;108;1;99;0
WireConnection;254;2;142;0
WireConnection;57;0;56;0
WireConnection;151;0;254;0
WireConnection;242;0;206;0
WireConnection;259;0;108;0
WireConnection;83;0;67;0
WireConnection;116;0;114;0
WireConnection;116;1;115;0
WireConnection;58;0;8;0
WireConnection;130;0;126;0
WireConnection;130;1;128;0
WireConnection;209;0;242;0
WireConnection;55;1;57;0
WireConnection;55;0;58;0
WireConnection;117;0;116;0
WireConnection;135;0;259;0
WireConnection;113;0;55;0
WireConnection;113;3;114;0
WireConnection;113;4;117;0
WireConnection;207;0;130;0
WireConnection;216;0;215;0
WireConnection;216;1;213;0
WireConnection;134;0;135;0
WireConnection;153;0;152;0
WireConnection;146;0;207;0
WireConnection;20;0;113;0
WireConnection;20;1;84;0
WireConnection;20;2;153;0
WireConnection;214;0;151;0
WireConnection;214;1;216;0
WireConnection;222;0;223;0
WireConnection;21;0;20;0
WireConnection;138;0;137;0
WireConnection;138;1;220;0
WireConnection;218;0;214;0
WireConnection;218;1;213;0
WireConnection;224;0;222;0
WireConnection;224;1;222;0
WireConnection;232;0;108;0
WireConnection;226;0;218;0
WireConnection;210;0;211;0
WireConnection;210;1;59;0
WireConnection;225;0;224;0
WireConnection;225;1;224;0
WireConnection;139;0;138;0
WireConnection;139;1;221;0
WireConnection;136;0;147;0
WireConnection;136;1;137;0
WireConnection;212;0;210;0
WireConnection;227;0;226;0
WireConnection;227;1;225;0
WireConnection;140;0;136;0
WireConnection;140;1;147;0
WireConnection;140;2;139;0
WireConnection;141;1;144;0
WireConnection;141;2;151;0
WireConnection;233;0;231;0
WireConnection;228;0;218;0
WireConnection;228;1;227;0
WireConnection;145;0;140;0
WireConnection;145;1;141;0
WireConnection;150;0;145;0
WireConnection;40;0;228;0
WireConnection;234;0;230;0
WireConnection;234;1;233;0
WireConnection;235;0;234;0
WireConnection;235;1;231;0
WireConnection;241;0;235;0
WireConnection;241;1;238;0
WireConnection;241;2;239;0
WireConnection;236;0;241;0
WireConnection;179;0;155;0
WireConnection;180;0;154;0
WireConnection;11;0;6;1
WireConnection;11;1;5;0
WireConnection;156;0;180;0
WireConnection;156;1;179;0
WireConnection;167;0;242;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;160;2;198;0
WireConnection;157;0;156;0
WireConnection;157;1;11;0
WireConnection;158;0;157;0
WireConnection;158;1;160;0
WireConnection;175;4;174;0
WireConnection;175;24;158;0
WireConnection;175;25;176;0
WireConnection;175;26;177;0
WireConnection;175;27;178;0
WireConnection;162;0;175;0
WireConnection;185;0;113;0
WireConnection;104;0;186;0
WireConnection;250;0;249;0
WireConnection;249;0;248;0
WireConnection;203;0;4;0
WireConnection;203;1;204;0
WireConnection;186;0;185;0
WireConnection;251;0;250;0
WireConnection;248;0;206;0
WireConnection;246;1;206;0
WireConnection;204;0;4;0
WireConnection;187;0;3;0
WireConnection;243;0;246;0
WireConnection;0;13;22;0
ASEEND*/
//CHKSM=D3689A6EE4C0E0E43ED0D1E06B9F4A525E238F56
// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TFE/Toon/Lightning PBR"
{
	Properties
	{
		[Header(Toonificator)]_GradientMainLight("GradientMainLight", 2D) = "white" {}
		_GradientOtherLights("GradientOtherLights", 2D) = "white" {}
		_MinGradient("MinGradient", Range( 0 , 1)) = 0
		_MaxGradient("MaxGradient", Range( 0 , 1)) = 1
		[Toggle]_InvertYMain("InvertYMain", Float) = 0
		[Toggle]_InvertYOthers("InvertYOthers", Float) = 0
		[Header(Overall Tex)]_Tiling("Tiling", Float) = 1
		_FallOff("FallOff", Float) = 0.5
		[Enum(Color,0,Texture,1,Triplanar,2)][Header(Base Color)]_BaseColorType("BaseColor Type", Float) = 0
		_BaseColor("BaseColor", 2D) = "white" {}
		_MainColor1("Tint", Color) = (0.7843137,0.7843137,0.7843137,1)
		[Header(Normal)][Toggle]_UseMeshNormal("Use Mesh Normal", Float) = 0
		[Normal]_NormalTex("NormalTex", 2D) = "bump" {}
		[Space(20)]_NormalScale("NormalScale", Float) = 1
		[Header(Glossiness)]_Smoothness("Smoothness", Range( 0 , 1)) = 0
		[Toggle]_InvertGlossiness("InvertGlossiness", Float) = 0
		_SmoothnessMultiplier("SmoothnessMultiplier", Float) = 1
		_MaxGlossiness("MaxGlossiness", Float) = 1
		_GlossMap("GlossMap", 2D) = "white" {}
		[Toggle]_GlossInAlbedoAlpha("GlossInAlbedoAlpha", Float) = 0
		[Header(Metalness)]_Metalness("Metalness", Range( 0 , 1)) = 0
		[Enum(Total,0,Diffuse,1,Specular,2,Debug,3)]_OutputSelection("Output Selection", Float) = 0
		_AmbientLightInfluence("AmbientLight Influence", Range( 0 , 0.5)) = 0.2
		_MetalMap("MetalMap", 2D) = "white" {}
		[Header(Shadows)]_LightAttenuationPosition("LightAttenuation Position", Range( 0 , 1)) = 0.2
		_LightAttenuationWidth("LightAttenuation Width", Range( 0 , 1)) = 0.05
		[Toggle]_LightSwitch("LightSwitch", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "OutlineSobel"="true" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityStandardUtils.cginc"
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

		uniform float _OutputSelection;
		uniform sampler2D _GradientOtherLights;
		uniform float _UseMeshNormal;
		uniform float _BaseColorType;
		uniform sampler2D _NormalTex;
		uniform float _Tiling;
		uniform float _FallOff;
		uniform float _NormalScale;
		uniform float _InvertYOthers;
		uniform float _InvertGlossiness;
		uniform float _GlossInAlbedoAlpha;
		uniform sampler2D _GlossMap;
		uniform sampler2D _BaseColor;
		uniform float _Smoothness;
		uniform sampler2D _GradientMainLight;
		uniform float _InvertYMain;
		uniform float _MinGradient;
		uniform float _MaxGradient;
		uniform float _SmoothnessMultiplier;
		uniform float4 _MainColor1;
		uniform sampler2D _MetalMap;
		uniform float _Metalness;
		uniform float _MaxGlossiness;
		uniform float _LightSwitch;
		uniform float _LightAttenuationPosition;
		uniform float _LightAttenuationWidth;
		uniform float _AmbientLightInfluence;


		inline float3 TriplanarSampling17_g17( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
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
			float temp_output_4_0_g25 = _OutputSelection;
			float3 _Vector0 = float3(0,2,3);
			float DisplayType69 = _BaseColorType;
			float temp_output_4_0_g23 = DisplayType69;
			float2 appendResult49 = (float2(_Tiling , _Tiling));
			float2 Tiling73 = appendResult49;
			float2 temp_output_13_0_g17 = Tiling73;
			float TriplanarFallOffg74 = _FallOff;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float temp_output_11_0_g17 = _NormalScale;
			float3 triplanar17_g17 = TriplanarSampling17_g17( _NormalTex, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, temp_output_13_0_g17, temp_output_11_0_g17, 0 );
			float3 tanTriplanarNormal17_g17 = mul( ase_worldToTangent, triplanar17_g17 );
			float3 newWorldNormal4_g17 = normalize( (WorldNormalVector( i , tanTriplanarNormal17_g17 )) );
			float2 temp_output_13_0_g18 = Tiling73;
			float temp_output_11_0_g18 = _NormalScale;
			float3 newWorldNormal4_g18 = normalize( (WorldNormalVector( i , UnpackScaleNormal( tex2D( _NormalTex, ( temp_output_13_0_g18 * i.uv_texcoord ) ), temp_output_11_0_g18 ) )) );
			float3 temp_output_94_0 = newWorldNormal4_g18;
			float4 temp_output_7_0_g23 = ( temp_output_4_0_g23 == _Vector0.x ? float4( temp_output_94_0 , 0.0 ) : float4( temp_output_94_0 , 0.0 ) );
			float4 temp_output_12_0_g23 = ( temp_output_4_0_g23 == _Vector0.y ? float4( newWorldNormal4_g17 , 0.0 ) : temp_output_7_0_g23 );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float4 WorldNormal27 = (( _UseMeshNormal )?( float4( ase_normWorldNormal , 0.0 ) ):( temp_output_12_0_g23 ));
			float3 normalizeResult171 = normalize( ( _WorldSpaceLightPos0.xyz - ase_worldPos ) );
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch173 = _WorldSpaceLightPos0.xyz;
			#else
				float3 staticSwitch173 = normalizeResult171;
			#endif
			float dotResult3 = dot( WorldNormal27 , float4( staticSwitch173 , 0.0 ) );
			float temp_output_4_0 = (dotResult3*0.5 + 0.5);
			float2 _GradientYPos = float2(0,1);
			float2 appendResult282 = (float2(temp_output_4_0 , (( _InvertYOthers )?( _GradientYPos.y ):( _GradientYPos.x ))));
			float4 tex2DNode56 = tex2D( _GradientOtherLights, appendResult282 );
			float4 Debug167 = tex2DNode56;
			float3 LightDir188 = staticSwitch173;
			float3 normalizeResult190 = normalize( LightDir188 );
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 normalizeResult126 = normalize( ( normalizeResult190 + ase_worldViewDir ) );
			float dotResult130 = dot( float4( normalizeResult126 , 0.0 ) , WorldNormal27 );
			float NdotH146 = dotResult130;
			float2 UV61 = ( i.uv_texcoord * Tiling73 );
			float temp_output_4_0_g24 = DisplayType69;
			float4 triplanar46 = TriplanarSampling46( _BaseColor, ase_worldPos, ase_worldNormal, TriplanarFallOffg74, Tiling73, 1.0, 0 );
			float4 color17 = IsGammaSpace() ? float4(1,1,1,1) : float4(1,1,1,1);
			float4 temp_output_7_0_g24 = ( temp_output_4_0_g24 == _Vector0.x ? color17 : tex2D( _BaseColor, UV61 ) );
			float4 temp_output_12_0_g24 = ( temp_output_4_0_g24 == _Vector0.y ? triplanar46 : temp_output_7_0_g24 );
			float4 temp_output_246_0 = temp_output_12_0_g24;
			float AlbedoAlpha164 = (temp_output_246_0).w;
			float e134 = exp2( ( (( _InvertGlossiness )?( ( 1.0 - (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )) ) ):( (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )) )) * 12.0 * _Smoothness ) );
			float2 appendResult9 = (float2(temp_output_4_0 , (( _InvertYMain )?( _GradientYPos.y ):( _GradientYPos.x ))));
			#ifdef UNITY_PASS_FORWARDBASE
				float3 staticSwitch55 = (tex2D( _GradientMainLight, appendResult9 )).rgb;
			#else
				float3 staticSwitch55 = (tex2DNode56).rgb;
			#endif
			float3 temp_cast_9 = (_MinGradient).xxx;
			float3 temp_cast_10 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float3 temp_output_113_0 = (temp_cast_9 + (staticSwitch55 - float3( 0,0,0 )) * (temp_cast_10 - temp_cast_9) / (float3( 1,1,1 ) - float3( 0,0,0 )));
			float3 desaturateInitialColor185 = temp_output_113_0;
			float desaturateDot185 = dot( desaturateInitialColor185, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar185 = lerp( desaturateInitialColor185, desaturateDot185.xxx, 1.0 );
			float NdotL104 = (desaturateVar185).x;
			float temp_output_140_0 = ( pow( NdotH146 , e134 ) * ( ( e134 * 0.125 ) + 1.0 ) * NdotL104 );
			float lerpResult208 = lerp( temp_output_140_0 , ( temp_output_140_0 * _SmoothnessMultiplier ) , (( _InvertGlossiness )?( ( 1.0 - (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )) ) ):( (( _GlossInAlbedoAlpha )?( AlbedoAlpha164 ):( tex2D( _GlossMap, UV61 ).r )) )));
			float3 temp_cast_11 = (_MinGradient).xxx;
			float3 temp_cast_12 = (( max( _MinGradient , _MaxGradient ) + 0.001 )).xxx;
			float3 BaseColor83 = (( _MainColor1 * temp_output_246_0 )).rgb;
			float lerpResult205 = lerp( 0.0 , 0.7 , _Metalness);
			float Metalness151 = ( tex2D( _MetalMap, UV61 ).r * lerpResult205 );
			float3 Diffuse21 = ( temp_output_113_0 * BaseColor83 * ( 1.0 - Metalness151 ) );
			float3 lerpResult141 = lerp( float3( 0.05,0.05,0.05 ) , Diffuse21 , Metalness151);
			float3 Specular150 = ( lerpResult208 * lerpResult141 );
			float3 temp_cast_15 = (_MaxGlossiness).xxx;
			float3 clampResult212 = clamp( Specular150 , float3( 0,0,0 ) , temp_cast_15 );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float temp_output_264_0 = max( 0.0 , ( _LightAttenuationPosition - _LightAttenuationWidth ) );
			float temp_output_265_0 = min( 1.0 , ( _LightAttenuationPosition + _LightAttenuationWidth ) );
			float lerpResult275 = lerp( ase_lightAtten , temp_output_264_0 , temp_output_265_0);
			float temp_output_271_0 = max( lerpResult275 , ase_lightAtten );
			float AttenuationTooned257 = (( _LightSwitch )?( temp_output_271_0 ):( ase_lightAtten ));
			float4 temp_output_7_0_g25 = ( temp_output_4_0_g25 == _Vector0.x ? ( float4( ( ( saturate( Diffuse21 ) + clampResult212 ) * ( ase_lightColor.rgb * AttenuationTooned257 ) ) , 0.0 ) + ( UNITY_LIGHTMODEL_AMBIENT * float4( BaseColor83 , 0.0 ) * _AmbientLightInfluence ) ) : float4( Diffuse21 , 0.0 ) );
			float4 temp_output_12_0_g25 = ( temp_output_4_0_g25 == _Vector0.y ? float4( Specular150 , 0.0 ) : temp_output_7_0_g25 );
			float4 Output162 = ( temp_output_4_0_g25 == _Vector0.z ? Debug167 : temp_output_12_0_g25 );
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
Version=18500
354;73;853;615;7807.548;-35.52097;2.520587;True;False
Node;AmplifyShaderEditor.CommentaryNode;81;-6651.777,2263.396;Inherit;False;2870.216;922.9689;Comment;22;19;16;46;74;48;73;49;47;83;223;222;164;165;221;17;61;63;69;62;66;238;237;Base Color;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;47;-6592.547,2918.053;Inherit;False;Property;_Tiling;Tiling;6;0;Create;True;0;0;False;1;Header(Overall Tex);False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-6435.776,2906.307;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-6224.717,3063.435;Inherit;False;Property;_FallOff;FallOff;7;0;Create;True;0;0;False;0;False;0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;82;-7308.42,-957.2874;Inherit;False;1730.243;477.6984;Comment;10;75;76;70;27;59;24;94;93;45;14;Normal;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;73;-6302.665,2908.552;Inherit;False;Tiling;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;66;-5157.271,2472.993;Inherit;False;Property;_BaseColorType;BaseColor Type;8;1;[Enum];Create;True;3;Color;0;Texture;1;Triplanar;2;0;False;2;Header(Base Color);;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;74;-6091.605,3066.68;Inherit;False;TriplanarFallOffg;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;62;-6052.052,2714.214;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;75;-7149.955,-580.3591;Inherit;False;74;TriplanarFallOffg;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;232;-8613.115,374.2291;Inherit;False;4520.207;633.254;Comment;24;7;55;9;4;28;113;117;115;114;116;187;3;57;58;56;8;52;168;234;167;280;279;281;282;Toon Gradient;1,1,1,1;0;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-6089.35,2521.613;Inherit;True;Property;_BaseColor;BaseColor;9;0;Create;True;0;0;False;0;False;None;fc61e5c494810ca4ebc1f9e89b5711b5;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;69;-4967.961,2473.333;Inherit;False;DisplayType;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;76;-7153.767,-658.045;Inherit;False;73;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-7144.439,-726.2396;Inherit;False;Property;_NormalScale;NormalScale;13;0;Create;True;0;0;False;1;Space(20);False;1;1.58;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;14;-7258.42,-907.2874;Inherit;True;Property;_NormalTex;NormalTex;12;1;[Normal];Create;True;0;0;False;0;False;None;7864434e38680f64199090e5f072f56a;True;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;70;-6555.928,-829.6806;Inherit;False;69;DisplayType;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;93;-6825.415,-753.8786;Inherit;False;Blend World and NormalTex;-1;;17;a41941b1668fdfa4886041bd0a82573b;1,16,1;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;63;-5775.356,2773.299;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;168;-8563.115,532.765;Inherit;False;1066.81;360.6098;Comment;6;188;173;171;170;169;172;L;1,1,1,1;0;0
Node;AmplifyShaderEditor.TriplanarNode;46;-5791.099,2895.671;Inherit;True;Spherical;World;False;Top Texture 2;_TopTexture2;white;-1;None;Mid Texture 2;_MidTexture2;white;-1;None;Bot Texture 2;_BotTexture2;white;-1;None;Triplanar Sampler;Tangent;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT2;1,1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;94;-6822.461,-891.2513;Inherit;False;Blend World and NormalTex;-1;;18;a41941b1668fdfa4886041bd0a82573b;1,16,0;4;13;FLOAT2;1,1;False;10;SAMPLER2D;0;False;11;FLOAT;1;False;19;FLOAT;0.5;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;61;-5644.905,2767.057;Inherit;False;UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldSpaceLightPos;169;-8527.116,751.809;Inherit;False;0;3;FLOAT4;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.WorldNormalVector;24;-6370.209,-660.7898;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode;245;-6382.82,-818.8481;Inherit;False;Switch Vector;-1;;23;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldPosInputsNode;172;-8508.125,581.2197;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WireNode;237;-4847.221,2929.989;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;17;-5072.179,2596.265;Inherit;False;Constant;_MainColor;BaseColor;9;0;Create;False;0;0;False;0;False;1,1,1,1;1,0.3537736,0.3537736,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;238;-4824.412,2896.644;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;19;-5417.615,2531.098;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;59;-6058.265,-743.371;Inherit;False;Property;_UseMeshNormal;Use Mesh Normal;11;0;Create;True;0;0;False;1;Header(Normal);False;0;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;170;-8283.063,561.8135;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;27;-5810.856,-742.5649;Inherit;False;WorldNormal;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.NormalizeNode;171;-8151.412,559.7651;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;127;-6213.9,-2991.733;Inherit;False;4010.35;1074.688;;23;149;215;142;217;216;205;218;151;138;136;133;139;144;208;141;145;150;140;207;206;137;147;229;Specular;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;246;-4777.446,2548.396;Inherit;False;Switch Vector;-1;;24;aee5c6d08ca784945b154b9b7d527020;1,9,1;5;4;FLOAT;0;False;2;FLOAT4;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;5;FLOAT4;0,0,0,0;False;6;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;149;-6176.051,-2881.567;Inherit;False;1608.383;381.2552;e;11;134;135;108;99;219;220;163;107;166;214;213;e;1,1,1,1;0;0
Node;AmplifyShaderEditor.ComponentMaskNode;165;-4513.411,2741.273;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;173;-7981.835,719.1091;Inherit;False;Property;_Keyword0;Keyword 0;0;0;Create;True;0;0;False;0;False;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;28;-7616.365,572.7787;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;164;-4325.966,2741.739;Inherit;False;AlbedoAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;3;-7543.407,689.5641;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;280;-7191.716,812.663;Inherit;False;Constant;_GradientYPos;GradientYPos;30;0;Create;True;0;0;False;0;False;0,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TexturePropertyNode;213;-6149.97,-2829.932;Inherit;True;Property;_GlossMap;GlossMap;19;0;Create;True;0;0;False;0;False;None;3ecadffc148b3154281976fdeab1c593;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.GetLocalVarNode;214;-6132.465,-2638.031;Inherit;False;61;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;107;-5913.746,-2831.567;Inherit;True;Property;_GlossTex;GlossTex;13;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;229;-6137.633,-2421.237;Inherit;False;1396.442;420.1992;Comment;4;146;128;148;130;NdotH;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;166;-5844.708,-2643.427;Inherit;False;164;AlbedoAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;281;-7015.318,537.6104;Inherit;False;Property;_InvertYOthers;InvertYOthers;5;0;Create;True;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;4;-7369.224,740.9977;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;279;-6971.956,830.1397;Inherit;False;Property;_InvertYMain;InvertYMain;4;0;Create;True;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;7;-6738.823,826.782;Inherit;True;Property;_GradientMainLight;GradientMainLight;0;0;Create;True;0;0;False;1;Header(Toonificator);False;31562a04312b4af4e937109dcc121e5d;e1513d885e903d1489ac403f549253fb;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DynamicAppendNode;9;-6735.676,747.0216;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;282;-6708.951,625.4634;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ToggleSwitchNode;163;-5605.771,-2812.787;Inherit;False;Property;_GlossInAlbedoAlpha;GlossInAlbedoAlpha;23;0;Create;True;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;52;-6700.942,424.2291;Inherit;True;Property;_GradientOtherLights;GradientOtherLights;1;0;Create;True;0;0;False;0;False;None;93d30e48898c1994999e98ca23529674;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-7695.985,501.0539;Inherit;False;LightDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;148;-6087.633,-2371.237;Inherit;False;634.2778;326.2389;H;5;124;126;125;190;189;;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;220;-5503.404,-2646.336;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;114;-5763.17,674.6601;Inherit;False;Property;_MinGradient;MinGradient;2;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;8;-6394.592,707.2997;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;189;-6043.631,-2315.358;Inherit;False;188;LightDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;115;-5767.741,746.7449;Inherit;False;Property;_MaxGradient;MaxGradient;3;0;Create;True;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;56;-6389.11,446.607;Inherit;True;Property;_TextureSample3;Texture Sample 3;1;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;219;-5288.544,-2769.92;Inherit;False;Property;_InvertGlossiness;InvertGlossiness;16;0;Create;True;0;0;False;0;False;0;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;58;-6088.841,708.5846;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;142;-4185.251,-2139.996;Inherit;False;Property;_Metalness;Metalness;24;0;Create;True;0;0;False;1;Header(Metalness);False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;215;-4518.469,-2343.415;Inherit;True;Property;_MetalMap;MetalMap;27;0;Create;True;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;124;-6048.733,-2235.333;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;99;-5301.42,-2668.793;Inherit;False;Property;_Smoothness;Smoothness;15;0;Create;True;0;0;False;1;Header(Glossiness);False;0;0.318;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;217;-4462.469,-2117.414;Inherit;False;61;UV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NormalizeNode;190;-5883.18,-2310.523;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;116;-5445.605,689.9402;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;57;-6044.217,437.544;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;216;-4243.47,-2344.415;Inherit;True;Property;_TextureSample4;Texture Sample 4;26;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;-5010.421,-2826.364;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;12;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;221;-4873.271,2269.137;Inherit;False;Property;_MainColor1;Tint;10;0;Create;False;0;0;False;0;False;0.7843137,0.7843137,0.7843137,1;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-5321.456,698.1686;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.001;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;205;-3858.967,-2293.461;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.7;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;125;-5733.441,-2297.324;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StaticSwitch;55;-5746.458,563.0889;Inherit;False;Property;_Keyword0;Keyword 0;12;0;Create;True;0;0;False;0;False;0;0;0;False;UNITY_PASS_FORWARDBASE;Toggle;2;Key0;Key1;Fetch;True;True;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;234;-4935.438,499.178;Inherit;False;729.0381;311.0637;Comment;3;185;186;104;NdotL;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;128;-5431.606,-2151.627;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TFHCRemapNode;113;-5185.428,553.9004;Inherit;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,1,1;False;3;FLOAT3;0,0,0;False;4;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;218;-3657.506,-2327.175;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;222;-4356.974,2540.761;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;126;-5609.213,-2285.932;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.Exp2OpNode;135;-4874.968,-2819.715;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;185;-4885.438,556.2416;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;134;-4760.893,-2825.33;Inherit;False;e;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;233;-4895.376,1187.943;Inherit;False;796.8037;259.6097;;5;152;153;84;20;21;Diffuse;1,1,1,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;130;-5259.333,-2285.598;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;151;-3515.615,-2313.863;Inherit;False;Metalness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;223;-4201.696,2541.812;Inherit;False;True;True;True;False;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;137;-4278.16,-2537.057;Inherit;False;134;e;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;186;-4633.561,555.4303;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;152;-4845.376,1330.216;Inherit;False;151;Metalness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-3980.703,2538.884;Inherit;False;BaseColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;146;-5100.99,-2275.111;Inherit;False;NdotH;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-4039.82,-2484.328;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.125;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;259;-8422.891,-342.3632;Inherit;False;1877.856;606.3897;Comment;17;257;270;268;273;274;271;267;272;266;264;265;263;262;260;261;275;276;Attenuation tooned;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;153;-4675.788,1336.553;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;-4430.4,549.1779;Inherit;False;NdotL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-4842.987,1243.732;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;147;-4281.793,-2633.564;Inherit;False;146;NdotH;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;133;-3869.187,-2591.017;Inherit;False;104;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;136;-4062.366,-2634.612;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;260;-8372.891,-134.3632;Inherit;False;Property;_LightAttenuationWidth;LightAttenuation Width;29;0;Create;True;0;0;False;0;False;0.05;0.137;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;139;-3883.716,-2484.056;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;261;-8371.891,-223.3632;Inherit;False;Property;_LightAttenuationPosition;LightAttenuation Position;28;0;Create;True;0;0;False;1;Header(Shadows);False;0.2;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;20;-4519.076,1237.943;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;206;-3394.973,-2553.271;Inherit;False;Property;_SmoothnessMultiplier;SmoothnessMultiplier;17;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;263;-8023.589,-139.7631;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;140;-3651.956,-2634.559;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;262;-8026.889,-292.3633;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;21;-4322.572,1238.866;Inherit;False;Diffuse;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;264;-7867.889,-264.3633;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;144;-3455.633,-2395.05;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMinOpNode;265;-7890.889,-173.3632;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;226;-3027.186,-2740.757;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightAttenuation;266;-8148.288,20.99442;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;207;-3151.187,-2595.926;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;208;-2968.635,-2649.145;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;275;-7595.533,-273.9178;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;141;-3245.664,-2406.557;Inherit;False;3;0;FLOAT3;0.05,0.05,0.05;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;271;-7434.97,-117.8078;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;145;-2817.05,-2453.614;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightAttenuation;268;-7178.375,-93.90958;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;276;-6950.806,-143.6254;Inherit;False;Property;_LightSwitch;LightSwitch;30;0;Create;True;0;0;False;0;False;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;236;-1832.884,-50.86576;Inherit;False;2309.631;684.1461;;20;158;198;161;159;160;177;176;178;174;162;11;157;6;156;180;154;212;155;211;5;Output;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;150;-2601.219,-2462.476;Inherit;False;Specular;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;155;-1771.426,50.78723;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;154;-1490.868,-0.8657684;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;211;-1782.884,142.7986;Inherit;False;Property;_MaxGlossiness;MaxGlossiness;18;0;Create;True;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;257;-6770.777,-7.92625;Inherit;False;AttenuationTooned;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;212;-1550.988,60.70222;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;180;-1317.077,1.49025;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;258;-1413.58,417.4721;Inherit;False;257;AttenuationTooned;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LightColorNode;6;-1411.49,206.467;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;159;-917.9009,350.3223;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;156;-1174.653,30.40744;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;198;-948.4782,517.2803;Inherit;False;Property;_AmbientLightInfluence;AmbientLight Influence;26;0;Create;True;0;0;False;0;False;0.2;0.5;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-1187.93,223.1824;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;-906.8658,425.0812;Inherit;False;83;BaseColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;157;-1018.526,167.3022;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;167;-6044.012,533.7772;Inherit;False;Debug;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;160;-570.697,408.7554;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-255.9288,350.1407;Inherit;False;167;Debug;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;174;-248.9353,83.67545;Inherit;False;Property;_OutputSelection;Output Selection;25;1;[Enum];Create;True;4;Total;0;Diffuse;1;Specular;2;Debug;3;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;176;-266.0038,210.4476;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;-377.7814,154.7813;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;177;-261.0038,277.4476;Inherit;False;150;Specular;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;244;17.27822,120.1728;Inherit;False;Switch;-1;;25;ef8df9ee20085f74db0149565f949658;5,28,3,30,3,29,3,15,3,9,2;17;4;FLOAT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;162;252.7471,116.4421;Inherit;False;Output;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CommentaryNode;224;-1608.784,2622.39;Inherit;False;2203.152;713.2664;Comment;11;41;109;105;106;15;25;29;111;12;100;112;;1,1,1,1;0;0
Node;AmplifyShaderEditor.FunctionNode;106;0.3968391,3141.613;Inherit;False;GetGlossiness;-1;;26;62e5dc4f9ea737545928ae51607e1e26;0;4;1;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;8;FLOAT3;0,0,0;False;2;FLOAT;0;FLOAT;6
Node;AmplifyShaderEditor.GetLocalVarNode;22;609.2496,302.2593;Inherit;False;162;Output;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;-1356.193,3037.012;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.IndirectDiffuseLighting;12;-1342.56,2675.659;Inherit;False;World;1;0;FLOAT3;0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;34;-2300.201,-1235.396;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;29;-1558.784,2672.39;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;38;-1745.687,-938.8041;Inherit;False;Property;_FresnelStep;FresnelStep;21;0;Create;True;0;0;False;0;False;0;0.375;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;31;-1860.69,-1569.469;Inherit;True;Property;_TextureSample2;Texture Sample 2;5;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SmoothstepOpNode;267;-7727.893,-147.757;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;274;-7380.898,74.30204;Inherit;False;1;0;COLOR;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;35;-2688.234,-1228.133;Inherit;False;Property;_FresnelInfo;FresnelInfo;20;0;Create;True;0;0;False;0;False;0,0,0;0,1.04,1;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;42;-1887.428,-1194.965;Inherit;False;Property;_FresnelShadowing;FresnelShadowing;22;0;Create;True;0;0;False;0;False;0;0.955;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;109;198.6141,2952.583;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-914.0182,-1024.741;Inherit;False;FresnelMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;111;-302.5861,3021.584;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwitchNode;270;-6979.126,-12.43144;Inherit;False;1;2;8;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;39;-1406.421,-987.733;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FogAndAmbientColorsNode;272;-7664.957,73.27769;Inherit;False;UNITY_LIGHTMODEL_AMBIENT;0;1;COLOR;0
Node;AmplifyShaderEditor.FresnelNode;26;-2513.624,-1246.186;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;112;365.368,2892.699;Inherit;False;Property;_UseGlossiness;Use Glossiness;14;0;Create;True;0;0;False;1;Header(Glossiness);False;0;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;33;-2089.762,-1236.621;Inherit;True;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;37;-1521.135,-692.1479;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;105;-178.2398,3153.766;Inherit;False;104;NdotL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;43;-1621.428,-1198.965;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-668.4639,3123.395;Inherit;False;40;FresnelMask;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;30;-2652.055,-1436.725;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LightAttenuation;5;-1446.841,325.1266;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;230;-5867.443,-369.0944;Inherit;False;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.OneMinusNode;36;-1983.164,-978.0548;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;100;-193.6267,3219.656;Inherit;False;27;WorldNormal;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;273;-7169.891,30.22071;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;187;-7385.24,572.0776;Inherit;False;NdotLpreToon;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;15;-728.1948,2791.358;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;231;-6467.191,-103.5518;Inherit;False;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.SaturateNode;44;-1144.107,-1010.095;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;235;76.11676,2874.302;Inherit;False;21;Diffuse;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;768.5718,61.5391;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;TFE/Toon/Lightning PBR;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0.02;0,0,0,0;VertexOffset;False;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;1;OutlineSobel=true;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;49;0;47;0
WireConnection;49;1;47;0
WireConnection;73;0;49;0
WireConnection;74;0;48;0
WireConnection;69;0;66;0
WireConnection;93;13;76;0
WireConnection;93;10;14;0
WireConnection;93;11;45;0
WireConnection;93;19;75;0
WireConnection;63;0;62;0
WireConnection;63;1;73;0
WireConnection;46;0;16;0
WireConnection;46;3;73;0
WireConnection;46;4;74;0
WireConnection;94;13;76;0
WireConnection;94;10;14;0
WireConnection;94;11;45;0
WireConnection;61;0;63;0
WireConnection;245;4;70;0
WireConnection;245;2;94;0
WireConnection;245;3;94;0
WireConnection;245;5;93;0
WireConnection;237;0;46;0
WireConnection;238;0;237;0
WireConnection;19;0;16;0
WireConnection;19;1;61;0
WireConnection;59;0;245;0
WireConnection;59;1;24;0
WireConnection;170;0;169;1
WireConnection;170;1;172;0
WireConnection;27;0;59;0
WireConnection;171;0;170;0
WireConnection;246;4;69;0
WireConnection;246;2;17;0
WireConnection;246;3;19;0
WireConnection;246;5;238;0
WireConnection;165;0;246;0
WireConnection;173;1;171;0
WireConnection;173;0;169;1
WireConnection;164;0;165;0
WireConnection;3;0;28;0
WireConnection;3;1;173;0
WireConnection;107;0;213;0
WireConnection;107;1;214;0
WireConnection;281;0;280;1
WireConnection;281;1;280;2
WireConnection;4;0;3;0
WireConnection;279;0;280;1
WireConnection;279;1;280;2
WireConnection;9;0;4;0
WireConnection;9;1;279;0
WireConnection;282;0;4;0
WireConnection;282;1;281;0
WireConnection;163;0;107;1
WireConnection;163;1;166;0
WireConnection;188;0;173;0
WireConnection;220;0;163;0
WireConnection;8;0;7;0
WireConnection;8;1;9;0
WireConnection;56;0;52;0
WireConnection;56;1;282;0
WireConnection;219;0;163;0
WireConnection;219;1;220;0
WireConnection;58;0;8;0
WireConnection;190;0;189;0
WireConnection;116;0;114;0
WireConnection;116;1;115;0
WireConnection;57;0;56;0
WireConnection;216;0;215;0
WireConnection;216;1;217;0
WireConnection;108;0;219;0
WireConnection;108;2;99;0
WireConnection;117;0;116;0
WireConnection;205;2;142;0
WireConnection;125;0;190;0
WireConnection;125;1;124;0
WireConnection;55;1;57;0
WireConnection;55;0;58;0
WireConnection;113;0;55;0
WireConnection;113;3;114;0
WireConnection;113;4;117;0
WireConnection;218;0;216;1
WireConnection;218;1;205;0
WireConnection;222;0;221;0
WireConnection;222;1;246;0
WireConnection;126;0;125;0
WireConnection;135;0;108;0
WireConnection;185;0;113;0
WireConnection;134;0;135;0
WireConnection;130;0;126;0
WireConnection;130;1;128;0
WireConnection;151;0;218;0
WireConnection;223;0;222;0
WireConnection;186;0;185;0
WireConnection;83;0;223;0
WireConnection;146;0;130;0
WireConnection;138;0;137;0
WireConnection;153;0;152;0
WireConnection;104;0;186;0
WireConnection;136;0;147;0
WireConnection;136;1;137;0
WireConnection;139;0;138;0
WireConnection;20;0;113;0
WireConnection;20;1;84;0
WireConnection;20;2;153;0
WireConnection;263;0;261;0
WireConnection;263;1;260;0
WireConnection;140;0;136;0
WireConnection;140;1;139;0
WireConnection;140;2;133;0
WireConnection;262;0;261;0
WireConnection;262;1;260;0
WireConnection;21;0;20;0
WireConnection;264;1;262;0
WireConnection;265;1;263;0
WireConnection;226;0;219;0
WireConnection;207;0;140;0
WireConnection;207;1;206;0
WireConnection;208;0;140;0
WireConnection;208;1;207;0
WireConnection;208;2;226;0
WireConnection;275;0;266;0
WireConnection;275;1;264;0
WireConnection;275;2;265;0
WireConnection;141;1;144;0
WireConnection;141;2;151;0
WireConnection;271;0;275;0
WireConnection;271;1;266;0
WireConnection;145;0;208;0
WireConnection;145;1;141;0
WireConnection;276;0;268;0
WireConnection;276;1;271;0
WireConnection;150;0;145;0
WireConnection;257;0;276;0
WireConnection;212;0;155;0
WireConnection;212;2;211;0
WireConnection;180;0;154;0
WireConnection;156;0;180;0
WireConnection;156;1;212;0
WireConnection;11;0;6;1
WireConnection;11;1;258;0
WireConnection;157;0;156;0
WireConnection;157;1;11;0
WireConnection;167;0;56;0
WireConnection;160;0;159;0
WireConnection;160;1;161;0
WireConnection;160;2;198;0
WireConnection;158;0;157;0
WireConnection;158;1;160;0
WireConnection;244;4;174;0
WireConnection;244;24;158;0
WireConnection;244;25;176;0
WireConnection;244;26;177;0
WireConnection;244;27;178;0
WireConnection;162;0;244;0
WireConnection;106;1;111;0
WireConnection;106;4;105;0
WireConnection;106;8;100;0
WireConnection;25;0;113;0
WireConnection;12;0;29;0
WireConnection;34;0;26;0
WireConnection;31;0;230;0
WireConnection;31;1;33;0
WireConnection;267;0;266;0
WireConnection;267;1;264;0
WireConnection;267;2;265;0
WireConnection;274;0;272;0
WireConnection;109;0;235;0
WireConnection;109;1;106;6
WireConnection;40;0;44;0
WireConnection;270;0;268;0
WireConnection;270;1;271;0
WireConnection;39;0;36;0
WireConnection;39;1;43;0
WireConnection;39;2;38;0
WireConnection;26;1;35;1
WireConnection;26;2;35;2
WireConnection;26;3;35;3
WireConnection;112;0;235;0
WireConnection;112;1;109;0
WireConnection;33;0;34;0
WireConnection;37;0;38;0
WireConnection;37;1;36;0
WireConnection;43;0;42;0
WireConnection;230;0;231;0
WireConnection;36;0;34;0
WireConnection;273;0;271;0
WireConnection;273;1;274;0
WireConnection;187;0;3;0
WireConnection;15;0;25;0
WireConnection;15;1;12;0
WireConnection;231;0;7;0
WireConnection;44;0;39;0
WireConnection;0;13;22;0
ASEEND*/
//CHKSM=8FE4401E260E5008A5CE178C0B72B7173A7E2996
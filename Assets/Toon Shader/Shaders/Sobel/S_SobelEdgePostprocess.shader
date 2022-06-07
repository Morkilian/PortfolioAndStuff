// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Toon/Postprocess/SobelEdge"
{
	Properties
	{
		_MainTex ( "Screen", 2D ) = "black" {}
		_OutlineDepthThickness("_OutlineDepthThickness", Range( 0 , 1)) = 0
		_OutlineNormalThickness("_OutlineNormalThickness", Range( 0 , 1)) = 0
		_ColorToApply("ColorToApply", Color) = (0,0,0,0)
		_OutlineDepthBias("_OutlineDepthBias", Float) = 0
		_OutlineNormalBias("_OutlineNormalBias", Float) = 0
		_OutlineDepthMultiplier("_OutlineDepthMultiplier", Float) = 0
		_OutlineNormalMultiplier("_OutlineNormalMultiplier", Float) = 0
		_SobelType("_SobelType", Int) = 0
		_SobelOnly("_SobelOnly", Int) = 0
		_ShowBaseImage("_ShowBaseImage", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}

	SubShader
	{
		LOD 0

		
		
		ZTest Always
		Cull Off
		ZWrite Off

		
		Pass
		{ 
			CGPROGRAM 

			

			#pragma vertex vert_img_custom 
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"


			struct appdata_img_custom
			{
				float4 vertex : POSITION;
				half2 texcoord : TEXCOORD0;
				
			};

			struct v2f_img_custom
			{
				float4 pos : SV_POSITION;
				half2 uv   : TEXCOORD0;
				half2 stereoUV : TEXCOORD2;
		#if UNITY_UV_STARTS_AT_TOP
				half4 uv2 : TEXCOORD1;
				half4 stereoUV2 : TEXCOORD3;
		#endif
				
			};

			uniform sampler2D _MainTex;
			uniform half4 _MainTex_TexelSize;
			uniform half4 _MainTex_ST;
			
			uniform float _ShowBaseImage;
			uniform int _SobelOnly;
			uniform sampler2D _OcclusionDepthMap;
			uniform float _OutlineDepthThickness;
			uniform float4 _ColorToApply;
			uniform int _SobelType;
			uniform sampler2D _CameraDepthNormalsTexture;
			uniform float _OutlineNormalThickness;
			uniform float _OutlineNormalMultiplier;
			uniform float _OutlineNormalBias;
			UNITY_DECLARE_DEPTH_TEXTURE( _CameraDepthTexture );
			uniform float _OutlineDepthMultiplier;
			uniform float _OutlineDepthBias;
			uniform float4 _CameraDepthTexture_ST;


			v2f_img_custom vert_img_custom ( appdata_img_custom v  )
			{
				v2f_img_custom o;
				
				o.pos = UnityObjectToClipPos( v.vertex );
				o.uv = float4( v.texcoord.xy, 1, 1 );

				#if UNITY_UV_STARTS_AT_TOP
					o.uv2 = float4( v.texcoord.xy, 1, 1 );
					o.stereoUV2 = UnityStereoScreenSpaceUVAdjust ( o.uv2, _MainTex_ST );

					if ( _MainTex_TexelSize.y < 0.0 )
						o.uv.y = 1.0 - o.uv.y;
				#endif
				o.stereoUV = UnityStereoScreenSpaceUVAdjust ( o.uv, _MainTex_ST );
				return o;
			}

			half4 frag ( v2f_img_custom i ) : SV_Target
			{
				#ifdef UNITY_UV_STARTS_AT_TOP
					half2 uv = i.uv2;
					half2 stereoUV = i.stereoUV2;
				#else
					half2 uv = i.uv;
					half2 stereoUV = i.stereoUV;
				#endif	
				
				half4 finalColor;

				// ase common template code
				float2 temp_output_2_0_g25 = i.uv.xy;
				float temp_output_8_0 = ( 1.0 / _ScreenParams.x );
				float temp_output_9_0 = ( 1.0 / _ScreenParams.y );
				float3 appendResult12 = (float3(temp_output_8_0 , temp_output_9_0 , _OutlineDepthThickness));
				float3 temp_output_69_0_g25 = appendResult12;
				float2 temp_output_71_0_g25 = (temp_output_69_0_g25).xy;
				float2 _Units = float2(0,1);
				float temp_output_75_0_g25 = (temp_output_69_0_g25).z;
				float2 VerticalOffset77_g25 = ( ( temp_output_71_0_g25 * _Units ) * temp_output_75_0_g25 );
				float4 tex2DNode17_g26 = tex2D( _OcclusionDepthMap, ( temp_output_2_0_g25 + VerticalOffset77_g25 ) );
				float4 tex2DNode17_g28 = tex2D( _OcclusionDepthMap, ( temp_output_2_0_g25 + -VerticalOffset77_g25 ) );
				float temp_output_57_0_g25 = ( ( tex2DNode17_g26.r + -tex2DNode17_g28.r ) * 0.5 );
				float2 HorizontalOffset78_g25 = ( ( temp_output_71_0_g25 * (_Units).yx ) * temp_output_75_0_g25 );
				float4 tex2DNode17_g27 = tex2D( _OcclusionDepthMap, ( temp_output_2_0_g25 + HorizontalOffset78_g25 ) );
				float4 tex2DNode17_g29 = tex2D( _OcclusionDepthMap, ( temp_output_2_0_g25 + -HorizontalOffset78_g25 ) );
				float temp_output_64_0_g25 = ( ( tex2DNode17_g27.r + -tex2DNode17_g29.r ) * 0.5 );
				float temp_output_67_0_g25 = sqrt( ( ( temp_output_57_0_g25 * temp_output_57_0_g25 ) + ( temp_output_64_0_g25 * temp_output_64_0_g25 ) ) );
				float3 appendResult68_g25 = (float3(temp_output_67_0_g25 , temp_output_67_0_g25 , temp_output_67_0_g25));
				float4 tex2DNode13 = tex2D( _MainTex, i.uv.xy );
				int temp_output_4_0_g23 = _SobelType;
				float3 _Vector0 = float3(0,2,3);
				float2 temp_output_2_0_g13 = i.uv.xy;
				float3 appendResult79 = (float3(temp_output_8_0 , temp_output_9_0 , _OutlineNormalThickness));
				float3 temp_output_69_0_g13 = appendResult79;
				float2 temp_output_71_0_g13 = (temp_output_69_0_g13).xy;
				float temp_output_75_0_g13 = (temp_output_69_0_g13).z;
				float2 VerticalOffset77_g13 = ( ( temp_output_71_0_g13 * _Units ) * temp_output_75_0_g13 );
				float4 tex2DNode17_g15 = tex2D( _CameraDepthNormalsTexture, ( temp_output_2_0_g13 + VerticalOffset77_g13 ) );
				float depthDecodedVal90_g13 = 0;
				float3 normalDecodedVal90_g13 = float3(0,0,0);
				DecodeDepthNormal( tex2DNode17_g15, depthDecodedVal90_g13, normalDecodedVal90_g13 );
				float depthDecodedVal98_g13 = 0;
				float3 normalDecodedVal98_g13 = float3(0,0,0);
				DecodeDepthNormal( tex2D( _CameraDepthNormalsTexture, temp_output_2_0_g13 ), depthDecodedVal98_g13, normalDecodedVal98_g13 );
				float4 tex2DNode17_g16 = tex2D( _CameraDepthNormalsTexture, ( temp_output_2_0_g13 + -VerticalOffset77_g13 ) );
				float depthDecodedVal92_g13 = 0;
				float3 normalDecodedVal92_g13 = float3(0,0,0);
				DecodeDepthNormal( tex2DNode17_g16, depthDecodedVal92_g13, normalDecodedVal92_g13 );
				float2 HorizontalOffset78_g13 = ( ( temp_output_71_0_g13 * (_Units).yx ) * temp_output_75_0_g13 );
				float4 tex2DNode17_g17 = tex2D( _CameraDepthNormalsTexture, ( temp_output_2_0_g13 + HorizontalOffset78_g13 ) );
				float depthDecodedVal91_g13 = 0;
				float3 normalDecodedVal91_g13 = float3(0,0,0);
				DecodeDepthNormal( tex2DNode17_g17, depthDecodedVal91_g13, normalDecodedVal91_g13 );
				float4 tex2DNode17_g14 = tex2D( _CameraDepthNormalsTexture, ( temp_output_2_0_g13 + -HorizontalOffset78_g13 ) );
				float depthDecodedVal93_g13 = 0;
				float3 normalDecodedVal93_g13 = float3(0,0,0);
				DecodeDepthNormal( tex2DNode17_g14, depthDecodedVal93_g13, normalDecodedVal93_g13 );
				float3 break57 = ( abs( ( normalDecodedVal90_g13 - normalDecodedVal98_g13 ) ) + abs( ( normalDecodedVal92_g13 - normalDecodedVal98_g13 ) ) + abs( ( normalDecodedVal91_g13 - normalDecodedVal98_g13 ) ) + abs( ( normalDecodedVal93_g13 - normalDecodedVal98_g13 ) ) );
				float temp_output_58_0 = ( break57.x + break57.y + break57.z );
				float temp_output_75_0 = pow( ( saturate( temp_output_58_0 ) * _OutlineNormalMultiplier ) , _OutlineNormalBias );
				float2 temp_output_2_0_g18 = i.uv.xy;
				float3 temp_output_69_0_g18 = appendResult12;
				float2 temp_output_71_0_g18 = (temp_output_69_0_g18).xy;
				float temp_output_75_0_g18 = (temp_output_69_0_g18).z;
				float2 VerticalOffset77_g18 = ( ( temp_output_71_0_g18 * _Units ) * temp_output_75_0_g18 );
				float4 tex2DNode17_g19 = tex2D( _CameraDepthTexture, ( temp_output_2_0_g18 + VerticalOffset77_g18 ) );
				float4 tex2DNode17_g21 = tex2D( _CameraDepthTexture, ( temp_output_2_0_g18 + -VerticalOffset77_g18 ) );
				float temp_output_57_0_g18 = ( ( tex2DNode17_g19.r + -tex2DNode17_g21.r ) * 0.5 );
				float2 HorizontalOffset78_g18 = ( ( temp_output_71_0_g18 * (_Units).yx ) * temp_output_75_0_g18 );
				float4 tex2DNode17_g20 = tex2D( _CameraDepthTexture, ( temp_output_2_0_g18 + HorizontalOffset78_g18 ) );
				float4 tex2DNode17_g22 = tex2D( _CameraDepthTexture, ( temp_output_2_0_g18 + -HorizontalOffset78_g18 ) );
				float temp_output_64_0_g18 = ( ( tex2DNode17_g20.r + -tex2DNode17_g22.r ) * 0.5 );
				float temp_output_67_0_g18 = sqrt( ( ( temp_output_57_0_g18 * temp_output_57_0_g18 ) + ( temp_output_64_0_g18 * temp_output_64_0_g18 ) ) );
				float3 appendResult68_g18 = (float3(temp_output_67_0_g18 , temp_output_67_0_g18 , temp_output_67_0_g18));
				float temp_output_40_0 = pow( ( saturate( (appendResult68_g18).x ) * _OutlineDepthMultiplier ) , _OutlineDepthBias );
				float temp_output_7_0_g23 = ( (float)temp_output_4_0_g23 == _Vector0.x ? temp_output_40_0 : temp_output_75_0 );
				float temp_output_12_0_g23 = ( (float)temp_output_4_0_g23 == _Vector0.y ? max( temp_output_75_0 , temp_output_40_0 ) : temp_output_7_0_g23 );
				float temp_output_94_0 = temp_output_12_0_g23;
				float4 lerpResult26 = lerp( tex2DNode13 , _ColorToApply , temp_output_94_0);
				float4 temp_cast_8 = (temp_output_94_0).xxxx;
				int temp_output_4_0_g24 = _SobelType;
				float2 uv_CameraDepthTexture = i.uv.xy * _CameraDepthTexture_ST.xy + _CameraDepthTexture_ST.zw;
				float4 temp_cast_12 = (tex2D( _CameraDepthTexture, uv_CameraDepthTexture ).r).xxxx;
				float depthDecodedVal65 = 0;
				float3 normalDecodedVal65 = float3(0,0,0);
				DecodeDepthNormal( tex2D( _CameraDepthNormalsTexture, i.uv.xy ), depthDecodedVal65, normalDecodedVal65 );
				float3 temp_output_101_0 = mul( float4( normalDecodedVal65 , 0.0 ), unity_CameraToWorld ).xyz;
				float4 temp_output_7_0_g24 = ( (float)temp_output_4_0_g24 == _Vector0.x ? temp_cast_12 : float4( temp_output_101_0 , 0.0 ) );
				float4 temp_output_12_0_g24 = ( (float)temp_output_4_0_g24 == _Vector0.y ? tex2DNode13 : temp_output_7_0_g24 );
				

				finalColor = ( _ShowBaseImage == 0.0 ? ( (float)_SobelOnly == 0.0 ? ( (appendResult68_g25).x == 0.0 ? tex2DNode13 : lerpResult26 ) : temp_cast_8 ) : temp_output_12_0_g24 );

				return finalColor;
			} 
			ENDCG 
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18500
724;73;806;832;-1977.351;576.975;1.480606;True;False
Node;AmplifyShaderEditor.RangedFloatNode;10;-946.8182,-716.6901;Inherit;False;Constant;_Float0;Float 0;1;0;Create;True;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenParams;5;-1066.574,-612.1102;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;80;-834.0346,-858.3506;Inherit;False;Property;_OutlineNormalThickness;_OutlineNormalThickness;1;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;8;-745.3287,-698.323;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;9;-745.8181,-593.6901;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;79;-489.817,-769.7197;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TexturePropertyNode;51;-187.7706,-944.6105;Inherit;True;Global;_CameraDepthNormalsTexture;_CameraDepthNormalsTexture ;5;0;Create;True;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexCoordVertexDataNode;21;-773.3305,-154.6914;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;59;216.025,-770.3478;Inherit;False;SobelEdgeNormals4Sample;-1;;13;9aa2e6458ce50c746b928ace39408008;0;4;1;SAMPLER2D;0;False;2;FLOAT2;0,0;False;69;FLOAT3;0.1,0.1,0.1;False;28;FLOAT;0.1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;11;-865.8907,-382.5758;Inherit;False;Property;_OutlineDepthThickness;_OutlineDepthThickness;0;0;Create;True;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;31;-481.7627,-249.6674;Inherit;True;Global;_CameraDepthTexture;_CameraDepthTexture;3;0;Create;True;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.DynamicAppendNode;12;-531.714,-593.7231;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;57;521.2559,-771.179;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;58;755.6685,-710.4449;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;45;-32.03082,-67.65804;Inherit;False;SobelEdgeDepth4Sample;-1;;18;c6e973b30892b0a41958c9809ead624f;0;4;1;SAMPLER2D;0;False;2;FLOAT2;0,0;False;69;FLOAT3;0.1,0.1,0.1;False;28;FLOAT;0.1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;72;984.3259,-738.1603;Inherit;False;Property;_OutlineNormalMultiplier;_OutlineNormalMultiplier;9;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;71;1057.199,-840.4698;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;28;253.4294,-73.19293;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;73;1061.733,-669.189;Inherit;False;Property;_OutlineNormalBias;_OutlineNormalBias;7;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;1237.036,-841.1685;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;41;770.6769,-175.6578;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;61;1199.911,-324.3352;Inherit;False;Property;_SobelType;_SobelType;10;0;Create;True;0;0;False;0;False;0;0;0;1;INT;0
Node;AmplifyShaderEditor.RangedFloatNode;34;719.0271,-105.1829;Inherit;False;Property;_OutlineDepthMultiplier;_OutlineDepthMultiplier;8;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;75;1437.003,-689.7862;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;841.5002,-40.94447;Inherit;False;Property;_OutlineDepthBias;_OutlineDepthBias;6;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;950.5143,-176.3565;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;87;1336.848,-321.8841;Inherit;False;1;0;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.TemplateShaderPropertyNode;1;-684.2557,-254.2699;Inherit;False;0;0;_MainTex;Shader;0;5;SAMPLER2D;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;84;1424.235,-387.4821;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;64;287.9562,-562.9855;Inherit;True;Property;_TextureSample1;Texture Sample 1;8;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;13;-531.6201,28.58397;Inherit;True;Property;_TextureSample0;Texture Sample 0;2;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;0,0,0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;40;1147.828,-144.3537;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;86;1332.848,-514.8841;Inherit;False;1;0;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.TexturePropertyNode;105;-490.5945,-443.5721;Inherit;True;Global;_OcclusionDepthMap;_OcclusionDepthMap;4;0;Create;True;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMaxOpNode;76;1475.465,-252.6447;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;85;1345.848,-541.8841;Inherit;False;1;0;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.WireNode;90;-214.3228,284.6942;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DecodeDepthNormalNode;65;712.8299,-472.7753;Inherit;False;1;0;FLOAT4;0,0,0,0;False;2;FLOAT;0;FLOAT3;1
Node;AmplifyShaderEditor.CameraToWorldMatrix;103;738.468,162.1882;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SamplerNode;83;151.7581,239.01;Inherit;True;Property;_TextureSample2;Texture Sample 2;12;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;88;1373.969,221.2323;Inherit;False;1;0;INT;0;False;1;INT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;984.7924,170.801;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;94;1680.01,-602.3948;Inherit;False;Switch;-1;;23;ef8df9ee20085f74db0149565f949658;5,28,0,30,0,29,0,15,0,9,1;17;4;INT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;1726.065,84.8414;Inherit;False;Property;_ColorToApply;ColorToApply;2;0;Create;True;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;89;-38.95032,344.6899;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;104;-89.24693,-300.4733;Inherit;False;SobelEdgeDepth4Sample;-1;;25;c6e973b30892b0a41958c9809ead624f;0;4;1;SAMPLER2D;0;False;2;FLOAT2;0,0;False;69;FLOAT3;0.1,0.1,0.1;False;28;FLOAT;0.1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;95;1433.075,260.3312;Inherit;False;Switch;-1;;24;ef8df9ee20085f74db0149565f949658;5,28,3,30,3,29,3,15,3,9,1;17;4;INT;0;False;2;FLOAT;0;False;16;FLOAT2;0,0;False;20;FLOAT3;0,0,0;False;24;FLOAT4;0,0,0,0;False;21;FLOAT3;0,0,0;False;25;FLOAT4;0,0,0,0;False;3;FLOAT;0;False;17;FLOAT2;0,0;False;18;FLOAT2;0,0;False;26;FLOAT4;0,0,0,0;False;5;FLOAT;0;False;22;FLOAT3;0,0,0;False;23;FLOAT3;0,0,0;False;6;FLOAT;0;False;19;FLOAT2;0,0;False;27;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.LerpOp;26;2063.27,68.06087;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ComponentMaskNode;107;202.1527,-271.2361;Inherit;False;True;False;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;62;2262.811,-116.6579;Inherit;False;Property;_SobelOnly;_SobelOnly;11;0;Create;True;0;0;False;0;False;0;0;0;1;INT;0
Node;AmplifyShaderEditor.WireNode;93;2589.003,299.1078;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Compare;106;2281.093,-9.253043;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;81;2358.312,-267.7347;Inherit;False;Property;_ShowBaseImage;_ShowBaseImage;12;0;Create;True;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;63;2448.983,-105.9693;Inherit;False;0;4;0;INT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;92;2674.316,276.6561;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.InverseViewMatrixNode;100;805.6479,248.3158;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;102;1157.047,153.5755;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;99;1120.116,445.601;Inherit;False;View;World;True;Fast;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Compare;91;2719.423,-154.7705;Inherit;False;0;4;0;FLOAT;0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;3;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;67;857.0413,-910.9908;Inherit;False;Debug;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;68;2774.247,-320.9807;Inherit;False;67;Debug;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;108;2387.178,-587.2511;Inherit;True;Property;_TextureSample3;Texture Sample 3;13;0;Create;True;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;20;2931.271,-147.3331;Float;False;True;-1;2;ASEMaterialInspector;0;2;Toon/Postprocess/SobelEdge;c71b220b631b6344493ea3cf87110c93;True;SubShader 0 Pass 0;0;0;SubShader 0 Pass 0;1;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;True;2;False;-1;True;7;False;-1;False;True;0;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;8;0;10;0
WireConnection;8;1;5;1
WireConnection;9;0;10;0
WireConnection;9;1;5;2
WireConnection;79;0;8;0
WireConnection;79;1;9;0
WireConnection;79;2;80;0
WireConnection;59;1;51;0
WireConnection;59;2;21;0
WireConnection;59;69;79;0
WireConnection;12;0;8;0
WireConnection;12;1;9;0
WireConnection;12;2;11;0
WireConnection;57;0;59;0
WireConnection;58;0;57;0
WireConnection;58;1;57;1
WireConnection;58;2;57;2
WireConnection;45;1;31;0
WireConnection;45;2;21;0
WireConnection;45;69;12;0
WireConnection;71;0;58;0
WireConnection;28;0;45;0
WireConnection;74;0;71;0
WireConnection;74;1;72;0
WireConnection;41;0;28;0
WireConnection;75;0;74;0
WireConnection;75;1;73;0
WireConnection;42;0;41;0
WireConnection;42;1;34;0
WireConnection;87;0;61;0
WireConnection;84;0;75;0
WireConnection;64;0;51;0
WireConnection;64;1;21;0
WireConnection;13;0;1;0
WireConnection;13;1;21;0
WireConnection;40;0;42;0
WireConnection;40;1;33;0
WireConnection;86;0;87;0
WireConnection;76;0;84;0
WireConnection;76;1;40;0
WireConnection;85;0;86;0
WireConnection;90;0;13;0
WireConnection;65;0;64;0
WireConnection;83;0;31;0
WireConnection;88;0;61;0
WireConnection;101;0;65;1
WireConnection;101;1;103;0
WireConnection;94;4;85;0
WireConnection;94;2;40;0
WireConnection;94;3;75;0
WireConnection;94;5;76;0
WireConnection;89;0;90;0
WireConnection;104;1;105;0
WireConnection;104;2;21;0
WireConnection;104;69;12;0
WireConnection;95;4;88;0
WireConnection;95;24;83;1
WireConnection;95;25;101;0
WireConnection;95;26;89;0
WireConnection;26;0;13;0
WireConnection;26;1;25;0
WireConnection;26;2;94;0
WireConnection;107;0;104;0
WireConnection;93;0;95;0
WireConnection;106;0;107;0
WireConnection;106;2;13;0
WireConnection;106;3;26;0
WireConnection;63;0;62;0
WireConnection;63;2;106;0
WireConnection;63;3;94;0
WireConnection;92;0;93;0
WireConnection;102;0;101;0
WireConnection;99;0;65;1
WireConnection;91;0;81;0
WireConnection;91;2;63;0
WireConnection;91;3;92;0
WireConnection;67;0;58;0
WireConnection;108;0;31;0
WireConnection;20;0;91;0
ASEEND*/
//CHKSM=60A3B737758FEEE01A7018841C5871FEC05DCE44
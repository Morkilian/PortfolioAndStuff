// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Tech Art/Curve Lazer"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		[Normal]_Normal("Normal", 2D) = "white" {}
		_Albedo("Albedo", 2D) = "white" {}
		_Length("_Length", Float) = 1
		_Multiplier("Multiplier", Range( 0 , 1)) = 1
		_Slider("Slider", Range( 0 , 1)) = 0.2268263
		_UVWidthTiling("UV Width Tiling", Range( 0.01 , 2)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" }
		Cull Off
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Standard keepalpha noshadow 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Normal;
		uniform sampler2D _Albedo;
		uniform float4 _Albedo_ST;
		uniform float _Length;
		uniform float _Multiplier;
		uniform float _Slider;
		uniform float _UVWidthTiling;
		uniform float _Cutoff = 0.5;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv0_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
			float temp_output_49_0 = ( _Length * _Multiplier );
			float temp_output_72_0 = ( uv0_Albedo.y * _UVWidthTiling );
			float2 appendResult43 = (float2(( ( uv0_Albedo.x * temp_output_49_0 ) - ( temp_output_49_0 * _Slider ) ) , temp_output_72_0));
			float4 Normal70 = tex2D( _Normal, appendResult43 );
			o.Normal = Normal70.rgb;
			float4 Color64 = tex2D( _Albedo, appendResult43 );
			o.Albedo = Color64.rgb;
			o.Alpha = 1;
			float Opacity63 = step( uv0_Albedo.x , _Slider );
			clip( Opacity63 - _Cutoff );
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16600
254;92;1193;671;1150.219;-179.2713;1.3;True;False
Node;AmplifyShaderEditor.TexturePropertyNode;36;-655.1411,348.0937;Float;True;Property;_Albedo;Albedo;2;0;Create;True;0;0;False;0;16d574e53541bba44a84052fa38778df;138df4511c079324cabae1f7f865c1c1;False;white;Auto;Texture2D;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-790.7452,1091.11;Float;False;Property;_Multiplier;Multiplier;4;0;Create;True;0;0;False;0;1;0.407;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;39;-711.1633,1000.941;Float;False;Property;_Length;_Length;3;0;Create;True;0;0;False;0;1;8.070264;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;49;-427.7979,1100.93;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-617.1174,1238.012;Float;False;Property;_Slider;Slider;5;0;Create;True;0;0;False;0;0.2268263;0.831;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;37;-559.2198,661.7262;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-315.0629,970.9525;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-226.7101,1155.034;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;73;-517.3467,827.1531;Float;False;Property;_UVWidthTiling;UV Width Tiling;6;0;Create;True;0;0;False;0;0;0.2;0.01;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;72;-69.27563,748.11;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;47;-81.01134,988.3098;Float;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;67;-648.4969,155.1589;Float;True;Property;_Normal;Normal;1;1;[Normal];Create;True;0;0;False;0;None;0bebe40e9ebbecc48b8e9cfea982da7e;True;white;Auto;Texture2D;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.DynamicAppendNode;43;208.1943,706.1378;Float;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StepOpNode;46;-5.276843,1208.654;Float;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;38;242.5854,351.2334;Float;True;Property;_TextureSample0;Texture Sample 0;8;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;69;270.4043,162.5563;Float;True;Property;_TextureSample1;Texture Sample 1;6;0;Create;True;0;0;False;0;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;70;602.9983,164.8808;Float;False;Normal;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;211.7625,1203.934;Float;False;Opacity;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;64;547.0251,318.374;Float;False;Color;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;71;1088.998,361.8808;Float;False;70;Normal;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;50;18.17328,645.4996;Float;False;UVLength;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;51;-47.26663,589.7711;Float;False;UVWidth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;65;1084.118,288.5545;Float;False;64;Color;1;0;OBJECT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;66;1046.118,520.5546;Float;False;63;Opacity;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;44;1312.292,322.3796;Float;False;True;2;Float;ASEMaterialInspector;0;0;Standard;Tech Art/Curve Lazer;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;False;0;True;Opaque;;AlphaTest;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;49;0;39;0
WireConnection;49;1;40;0
WireConnection;37;2;36;0
WireConnection;41;0;37;1
WireConnection;41;1;49;0
WireConnection;48;0;49;0
WireConnection;48;1;45;0
WireConnection;72;0;37;2
WireConnection;72;1;73;0
WireConnection;47;0;41;0
WireConnection;47;1;48;0
WireConnection;43;0;47;0
WireConnection;43;1;72;0
WireConnection;46;0;37;1
WireConnection;46;1;45;0
WireConnection;38;0;36;0
WireConnection;38;1;43;0
WireConnection;69;0;67;0
WireConnection;69;1;43;0
WireConnection;70;0;69;0
WireConnection;63;0;46;0
WireConnection;64;0;38;0
WireConnection;50;0;72;0
WireConnection;51;0;37;1
WireConnection;44;0;65;0
WireConnection;44;1;71;0
WireConnection;44;10;66;0
ASEEND*/
//CHKSM=E4162AFFD6EB7B640BB89316ED63994F1CE13274
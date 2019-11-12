Shader "Toon Shading/Toon Solid" {
	Properties {
	    [HDR]
		_Color ("Color", Color) = (1,1,1,1)
		_Ambient ("Ambient", Range(0,1)) = 0.4
		_HueAdjust ("Hue Adjustment In Darkness", Range(0,1)) = 0.25
		_SatAdjust ("Saturation Adjustment In Darkness", Range(0,1)) = 0.35
		_LightColorInfluence ("Light Color Influence", Range(0,1)) = 0.75
		_AlbedoTex ("Color Texture", 2D) = "white" {}
		_MainSpecular ("Specular", Range(0,1)) = 0.75
		_Gloss ("Gloss", Range(0,1)) = 0.5
		[HDR]
		_SpecularTint ("Specular Color", Color) = (1,1,1,1)
		_SpecularTex ("Specular Map", 2D) = "white" {}
		_Rim ("Rim", Range(0,1)) = 0.25
		_RimWidth ("Rim Width", Range(0,1)) = 0.4
		[HDR]
		_RimTint ("Rim Color", Color) = (1,1,1,1)
		[Normal]
		_NormalTex ("Bump Map", 2D) = "bump" {}
		_Depth ("Bump Depth", Range(-2,2)) = 1.0
		_ToonShaderRampTex ("Lighting Ramp", 2D) = "" {}
	}
	SubShader {
	    Pass {
            Tags { "LightMode" = "ForwardBase" }
    
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "ToonUtility.cginc"
            
            #pragma vertex toonVert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            sampler2D _AlbedoTex;
            float4 _AlbedoTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            sampler2D _SpecularTex;
            float4 _SpecularTex_ST;
            sampler2D _ToonShaderRampTex;
            float4 _ToonShaderRampTex_ST;
            
            half _MainSpecular;
            half _LightColorInfluence;
            half _Ambient;
            half _Gloss;
            half _Rim;
            half _RimWidth;
            half _HueAdjust;
            half _SatAdjust;
            half _Depth;
            fixed4 _Color;
            fixed4 _SpecularTint;
            fixed4 _RimTint;
			
			
			fixed4 frag(fragIN i) : SV_Target {
			    // uvs
			    float2 specUV = i.uv.xy * _SpecularTex_ST.xy + _SpecularTex_ST.zw;
			    float2 normUV = i.uv.xy * _NormalTex_ST.xy + _NormalTex_ST.zw;
			    float2 albedoUV = i.uv.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw;
			    
			    float3 view = normalize(i.view);
			    float atten = LIGHT_ATTENUATION(i);
			    
			    ToonFragData data = ProcessToonFragInput(
			        i, atten, view, _NormalTex, _Depth, normUV,
			        _SpecularTex, _MainSpecular, _Gloss, specUV,
			        _RimWidth, _ToonShaderRampTex, _ToonShaderRampTex_ST
			    );
			    
			    float3 light = lerp(float3(1,1,1), _LightColor0.rgb, _LightColorInfluence);
			    
			    float3 albedo = tex2D(_AlbedoTex, albedoUV) * _Color;
			    float3 ambient = (1 - data.intensity) * (_Ambient * light * albedo);
			    albedo *=  light * data.intensity;
			    
			    float3 specular = _SpecularTint * data.specular;
			    float3 rimLight = _RimTint * data.rim * _Rim;
			    
			    // composite and darkness adjustments
			    float3 mixed = albedo + ambient + specular + rimLight;
			    half3 output = adjustedDarkness(mixed, 1 - data.intensity, _HueAdjust, _SatAdjust);
			    
			    return fixed4(output, 1);
			}
            ENDCG
	    }
	    
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            BlendOp Max
    
            CGPROGRAM
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "ToonUtility.cginc"
            
            #pragma vertex toonVert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            
            sampler2D _AlbedoTex;
            float4 _AlbedoTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;
            sampler2D _SpecularTex;
            float4 _SpecularTex_ST;
            sampler2D _ToonShaderRampTex;
            float4 _ToonShaderRampTex_ST;
            
            half _MainSpecular;
            half _LightColorInfluence;
            half _Ambient;
            half _Gloss;
            half _Rim;
            half _RimWidth;
            half _HueAdjust;
            half _SatAdjust;
            half _Depth;
            fixed4 _Color;
            fixed4 _SpecularTint;
            fixed4 _RimTint;
			
			
			fixed4 frag(fragIN i) : SV_Target {
			    // uvs
			    float2 specUV = i.uv.xy * _SpecularTex_ST.xy + _SpecularTex_ST.zw;
			    float2 normUV = i.uv.xy * _NormalTex_ST.xy + _NormalTex_ST.zw;
			    float2 albedoUV = i.uv.xy * _AlbedoTex_ST.xy + _AlbedoTex_ST.zw;
			    
			    float3 view = normalize(i.view);
			    float atten = LIGHT_ATTENUATION(i);
			    
			    ToonFragData data = ProcessToonFragInput(
			        i, atten, view, _NormalTex, _Depth, normUV,
			        _SpecularTex, _MainSpecular, _Gloss, specUV,
			        _RimWidth, _ToonShaderRampTex, _ToonShaderRampTex_ST
			    );
			    
			    float3 light = lerp(float3(1,1,1), _LightColor0.rgb, _LightColorInfluence);
			    
			    float3 albedo = tex2D(_AlbedoTex, albedoUV) * _Color;
			    float3 ambient = (1 - data.intensity) * (_Ambient * light * albedo);
			    albedo *=  light * data.intensity;
			    
			    float3 specular = _SpecularTint * data.specular;
			    
			    // composite and darkness adjustments
			    float3 mixed = albedo + ambient + specular;
			    half3 output = adjustedDarkness(mixed, 1 - data.intensity, _HueAdjust, _SatAdjust);
			    
			    return fixed4(output, 1);
			}
            ENDCG
	    }
	    
	    UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
	}
}

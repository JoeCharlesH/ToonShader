Shader "Toon Shading/Toon Solid" {
    Properties {
	    [HDR]
        _Color ("Color", Color) = (0.75,0.75,0.75,1)
        [HDR]
        _Ambient ("Ambient", Color) = (.1,.1,.1,.1)
        _HueAdjust ("Hue Adjustment In Darkness", Range(0,1)) = 0.35
        _SatAdjust ("Saturation Adjustment In Darkness", Range(0,1)) = 0.35
        _LightColorInfluence ("Light Color Influence", Range(0,1)) = 0.75
        _AlbedoTex ("Color Texture", 2D) = "white" {}
        _MainSpecular ("Specular", Range(0,1)) = 0.75
        _Gloss ("Gloss", Range(0,1)) = 0.5
        [HDR]
        _SpecularTint ("Specular Color", Color) = (1,1,1,1)
        _SpecularTex ("Specular Map", 2D) = "white" {}
        _Rim ("Rim", Range(0,1)) = 0.1
        _RimWidth ("Rim Width", Range(0,1)) = 0.175
        [HDR]
        _RimTint ("Rim Color", Color) = (1,1,1,1)
        [Normal]
        _NormalTex ("Bump Map", 2D) = "bump" {}
        _Depth ("Bump Depth", Range(-2,2)) = 1.0
        _ToonShaderRampTex ("Lighting Ramp", 2D) = "" {}
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM
        #pragma surface surf Toon fullforwardshadows
        #include "UnityGlobalIllumination.cginc"
        #include "ToonUtility.cginc"
        
        sampler2D _AlbedoTex;
        sampler2D _NormalTex;
        sampler2D _SpecularTex;
        sampler2D _ToonShaderRampTex;
        float4 _ToonShaderRampTex_ST;
        
        half _MainSpecular;
        half _LightColorInfluence;
        half _Gloss;
        half _Rim;
        half _RimWidth;
        half _HueAdjust;
        half _SatAdjust;
        half _Depth;
        fixed4 _Ambient;
        fixed4 _Color;
        fixed4 _SpecularTint;
        fixed4 _RimTint;
        
        struct Input {
            float2 uv_AlbedoTex;
            float2 uv_NormalTex;
            float2 uv_SpecularTex;
        };
        
        half4 LightingToon (SurfaceOutput s, half3 view, UnityGI gi) {
            half3 attenVec = gi.light.color / max(_LightColor0.rgb, 0.0001);
            half atten = length(gi.light.color) / 1.7321;
            float3 lightHSV = rgb2hsv(_LightColor0.rgb);
            
            ToonFragData data = ProcessToonFragInput(
                gi.light.dir, atten, view, s.Normal * _Depth, s.Specular,
                _Gloss * lightHSV.z, _RimWidth, _ToonShaderRampTex, _ToonShaderRampTex_ST
            );
            
            float3 light = hsv2rgb(float3(lightHSV.x, lerp(0, lightHSV.y, _LightColorInfluence), min(data.intensity, 1)));
            
            float3 albedo = s.Albedo * light * data.intensity;
            
            float3 specular = _SpecularTint * data.specular;
            float3 rimLight = _RimTint * data.rim * _Rim;
            
            // composite and darkness adjustments
            float3 mixed = albedo + specular + rimLight;
            
            #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
                mixed += s.Albedo * gi.indirect.diffuse * _Ambient;
            #endif
            
            half3 output = adjustedDarkness(mixed, saturate(1 - length(mixed)), _HueAdjust, _SatAdjust);
            
            return half4(output, 1);
        }
        
        void LightingToon_GI(SurfaceOutput s, UnityGIInput data, inout UnityGI gi) {
            gi = UnityGlobalIllumination (data, 1.0, s.Normal);
        }
        
        void surf(Input IN, inout SurfaceOutput o) {
            float sqrt3 = 1.7321;
            
            o.Albedo = tex2D(_AlbedoTex, IN.uv_AlbedoTex) * _Color;
            o.Specular = (length(tex2D(_SpecularTex, IN.uv_SpecularTex).rgb) / sqrt3) * _MainSpecular;
            o.Normal = UnpackNormal (tex2D (_NormalTex, IN.uv_NormalTex));
        }
        ENDCG
    }
    Fallback "Diffuse"
}

Shader "Toon Shading/Toon Tinted Solid" {
    Properties {
        [Header(Main Color)]
	    [HDR]
	    _AlbedoTex ("Color Texture", 2D) = "white" {}
        _Color ("Color", Color) = (0.75,0.75,0.75,1)
        [HDR]
        _Ambient ("Ambient", Color) = (.1,.1,.1,.1)
        
        [Header(Tint)]
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _TintBias ("Default Tint", Range(0,1)) = 0
        _HW ("Hue Weight", Range(0, 4)) = 0.5
        _SW ("Saturation Weight", Range(0, 4)) = 0.5
        _VW ("Value Weight", Range(0,4)) = 0.5
        
        [Header(Lighting)]
        _HueAdjust ("Primary Shadows", Range(0,1)) = 0.35
        _SatAdjust ("Vibrant Shadows", Range(0,1)) = 0.35
        _LightColorInfluence ("Light Color Influence", Range(0,1)) = 0.75
        _LightThreshold("Light Threshold", Range(0,1)) = 0.5
        _Bands("Bands", Range(1,4)) = 1
        
        [Header(Specular)]
        _SpecularTex ("Specular Map", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 0.5
        [HDR]
        _SpecularTint ("Specular Color", Color) = (1,1,1,1)
        
        [Header(Rim Lighting)]
        _RimWidth ("Rim Width", Range(0,1)) = 0.175
        [HDR]
        _RimTint ("Rim Color", Color) = (1,1,1,1)
        [Toggle(SHADOWED_RIM)]
        _ShadowedRim("Shadow Affects Rim", float) = 0
        
        [Header(Emission)]
        _EmissionTex ("Emission Map", 2D) = "white" {}
        _MainEmission ("Emission", Range(0,1)) = 0.75
        [HDR]
        _EmissionTint ("Emission Color", Color) = (1,1,1,1)
        
        [Header(Normals)]
        [Normal]
        _NormalTex ("Bump Map", 2D) = "bump" {}
        _Depth ("Bump Depth", Range(-2,2)) = 1.0
    }
    SubShader {
        Tags { "RenderType" = "Opaque" }

        CGPROGRAM
        #pragma surface surf Toon fullforwardshadows
        #pragma shader_feature SHADOWED_RIM
        #include "UnityGlobalIllumination.cginc"
        #include "ToonUtility.cginc"
        
        sampler2D _AlbedoTex;
        sampler2D _NormalTex;
        sampler2D _SpecularTex;
        sampler2D _EmissionTex;
        
        float _MainSpecular;
        float _MainEmission;
        float _LightColorInfluence;
        float _LightThreshold;
        float _Bands;
        float _Gloss;
        float _RimWidth;
        float _ShadowedRim;
        float _HueAdjust;
        float _SatAdjust;
        float _Depth;
        float _TintBias;
        float _HW;
        float _SW;
        float _VW;
        
        float4 _BaseColor;
        float4 _Tint;
        float4 _Ambient;
        float4 _Color;
        float4 _SpecularTint;
        float4 _RimTint;
        float4 _EmissionTint;
        
        struct Input {
            float2 uv_AlbedoTex;
            float2 uv_NormalTex;
            float2 uv_SpecularTex;
            float2 uv_EmissionTex;
        };
        
        float4 LightingToon (SurfaceOutput s, float3 view, UnityGI gi) {
            float atten = length(gi.light.color) / 1.7321;
            float3 ld = gi.light.dir;
            float ndl = saturate(dot(s.Normal, ld));
            float shadow = round(saturate(ndl * atten / _LightThreshold) * _Bands) / _Bands;
            
            float3 r = reflect(ld, s.Normal);
            float vdr = dot(view, -r);
            float vdn = saturate(dot(normalize(view), s.Normal));
            
            float3 spec = _SpecularTint.rgb * step(s.Specular, vdr);
            float3 rim = _RimTint.rgb * step(1 - _RimWidth, 0.99 - vdn);
            
            float3 lightHSV = rgb2hsv(gi.light.color.rgb);
            float3 light = hsv2rgb(float3(lightHSV.x, lerp(0, lightHSV.y, _LightColorInfluence), 1));
            
            float3 mixed = ((s.Albedo + spec) * light);
            float3 ambient = s.Albedo * _Ambient.rgb;
            
            #ifdef SHADOWED_RIM
                mixed = (mixed + rim) * shadow;
            #else
                mixed = (mixed * shadow) + rim;
            #endif
            
            #ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
                mixed += ambient * gi.indirect.diffuse;
            #endif
            
            float3 output = adjustedDarkness(mixed , saturate(1 - length(mixed)), _HueAdjust, _SatAdjust);
            
            return float4(output, 1);
        }
        
        void LightingToon_GI(SurfaceOutput s, UnityGIInput data, inout UnityGI gi) {
            gi = UnityGlobalIllumination (data, 1.0, s.Normal);
        }
        
        void surf(Input IN, inout SurfaceOutput o) {
            float sqrt3 = 1.7321;
            
            float4 a = tex2D(_AlbedoTex, IN.uv_AlbedoTex);
            float3 aHSV = rgb2hsv(a.rgb);
            float3 bHSV = rgb2hsv(_BaseColor.rgb);
            
            float3 diff = aHSV - bHSV;
            float weight = saturate(dot(diff * diff, float3(_HW, _SW, _VW)) + _TintBias);
            
            float4 tinted = a.rgba;
            tinted.rgb = lerp(tinted.rgb * _Color.rgb, _Tint.rgb, weight);
            
            o.Albedo = tinted;
            o.Specular = (length(tex2D(_SpecularTex, IN.uv_SpecularTex).rgb) / sqrt3) * (1 - _Gloss);
            o.Emission = o.Albedo * tex2D(_EmissionTex, IN.uv_EmissionTex).rgb * _EmissionTint.rgb * _MainEmission;
            o.Normal = UnpackNormal (tex2D (_NormalTex, IN.uv_NormalTex));
        }
        ENDCG
    }
    Fallback "Diffuse"
}

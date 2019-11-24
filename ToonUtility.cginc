#ifndef TOONUTILITY_INCLUDED
#define TOONUTILITY_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

// implimentation of rgb2hsv conversion equation
half3 rgb2hsv(half3 c) {
    half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
    half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

    half d = q.x - min(q.w, q.y);
    half e = 1.0e-10;
    return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// implimentation of hsv2rgb conversion equation
half3 hsv2rgb(half3 c) {
    half4 K = half4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    half3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

half smoothRound(half x, half a) {
    half fx = floor(x);
    half halfa = a / 2;
    return (tanh((a * x) - (a * fx) - halfa) / (2 * tanh(halfa))) + 0.5 + fx;
}

half hueLerp(half hue1, half hue2, half t) {
    half h;
    half d = hue2 - hue1;
    
    if (hue1 > hue2) {
        half h2 = hue2;
        hue2 = hue1;
        hue1 = h2;
        d = -d;
        t = 1 - t;
    }
    
    if (d > 0.5) {
        hue1 += 1;
        h = (hue1 + t * (hue2 - hue1)) % 1; 
    }
    else {
        h = hue1 + t * d;
    }
    
    return h;
}

// turns color into a more saturated version of itself that is closer to its roygbiv equivalent 
half3 adjustedDarkness(half3 color, half level, half hue, half sat) {
    half3 hsv = rgb2hsv(color);
    half primaryH = smoothRound(hsv.x * 8.0, 1 + (31.0 * hue * level)) / 8.0;
    return hsv2rgb(half3(saturate(primaryH), saturate(hsv.y * (level * sat + 1)), hsv.z));
}

struct ToonFragData {
    float intensity;
    float specular;
    float rim;
    float darkFilter;
};

ToonFragData ProcessToonFragInput(float3 lightDir, float atten, float3 view, float3 normal, float specScalar, float gloss, float rimWidth, sampler2D ramp, float4 rampST) {
    // normal mapping
    float sqrt3 = 1.7321;
    ToonFragData o;
    
    // intensity calculation
    float ndl = dot(lightDir, normal);
    float baseIntensity = max(ndl, 0);
    float2 rampUV = half2(baseIntensity * atten, 0.5) * rampST.xy + rampST.zw;
    o.intensity = length(tex2D(ramp, rampUV).rgb) / sqrt3;
    o.darkFilter = step(0.3, o.intensity);
    
    // specular calculation
    float3 h = normalize(lightDir + view);
    float3 ndh = dot(normal, h);
    float specExp = 1 - specScalar;
    float spec = pow(ndh * o.intensity, 256 * specExp) * gloss;
    rampUV = half2(spec, 0.5) * rampST.xy + rampST.zw;
    o.specular = pow(length(tex2D(ramp, rampUV).rgb) / sqrt3, 2);
    
    // rim calculation
    half rimDot = 1 - dot(view, normal);
    half rim = rimDot * o.darkFilter * rimWidth * 8;
    rampUV = half2(rim * rim, 0.5) * rampST.xy + rampST.zw;
    o.rim = length(tex2D(ramp, rampUV).rgb) / 1.7321;
    
    return o;
}
#endif
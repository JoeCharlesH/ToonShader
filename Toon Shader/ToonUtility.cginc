#ifndef TOONUTILITY_INCLUDED
#define TOONUTILITY_INCLUDED

#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"

// implimentation of rgb2hsv conversion equation
float3 rgb2hsv(float3 c) {
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// implimentation of hsv2rgb conversion equation
float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float smoothRound(float x, float a) {
    float fx = floor(x);
    float floata = a / 2;
    return (tanh((a * x) - (a * fx) - floata) / (2 * tanh(floata))) + 0.5 + fx;
}

float hueLerp(float hue1, float hue2, float t) {
    float h;
    float d = hue2 - hue1;
    
    if (hue1 > hue2) {
        float h2 = hue2;
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
float3 adjustedDarkness(float3 color, float level, float hue, float sat) {
    float3 hsv = rgb2hsv(color);
    float primaryH = smoothRound(hsv.x * 8.0, 1 + (31.0 * hue * level)) / 8.0;
    return hsv2rgb(float3(saturate(primaryH), saturate(hsv.y * (level * sat + 1)), hsv.z));
}
#endif
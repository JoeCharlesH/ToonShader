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

// find closest roygbiv color to the current hue.
half hueStep(half h) {
    return ((floor(h * 7) / 6) + 0.015h) / 1.015h;
}

// turns color into a more saturated version of itself that is closer to its roygbiv equivalent 
half3 adjustedDarkness(half3 color, half level, half hue, half sat) {
    half3 hsv = rgb2hsv(color);
    half targetH = hueStep(hsv.x);
    return hsv2rgb(half3(saturate(lerp(hsv.x, targetH, hue * level)), saturate(hsv.y * (level * sat + 1)), hsv.z));
}

struct vertIN {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float4 uv : TEXCOORD0;
};

struct fragIN {
    float4 pos : SV_POSITION;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float3 bitangent : TEXCOORD0;
    float2 uv : TEXCOORD1;
    float3 view : TEXCOORD2;
    float3 lightDir : TEXCOORD3;
    SHADOW_COORDS(4)
    DECLARE_LIGHT_COORDS(5)
};

struct ToonFragData {
    float3 normal;
    float intensity;
    float specular;
    float rim;
    float darkFilter;
};

ToonFragData ProcessToonFragInput(fragIN i, float atten, float3 view, sampler2D normalMap, float depth, float2 normalUV, sampler2D specularMap, float specScalar, float gloss, float2 specularUV, float rimWidth, sampler2D ramp, float4 rampST) {
    // normal mapping
    float sqrt3 = 1.7321;
    ToonFragData o;
    float3 tNorm = float3(tex2D(normalMap, normalUV).ag * 2 - 1, depth);
    o.normal = normalize(float3(i.tangent * tNorm.x + i.bitangent * tNorm.y + i.normal * tNorm.z));
    
    // intensity calculation
    float ndl = dot(i.lightDir, o.normal);
    float baseIntensity = max(ndl, 0);
    float2 rampUV = half2(baseIntensity * atten, 0.5) * rampST.xy + rampST.zw;
    o.intensity = length(tex2D(ramp, rampUV).rgb) / sqrt3;
    o.darkFilter = step(0.3, o.intensity);
    
    // specular calculation
    float3 h = normalize(i.lightDir + view);
    float3 ndh = dot(o.normal, h);
    float specExp = 1 - length(tex2D(specularMap, specularUV).rgb / sqrt3) * specScalar;
    float spec = pow(ndh * o.intensity, 256 * specExp) * gloss;
    rampUV = half2(spec, 0.5) * rampST.xy + rampST.zw;
    o.specular = pow(length(tex2D(ramp, rampUV).rgb) / sqrt3, 2);
    
    // rim calculation
    half rimDot = 1 - dot(view, o.normal);
    half rim = rimDot * o.darkFilter * rimWidth * 8;
    rampUV = half2(rim * rim, 0.5) * rampST.xy + rampST.zw;
    o.rim = length(tex2D(ramp, rampUV).rgb) / 1.7321;
    
    return o;
}

fragIN toonVert(vertIN v) {
    fragIN fragInput;
    
    fragInput.pos = UnityObjectToClipPos(v.vertex);
    fragInput.uv = v.uv;
    // UnityWorldSpaceViewDir requires world pos instead of vertex
    fragInput.view = WorldSpaceViewDir(v.vertex);
    fragInput.lightDir = UnityWorldSpaceLightDir(v.vertex);
    
    fragInput.tangent = UnityObjectToWorldNormal(v.tangent);
    fragInput.normal = UnityObjectToWorldNormal(v.normal);
    fragInput.bitangent = normalize(cross(fragInput.tangent, fragInput.normal));
    
    TRANSFER_SHADOW(fragInput)
    COMPUTE_LIGHT_COORDS(fragInput)
    return fragInput;
}
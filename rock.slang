/*
Copyright 2014 Alexander Alekseev @TDM
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ldSSzV
*/

/******************************************************************************
 This work is a derivative of work by Alexander Alekseev used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef rock_glsl
#define rock_glsl

// Noise functions
// These are taken from https://www.shadertoy.com/view/ldSSzV
float hash11(float p)
{
    return frac(sin(p * 727.1) * 435.545);
}
float hash12(float2 p)
{
    float h = dot(p, float2(127.1, 311.7));
    return frac(sin(h) * 437.545);
}
float3 hash31(float p)
{
    float3 h = float3(127.231, 491.7, 718.423) * p;
    return frac(sin(h) * 435.543);
}
// 3d noise
float noise_3(in float3 p)
{
    float3 i = floor(p);
    float3 f = frac(p);
    float3 u = f * f * (3.0 - 2.0 * f);
    
    float2 ii = i.xy + i.z * float2(5.0);
    float a = hash12(ii + float2(0.0, 0.0));
    float b = hash12(ii + float2(1.0, 0.0));
    float c = hash12(ii + float2(0.0, 1.0));
    float d = hash12(ii + float2(1.0, 1.0));
    float v1 = lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
    
    ii += float2(5.0);
    a = hash12(ii + float2(0.0, 0.0));
    b = hash12(ii + float2(1.0, 0.0));
    c = hash12(ii + float2(0.0, 1.0));
    d = hash12(ii + float2(1.0, 1.0));
    float v2 = lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
        
    return max(lerp(v1, v2, u.z), 0.0);
}
float fbm3_high(float3 p, float a, float f)
{
    float ret = 0.0;
    float amp = 1.0;
    float frq = 1.0;
    for (int i = 0; i < 5; i++)
    {
        float n = pow(noise_3(p * frq), 2.0);
        ret += n * amp;
        frq *= f;
        amp *= a * (pow(n, 0.2));
    }
    return ret;
}

static const float DISPLACEMENT = 0.1;

// distance functions
float plane(float3 gp, float4 p)
{
    return dot(p.xyz, gp + p.xyz * p.w);
}
float rock_sphere(float3 p, float r)
{
    return length(p) - r;
}
float capsule(float3 p, float r, float h)
{
    p.y -= clamp(p.y, -h, h);
    return length(p) - r;
}
float cylinder(float3 p, float r, float h)
{
    return max(abs(p.y / h), capsule(p, r, h));
}
float rrbox(float3 p, float3 s)
{
    p = abs(p) - s;
    return max(max(p.x, p.y), p.z);
}
float rbox(float3 p, float3 s)
{
    p = abs(p) - s;
    return length(p - min(p, 0.0));
}
float quad(float3 p, float2 s)
{
    p = abs(p) - float3(s.x, 0.0, s.y);
    return max(max(p.x, p.y), p.z);
}

// boolean operations
float boolUnion(float a, float b)
{
    return min(a, b);
}
float boolIntersect(float a, float b)
{
    return max(a, b);
}
float boolSub(float a, float b)
{
    return max(a, -b);
}

// smooth operations. thanks to iq
float boolSmoothIntersect(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(a, b, h) + k * h * (1.0 - h);
}
float boolSmoothSub(float a, float b, float k)
{
    return boolSmoothIntersect(a, -b, k);
}

float rock(float3 p)
{
    float d = rock_sphere(p, 1.0);
    for (int i = 0; i < 9; i++)
    {
        float ii = float(i);
        float r = 2.5 + hash11(ii);
        float3 v = normalize(hash31(ii) * 2.0 - 1.0);
        d = boolSub(d, rock_sphere(p + v * r, r * 0.8));
    }
    return d;
}

float map_detailed(float3 p)
{
    float d = rock(p) + fbm3_high(p * 4.0, 0.4, 2.96) * DISPLACEMENT;
    return d;
}

float rocksdf(float3 p)
{
    const float scale = 0.8;
    p *= 1. / scale;
    return map_detailed(p) * scale * 0.7;
}

#endif

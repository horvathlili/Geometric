/*
Copyright 2018 Wes Bakane @WB
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4tKfWW
*/

/******************************************************************************
 This work is a derivative of work by Wes Bakane used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

float vsdSphere(float3 pos, float3 center, float radius)
{
    return length(center - pos) - radius;
}

float vsdPlane(float3 p, float4 n)
{
    return dot(p, n.xyz) + n.w;
}

float sdCappedCylinder(float3 p, float2 h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Boolean operations for distance fields
float opUnion(float d1, float d2)
{
    return min(d1, d2);
}

float opSubtraction(float d1, float d2)
{
    return max(-d1, d2);
}

float opIntersection(float d1, float d2)
{
    return max(d1, d2);
}

float vopSmoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}

float opShell(float d, float thickness)
{
    return abs(d) - thickness;
}

float vmap(float3 pos)
{
    float freq = 6.0;

    float d1 = sdCappedCylinder(pos, float2(0.2, 0.75));
    float d2 = vsdSphere(pos, float3(0.0, -0.25, 0.0), 0.45);
    float d3 = vsdSphere(pos, float3(0.0, 1.0, 0.0), 0.4);
    float d4 = sdCappedCylinder(pos + float3(0.0, -1.75, 0.0), float2(1.0, 1.0));

    float df = vopSmoothUnion(d1, d2, 0.2);
    df = vopSmoothUnion(df, d3, 0.2);
    df = opShell(df, 0.01);
    df = opSubtraction(d4, df);
    df += cos(pos.y * 100.0) / 300.0;

    return df;
}

float vasesdf(float3 p)
{
    const float scale = 1.0;
    p *= 1. / scale;
    return vmap(p) * scale;
}

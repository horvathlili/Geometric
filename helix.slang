/*
Copyright 2016 Xor @XorDev
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/Md3XRM
*/

/******************************************************************************
 This work is a derivative of work by XorDev used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

static float FULL_SIZE = 1.0;
static float EDGE_SIZE = 0.2;
static float PAIR_SIZE = 0.2;



float opSmoothSubtraction(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

float sdBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float model(float3 p)
{
    float A = p.z / 3.0;
    float3 R = float3(cos(A), sin(A), 0);
    float3 C = float3(p.xy + R.yx * float2(1, -1), frac(p.z) - 0.5);

    float H = min(length(C.xy + R.xy * FULL_SIZE), length(C.xy - R.xy * FULL_SIZE)) * 0.5 - EDGE_SIZE;
    float P = max(length(float2(dot(C.xy, R.yx * float2(1, -1)), C.z)) - PAIR_SIZE,
                length(C.xy) - FULL_SIZE);

    float D = min(H, P);
    return D;
}

/*float sdf(float3 p)
{
    float boxD = sdBox(p, float3(1., 1., 1.));
    const float scale = 0.125;
    p *= 1. / scale;
    return max(boxD, model(p * RotMat(float3(1., 0., 0.), pi / 2.))) * scale;
}*/

/*
Copyright 2020 Flopine @Flopine
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/wssBDf
*/

/******************************************************************************
 This work is a derivative of work by Flopine used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

//#define PI 3.141592

float2x2 rot(float a)
{
    return float2x2(cos(a), sin(a), -sin(a), cos(a));
}

float cyl(float3 p, float r, float h)
{
    return max(length(p.xy) - r, abs(p.z) - h);
}

float tore(float3 p, float2 t)
{
    return length(float2(length(p.xz) - t.x, p.y)) - t.y;
}

float key(float3 p, float t)
{
    float thick = t;
    float body = cyl(p.xzy, thick, 1.5);
    float encoche = tore(p.xzy + float3(-(2. * thick), 0.05, 1.), float2(thick, 0.1));
    float head = max(-cyl(p - float3(0., 2.2, 0.), 0.65, thick * 1.5),
                   cyl(p - float3(0., 2.2, 0.), 0.8, thick));
    p.y = abs(abs(p.y - 0.45) - 0.8) - 0.15;
    float ts = tore(p, float2(thick, 0.08));

    return min(encoche, min(min(body, head), ts));
}

float keySDF(float3 p)
{
    float3 pp = p - float3(0., 2., 0.);
    float small = 3.5;
    float thick = 0.25;
    float d = key(p, thick);
    for (int i = 0; i < 2; i++)
    {
        d = min(d, key(pp * small, thick) / small);
        pp.y -= 0.55;
        small *= 4.;
    }
    return d;
}

float keysdf(float3 p)
{
    p += float3(0., .2, 0.);
    const float scale = 0.3;
    p *= 1. / scale;
    return keySDF(p) * scale;
}

/*
Copyright 2020 Towaki Takikawa @yongyuanxi
The MIT License
Link: N/A
*/

/******************************************************************************
 * The MIT License (MIT)
 * Copyright (c) 2021, NVIDIA CORPORATION.
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#ifndef knob_glsl
#define knob_glsl

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// helper maths
/////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// distance functions
// taken from https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

float ksdSphere(float3 v, float r)
{
    return length(v) - r;
}

float ksdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdCone(float3 p, float2 c)
{
  // c is the sin/cos of the angle
    float q = length(p.xy);
    return dot(c, float2(q, p.z));
}

float sdCappedCylinder(float3 p, float h, float r)
{
    float2 d = abs(float2(length(p.xz), p.y)) - float2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTriPrism(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

float kopSmoothUnion(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return lerp(d2, d1, h) - k * h * (1.0 - h);
}
float ssub(float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0);
    return lerp(d2, -d1, h) + k * h * (1.0 - h);
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// actual distance functions
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

float sdBase(float3 p)
{
    // Intersect two cones
    float base = kopSmoothUnion(sdCone(mul((p + float3(0., .9, 0.)), RotMat(float3(1., 0., 0.), -PI / 2.)),
                                       float2(PI / 3., PI / 3.)),
                               sdCone(mul((p - float3(0., .9, 0.)), RotMat(float3(1., 0., 0.), PI / 2.)),
                                       float2(PI / 3., PI / 3.)),
                               0.02);
    // Bound the base radius
    base = max(base, sdCappedCylinder(p, 1.1, 0.25)) * 0.7;
    // Dig out the center
    base = max(-sdCappedCylinder(p, 0.6, 0.3), base);
    // Cut a slice of the pie
    base = max(-sdTriPrism(mul((p + float3(0., 0., -1.)), RotMat(float3(1., 0., 0.), PI / 2.)), float2(1.2, 0.3)), base);
    return base;
}

float sdKnob(float3 p)
{
    float sphere = ksdSphere(p, 1.0);
    float cutout = ksdSphere(p - float3(0.0, 0.5, 0.5), 0.7);
    float cutout_etch = ksdTorus(mul((p - float3(0.0, 0.2, 0.2)), RotMat(float3(1., 0., 0.), -PI / 4.)), float2(1.0, 0.05));
    float innersphere = ksdSphere(p - float3(0.0, 0.0, 0.0), 0.75);

    // Cutout sphere
    float d = ssub(cutout, sphere, 0.1);

    // Add eye, etch the sphere
    d = min(d, innersphere);
    d = max(-cutout_etch, d);

    // Add base
    d = min(ssub(sphere,
                 sdBase(p - float3(0., -.775, 0.)), 0.1), d);
    return d;
}

float knobsdf(float3 p)
{
    const float scale = 0.8;
    p *= 1. / scale;
    return sdKnob(p) * scale;
}

#endif

/*
Copyright 2015 Nimitz @nimitz
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/ltfGDs
*/

/******************************************************************************
 This work is a derivative of work by Nimitz used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

// Global material id (keeps code cleaner)
static float matid = 0.;

//--------------------Utility, Domain folding and
//Primitives---------------------
float tri(in float x)
{
    return abs(frac(x) - .5);
}
float3x3 rot_x(float a)
{
    float sa = sin(a);
    float ca = cos(a);
    return float3x3(1., .0, .0, .0, ca, sa, .0, -sa, ca);
}
float3x3 rot_y(float a)
{
    float sa = sin(a);
    float ca = cos(a);
    return float3x3(ca, .0, sa, .0, 1., .0, -sa, .0, ca);
}
float3x3 rot_z(float a)
{
    float sa = sin(a);
    float ca = cos(a);
    return float3x3(ca, sa, .0, -sa, ca, .0, .0, .0, 1.);
}
float3 rotz(float3 p, float a)
{
    float s = sin(a), c = cos(a);
    return float3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

float2 nmzHash22(float2 q)
{
    uint2 p =uint2(int2(q));
    p = p * uint2(3266489917U, 668265263U) + p.yx;
    p = p * (p.yx ^ (p >> 15U));
    return float2(p ^ (p >> 16U)) * (1.0 / float2(0xffffffffU));
}

float3 nmzHash33(float3 q)
{
    uint3 p = uint3(int3(q));
    p = p * uint3(374761393U, 1103515245U, 668265263U) + p.zxy + p.yzx;
    p = p.yzx * (p.zxy ^ (p >> 3U));
    return float3(p ^ (p >> 16U)) * (1.0 / float3(0xffffffffU));
}

// 2dFoldings, inspired by Gaz/Knighty  see:
// https://www.shadertoy.com/view/4tX3DS
float2 foldHex(in float2 p)
{
    p.xy = abs(p.xy);
    const float2 pl1 = float2(-0.5, 0.8657);
    const float2 pl2 = float2(-0.8657, 0.5);
    p -= pl1 * 2. * min(0., dot(p, pl1));
    p -= pl2 * 2. * min(0., dot(p, pl2));
    return p;
}

float2 foldOct(in float2 p)
{
    p.xy = abs(p.xy);
    const float2 pl1 = float2(-0.7071, 0.7071);
    const float2 pl2 = float2(-0.9237, 0.3827);
    p -= pl1 * 2. * min(0., dot(p, pl1));
    p -= pl2 * 2. * min(0., dot(p, pl2));

    return p;
}

float sbox(float3 p, float3 b)
{
    float3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float cyl(float3 p, float2 h)
{
    float2 d = abs(float2(length(p.xz), p.y)) - h;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float torus(float3 p, float2 t)
{
    return length(float2(length(p.xz) - t.x, p.y)) - t.y;
}

// using floor() in a SDF causes degeneracy.
float smoothfloor(in float x, in float k)
{
    float xk = x + k * 0.5;
    return floor(xk - 1.) + smoothstep(0., k, frac(xk));
}

float hexprism(float3 p, float2 h)
{
    float3 q = abs(p);
    return max(q.z - h.y, max((q.y * 0.866025 + q.x * 0.5), q.x) - h.x);
}

//------------------------------------------------------------------------

// float3 position(in float3 p) {
//   float dst = 7.;
//   float id = floor(p.z / dst * .1);
//   p.xy += sin(id * 10. + time);
//   p.z += sin(id * 10. + time * 0.9) * .5;
//   p = rotz(p, sin(time * 0.5) * 0.5 + id * 0.1);
//   p.z = (abs(p.z) - dst) * sign(p.z);
//   return p;
// }

float tfmap(float3 p)
{
    matid = 0.;
    float3 bp = p; // keep original coords around

    float mn = length(bp) - .7; // main ball

  // Cockpit
    p.z -= 0.8;
    float3 q = p;
    q.xy = mul(q.xy, float2x2(0.9239, 0.3827, -0.3827, 0.9239)); // pi/8
    q.xy = foldOct(q.xy);
    p.z += length(p.xy) * .46;
    p.xy = foldOct(p.xy);
    float g = sbox(p - float3(0.32, 0.2, 0.), float3(.3, 0.3, 0.04)); // Cockpit
                                                                // Spokes
    float mg = min(mn, g);
    if (mn < -g)
        matid = 2.;
    mn = max(mn, -g);
    float g2 = sbox(q, float3(.45, 0.15, .17)); // Cockpit center
    if (mn < -g2)
        matid = 2.;
    mn = max(mn, -g2);
    mn = min(mn,
           torus(bp.yzx + float3(0, -.545, 0), float2(0.4, 0.035))); // Cockpit lip
    mn = max(mn, -torus(bp + float3(0, -.585, 0), float2(0.41, 0.03))); // Hatch

  // Engine (Polar coords)
    mn = max(mn, -(bp.z + 0.6));
    float3 pl = bp.xzy;
    pl = float3(length(pl.xz) - 0.33, pl.y, atan2(pl.z, pl.x));
    pl.y += .55;
    mn = min(mn, sbox(pl, float3(.29 + bp.z * 0.35, .25, 4.)));
    pl.z = frac(pl.z * 1.7) - 0.5;
    mn = min(mn, sbox(pl + float3(0.03, 0.09, 0.), float3(0.05, .1, .2)));

    p = bp;
    p.x = abs(p.x) - 1.1; // Main symmetry

    mn = min(mn,
           cyl(p.xzy - float3(-0.87, .43, -0.48), float2(.038, 0.1))); // Gunports

    const float wd = 0.61; // Main width
    const float wg = 1.25; // Wign size

    mn = min(mn, cyl(p.yxz,
                   float2(0.22 + smoothfloor((abs(p.x + 0.12) - 0.15) * 4., 0.1) *
                                   0.04,
                        0.6))); // Main structure
    float3 pp = p;
    pp.y *= 0.95;
    float3 r = p;
    p.y *= 0.65;
    p.z = abs(p.z);
    p.z -= 0.16;
    q = p;
    r.y = abs(r.y) - .5;
    mn = min(mn,
           sbox(r - float3(-.3, -0.37, 0.),
                float3(0.35,
                     .12 - smoothfloor(r.x * 2. - .4, 0.1) * 0.1 * (-r.x * 1.7),
                     0.015 - r.x * 0.15))); // Side Structure
    mn = min(mn, sbox(r - float3(-.0, -0.5, 0.),
                    float3(0.6, .038, 0.18 + r.x * .5))); // Side Structure
    p.zy = foldHex(p.zy) - 0.5;
    pp.zy = foldHex(pp.zy) - 0.5;
    mn = min(mn,
           sbox(p - float3(wd, wg, 0), float3(0.05, .01, .6))); // wing Outer edge
    q.yz = foldHex(q.yz) - 0.5;

    mn = min(mn, sbox(q - float3(wd, -0.495 - abs(q.x - wd) * .07, 0.),
                    float3(0.16 - q.z * 0.07, .015 - q.z * 0.005,
                         wg + .27))); // wing spokes
    mn = min(mn, sbox(q - float3(wd, -0.5, 0.),
                    float3(0.12 - q.z * 0.05, .04, wg + .26))); // Spoke supports

    mn = min(mn,
           sbox(pp - float3(wd, -0.35, 0.), float3(0.12, .35, .5))); // Wing centers
    mn = min(mn, sbox(pp - float3(wd, -0.35, 0.),
                    float3(0.15 + tri(pp.y * pp.z * 30. * tri(pp.y * 2.5)) * 0.06,
                         .25, .485))); // Wing centers

    float wgn = sbox(p - float3(wd, 0, 0),
                   float3(0.04, wg, 1.)); // Actual wings (different material)
    if (mn > wgn)
        matid = 1.;
    mn = min(mn, wgn);

  // Engine port
    float ep = hexprism(bp + float3(0, 0, 0.6), float2(.15, 0.02));
    if (mn > ep)
        matid = 2.;
    mn = min(mn, ep);

    return mn;
}

float tfsdf(float3 p)
{
    const float scale = 0.3;
    p *= 1. / scale;
    return tfmap(p) * scale;
}

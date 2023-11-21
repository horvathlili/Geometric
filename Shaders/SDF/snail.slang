/*
Copyright 2015 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0
Link: https://www.shadertoy.com/view/ld3Gz2
Archive Link: https://web.archive.org/web/20191112111750/https://www.shadertoy.com/view/ld3Gz2
 */

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef snail_glsl
#define snail_glsl

#define TIME 60
//#define PI 3.14159265359
//#define TIME g3d_SceneTime

float sdCapsule(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

float sdTorusSnail(float3 p, float2 t)
{
    return length(float2(length(p.xz) - t.x, p.y)) - t.y;
}

/*float smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0., 1.);
    return lerp(b, a, h) - k * h * (1.0 - h);
}*/

// http://iquilezles.org/www/articles/smin/smin.htm
float snail_smax(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(a, b, h) + k * h * (1.0 - h);
}


// http://iquilezles.org/www/articles/smin/smin.htm
float3 snail_smax(float3 a, float3 b, float k)
{
    float3 h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(a, b, h) + k * h * (1.0 - h);
}

float sdSphere(in float3 p, in float4 s)
{
    return length(p - s.xyz) - s.w;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float snail_sdEllipsoid(in float3 p, in float3 c, in float3 r)
{
    return (length((p - c) / r) - 1.0) * min(min(r.x, r.y), r.z);
}

/*
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( in float3 p, in float4 s )
{
    return length(p-s.xyz) - s.w;
}
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCircle( in float2 p, in float2 c, in float r )
{
    return length(p-c) - r;
}
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdTorus( float3 p, float2 t )
{
    return length( float2(length(p.xz)-t.x,p.y) )-t.y;
}
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCapsule( float3 p, float3 a, float3 b, float r )
{
    float3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}
*/

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float2 udSegment(float3 p, float3 a, float3 b)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return float2(length(pa - ba * h), h);
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float det(float2 a, float2 b)
{
    return a.x * b.y - b.x * a.y;
}
float3 getClosest(float2 b0, float2 b1, float2 b2)
{
    float a = det(b0, b2);
    float b = 2.0 * det(b1, b0);
    float d = 2.0 * det(b2, b1);
    float f = b * d - a * a;
    float2 d21 = b2 - b1;
    float2 d10 = b1 - b0;
    float2 d20 = b2 - b0;
    float2 gf = 2.0 * (b * d21 + d * d10 + a * d20);
    gf = float2(gf.y, -gf.x);
    float2 pp = -f * gf / dot(gf, gf);
    float2 d0p = b0 - pp;
    float ap = det(d0p, d20);
    float bp = 2.0 * det(d10, d0p);
    float t = clamp((ap + bp) / (2.0 * a + b + d), 0.0, 1.0);
    return float3(lerp(lerp(b0, b1, t), lerp(b1, b2, t), t), t);
}

float4 sdBezier(float3 a, float3 b, float3 c, float3 p)
{
    float3 w = normalize(cross(c - b, a - b));
    float3 u = normalize(c - b);
    float3 v = (cross(w, u));

    float2 a2 = float2(dot(a - b, u), dot(a - b, v));
    float2 b2 = float2(0.0);
    float2 c2 = float2(dot(c - b, u), dot(c - b, v));
    float3 p3 = float3(dot(p - b, u), dot(p - b, v), dot(p - b, w));

    float3 cp = getClosest(a2 - p3.xy, b2 - p3.xy, c2 - p3.xy);

    return float4(sqrt(dot(cp.xy, cp.xy) + p3.z * p3.z), cp.z, length(cp.xy), p3.z);
}

//---------------------------------------------------------------------------



//---------------------------------------------------------------------------

#define ZERO 0

//---------------------------------------------------------------------------

float mapShell(in float3 p, out float4 matInfo)
{
    
    const float sc = 1.0 / 1.0;
    p -= float3(0.05, 0.12, -0.09);

    p *= sc;

    float3 q = float3(dot(float3(-0.6333234236, -0.7332753384, 0.2474039592), p),
    dot(float3(0.7738444477, -0.6034162289, 0.1924931824), p),
        dot(float3(0.0081370606, 0.3133626215, 0.9495986813), p));

    const float b = 0.1759;
    
    float r = length(q.xy);
    float t = atan2(q.y, q.x);
 
    // https://swiftcoder.wordpress.com/2010/06/21/logarithmic-spiral-distance-field/
    float n = (log(r) / b - t) / (2.0 * PI);

    float nm = (log(0.11) / b - t) / (2.0 * PI);

    n = min(n, nm);
    
    float ni = floor(n);
    
    float r1 = exp(b * (t + 2.0 * PI * ni));
    float r2 = r1 * 3.019863;
    
    //-------

    float h1 = q.z + 1.5 * r1 - 0.5;
    float d1 = sqrt((r1 - r) * (r1 - r) + h1 * h1) - r1;
    float h2 = q.z + 1.5 * r2 - 0.5;
    float d2 = sqrt((r2 - r) * (r2 - r) + h2 * h2) - r2;
    
    float d, dx, dy;
    if (d1 < d2)
    {
        d = d1;
        dx = r1 - r;
        dy = h1;
    }
    else
    {
        d = d2;
        dx = r2 - r;
        dy = h2;
    }


    //float di = textureLod( iChannel2, float2(t+r,0.5), 0. ).x;
    //d += 0.002*di;
    
    matInfo = float4(dx, dy, r / 0.4, t / PI);

    float3 s = q;
    q = q - float3(0.34, -0.1, 0.03);
    q.xy = float2(dot(float2(0.8, 0.6), q.xy), dot(float2(-0.6, 0.8), q.xy));
    d = smin(d, sdTorusSnail(q, float2(0.28, 0.05)), 0.06);
    d = snail_smax(d, -snail_sdEllipsoid(q, float3(0.0, 0.0, 0.0), float3(0.24, 0.36, 0.24)), 0.03);

    d = snail_smax(d, -snail_sdEllipsoid(s, float3(0.52, -0.0, 0.0), float3(0.42, 0.23, 0.5)), 0.05);
    
    return d / sc;
}

float2 mapSnail(float3 p, out float4 matInfo)
{
    float3 head = float3(-0.76, 0.6, -0.3);
    
    float3 q = p - head;

    // body
#if 1
    float4 b1 = sdBezier(float3(-0.13, -0.65, 0.0), float3(0.24, 0.9 + 0.1, 0.0), head + float3(0.04, 0.01, 0.0), p);
    float d1 = b1.x;
    d1 -= smoothstep(0.0, 0.2, b1.y) * (0.16 - 0.07 * smoothstep(0.5, 1.0, b1.y));
    b1 = sdBezier(float3(-0.085, 0.0, 0.0), float3(-0.1, 0.9 - 0.05, 0.0), head + float3(0.06, -0.08, 0.0), p);
    float d2 = b1.x;
    d2 -= 0.1 - 0.06 * b1.y;
    d1 = smin(d1, d2, 0.03);
    matInfo.xyz = b1.yzw;
#else
    float4 b1 = sdBezier( float3(-0.13,-0.65,0.0), float3(0.24,0.9+0.11,0.0), head+float3(0.05,0.01-0.02,0.0), p );
    float d1 = b1.x;
    d1 -= smoothstep(0.0,0.2,b1.y)*(0.16 - 0.75*0.07*smoothstep(0.5,1.0,b1.y));
    matInfo.xyz = b1.yzw;
    float d2;
#endif
    d2 = sdSphere(q, float4(0.0, -0.06, 0.0, 0.085));
    d1 = smin(d1, d2, 0.03);
    
    d1 = smin(d1, sdSphere(p, float4(0.05, 0.52, 0.0, 0.13)), 0.07);
    
    q.xz = float2(dot(float2(0.8, 0.6), q.xz), dot(float2(-0.6, 0.8), q.xz));

    float3 sq = float3(q.xy, abs(q.z));
    
    // top antenas
    float3 af = 0.05 * sin(0.5 * TIME + float3(0.0, 1.0, 3.0) + float3(2.0, 1.0, 0.0) * sign(q.z));
    float4 b2 = sdBezier(float3(0.0), float3(-0.1, 0.2, 0.2), float3(-0.3, 0.2, 0.3) + af, sq);
    float d3 = b2.x;
    d3 -= 0.03 - 0.025 * b2.y;
    d1 = smin(d1, d3, 0.04);
    d3 = sdSphere(sq, float4(-0.3, 0.2, 0.3, 0.016) + float4(af, 0.0));
    d1 = smin(d1, d3, 0.01);
    
    // bottom antenas
    float3 bf = 0.02 * sin(0.3 * TIME + float3(4.0, 1.0, 2.0) + float3(3.0, 0.0, 1.0) * sign(q.z));
    float2 b3 = udSegment(sq, float3(0.06, -0.05, 0.0), float3(-0.04, -0.2, 0.18) + bf);
    d3 = b3.x;
    d3 -= 0.025 - 0.02 * b3.y;
    d1 = smin(d1, d3, 0.06);
    d3 = sdSphere(sq, float4(-0.04, -0.2, 0.18, 0.008) + float4(bf, 0.0));
    d1 = smin(d1, d3, 0.02);
    
    // bottom
    float3 pp = p - float3(-0.17, 0.15, 0.0);
    float co = 0.988771078;
    float si = 0.149438132;
    pp.xy = float2(dot(float2(co, -si), pp.xy), dot(float2(si, co), pp.xy));
    d1 = smin(d1, snail_sdEllipsoid(pp, float3(0.0, 0.0, 0.0), float3(0.084, 0.3, 0.15)), 0.05);
    d1 = snail_smax(d1, -snail_sdEllipsoid(pp, float3(-0.08, -0.0, 0.0), float3(0.06, 0.55, 0.1)), 0.02);
    
    // disp
    //float dis = textureLod( iChannel1, 5.0*p.xy, 0. ).x;
    //float dx = 0.5 + 0.5*(1.0-smoothstep(0.5,1.0,b1.y));
    //d1 -= 0.005*dis*dx*0.5;
    //d1 -= 0.005*dis*dx*0.5;
        
    return float2(d1, 1.0);
}
    
float mapDrop(in float3 p)
{
    p -= float3(-0.26, 0.25, -0.02);
    p.x -= 2.5 * p.y * p.y;
    return sdCapsule(p, float3(0.0, -0.06, 0.0), float3(0.014, 0.06, 0.0), 0.037);
}

float mapLeaf(in float3 p)
{
    p -= float3(-1.8, 0.6, -0.75);
    
    p = float3(dot(float3(0.671212, 0.366685, -0.644218), p),
            dot(float3(-0.479426, 0.877583, 0.000000), p),
    dot(float3(0.565354, 0.308854, 0.764842), p));
 
    p.y += 0.2 * exp(-abs(2.0 * p.z));
    
    
    float ph = 0.25 * 50.0 * p.x - 0.25 * 75.0 * abs(p.z); // + 1.0*sin(5.0*p.x)*sin(5.0*p.z);
    float rr = sin(ph);
    rr = rr * rr;
    rr = rr * rr;
    p.y += 0.005 * rr;
    
    float r = clamp((p.x + 2.0) / 4.0, 0.0, 1.0);
    r = 0.0001 + r * (1.0 - r) * (1.0 - r) * 6.0;
    
    rr = sin(ph * 2.0);
    rr = rr * rr;
    rr *= 0.5 + 0.5 * sin(p.x * 12.0);

    float ri = 0.035 * rr;
    
    float d = snail_sdEllipsoid(p, float3(0.0), float3(2.0, 0.25 * r, r + ri));

    float d2 = p.y - 0.02;
    d = snail_smax(d, -d2, 0.02);
    
    return d;
}

float2 mapOpaque(float3 p, out float4 matInfo)
{
    matInfo = float4(0.0);
    
    //--------------
    float2 res = mapSnail(p, matInfo);
    
    //---------------
    float4 tmpMatInfo;
    float d4 = mapShell(p, tmpMatInfo);
    if (d4 < res.x)
    {
        res = float2(d4, 2.0);
        matInfo = tmpMatInfo;
    }

    //---------------
    
    // plant
    float4 b3 = sdBezier(float3(-0.15, -1.5, 0.0), float3(-0.1, 0.5, 0.0), float3(-0.6, 1.5, 0.0), p);
    d4 = b3.x;
    d4 -= 0.04 - 0.02 * b3.y;
    if (d4 < res.x)
    {
        res = float2(d4, 3.0);
    }
    
    //----------------------------
    
    //float d5 = mapLeaf( p );
    //if( d5<res.x ) res = float2(d5,4.0);
        
    return res;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
float3 calcNormalOpaque(in float3 pos, in float eps)
{
    float4 kk;
#if 0
    float2 e = float2(1.0,-1.0)*0.5773*eps;
    return normalize( e.xyy*mapOpaque( pos + e.xyy, kk ).x + 
                      e.yyx*mapOpaque( pos + e.yyx, kk ).x + 
                      e.yxy*mapOpaque( pos + e.yxy, kk ).x + 
                      e.xxx*mapOpaque( pos + e.xxx, kk ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    float3 n = float3(0.0);
    for (int i = ZERO; i < 4; i++)
    {
        float3 e = 0.5773 * (2.0 * float3((((i + 3) >> 1) & 1), ((i >> 1) & 1), (i & 1)) - 1.0);
        n += e * mapOpaque(pos + eps * e, kk).x;
    }
    return normalize(n);
#endif    
}

float snailsdf(float3 p)
{
    const float scale = 0.8;
    p *= 1. / scale;
    float4 temp = float4(0.);
    return mapOpaque(p, temp).x * scale;
}

#endif

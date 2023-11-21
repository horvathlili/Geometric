/*
Copyright 2016 Inigo Quilez @iq
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4dKGWm
Archive Link: https://web.archive.org/web/20191112085742/https://www.shadertoy.com/view/4dKGWm
*/

/******************************************************************************
 This work is a derivative of work by Inigo Quilez used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

float hash1(float n)
{
    return frac(sin(n) * 43758.5453123);
}

float esmin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

float2 esmin(float2 a, float2 b, float k)
{
    float h = clamp(0.5 + 0.5 * (b.x - a.x) / k, 0.0, 1.0);
    return float2(lerp(b.x, a.x, h) - k * h * (1.0 - h), lerp(b.y, a.y, h));
}

float esmax(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(a, b, h) + k * h * (1.0 - h);
}

float2 sdSegment(in float3 p, float3 a, float3 b)
{
    float3 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return float2(length(pa - ba * h), h);
}

float sdSphere(in float3 p, in float3 c, in float r)
{
    return length(p - c) - r;
}

float sdEllipsoid(in float3 p, in float3 c, in float3 r)
{
#if 1
    return (length((p - c) / r) - 1.0) * min(min(r.x, r.y), r.z);
#else
  p -= c;
  float k0 = length(p / r);
  float k1 = length(p / (r * r));
  return k0 * (k0 - 1.0) / k1;
#endif
}

// http://research.microsoft.com/en-us/um/people/hoppe/ravg.pdf
float edet(float2 a, float2 b)
{
    return a.x * b.y - b.x * a.y;
}
float3 egetClosest(float2 b0, float2 b1, float2 b2)
{
    float a = edet(b0, b2);
    float b = 2.0 * edet(b1, b0);
    float d = 2.0 * edet(b2, b1);
    float f = b * d - a * a;
    float2 d21 = b2 - b1;
    float2 d10 = b1 - b0;
    float2 d20 = b2 - b0;
    float2 gf = 2.0 * (b * d21 + d * d10 + a * d20);
    gf = float2(gf.y, -gf.x);
    float2 pp = -f * gf / dot(gf, gf);
    float2 d0p = b0 - pp;
    float ap = edet(d0p, d20);
    float bp = 2.0 * edet(d10, d0p);
    float t = clamp((ap + bp) / (2.0 * a + b + d), 0.0, 1.0);
    return float3(lerp(lerp(b0, b1, t), lerp(b1, b2, t), t), t);
}

float2 sdBezier(float3 a, float3 b, float3 c, float3 p, out float2 pos)
{
    float3 w = normalize(cross(c - b, a - b));
    float3 u = normalize(c - b);
    float3 v = normalize(cross(w, u));

    float2 a2 = float2(dot(a - b, u), dot(a - b, v));
    float2 b2 = float2(0.0);
    float2 c2 = float2(dot(c - b, u), dot(c - b, v));
    float3 p3 = float3(dot(p - b, u), dot(p - b, v), dot(p - b, w));

    float3 cp = egetClosest(a2 - p3.xy, b2 - p3.xy, c2 - p3.xy);

    pos = cp.xy;

    return float2(sqrt(dot(cp.xy, cp.xy) + p3.z * p3.z), cp.z);
}

//---------------------------------------------------------------------------

float3x3 base(in float3 ww)
{
    float3 vv = float3(0.0, 0.0, 1.0);
    float3 uu = normalize(cross(vv, ww));
    return float3x3(uu.x, ww.x, vv.x, uu.y, ww.y, vv.y, uu.z, ww.z, vv.z);
}

//---------------------------------------------------------------------------

float leg(in float3 p, in float3 pa, in float3 pb, in float3 pc, float m, float h)
{
    float l = sign(pa.z);

    float2 b = sdSegment(p, pa, pb);

    float tr = 0.35 - 0.16 * smoothstep(0.0, 1.0, b.y);
    float d3 = b.x - tr;

    b = sdSegment(p, pb, pc);
    tr = 0.18;
    d3 = esmin(d3, b.x - tr, 0.1);

  // paw
    float3 ww = normalize(lerp(normalize(pc - pb), float3(0.0, 1.0, 0.0), h));
    float3x3 pr = base(ww);
    float3 fc = mul(pr , (p - pc)) - float3(0.02, 0.0, 0.0) * (-1.0 + 2.0 * h);
    float d4 = sdEllipsoid(fc, float3(0.0), float3(0.2, 0.15, 0.2));

    d3 = esmin(d3, d4, 0.1);

  // nails
    float d6 = sdEllipsoid(fc, float3(0.14, -0.06, 0.0) * (-1.0 + 2.0 * h),
                         float3(0.1, 0.16, 0.1));
    d6 = min(d6, sdEllipsoid(float3(fc.xy, abs(fc.z)),
                           float3(0.13 * (-1.0 + 2.0 * h),
                                -0.08 * (-1.0 + 2.0 * h), 0.13),
                           float3(0.09, 0.14, 0.1)));
    d3 = esmin(d3, d6, 0.001);
    return d3;
}

float mapElephant(float3 p, out float3 matInfo)
{
    matInfo = float3(0.0);

    p.x -= -0.5;
    p.y -= 2.4;

    float3 ph = p;
    float cc = 0.995;
    float ss = 0.0998745;
    ph.yz = mul(float2x2(cc, -ss, ss, cc), ph.yz);
    ph.xy = mul(float2x2(cc, -ss, ss, cc), ph.xy);

  // head
    float d1 = sdEllipsoid(ph, float3(0.0, 0.05, 0.0), float3(0.45, 0.5, 0.3));
    d1 = esmin(d1, sdEllipsoid(ph, float3(-0.3, 0.15, 0.0), float3(0.2, 0.2, 0.2)),
            0.1);

  // nose
    float2 kk;
    float2 b1 = sdBezier(float3(-0.15, -0.05, 0.0), float3(-0.7, 0.0, 0.0),
                     float3(-0.7, -0.8, 0.0), ph, kk);
    float tr1 = 0.30 - 0.17 * smoothstep(0.0, 1.0, b1.y);
    float2 b2 = sdBezier(float3(-0.7, -0.8, 0.0), float3(-0.7, -1.5, 0.0),
                     float3(-0.4, -1.6, 0.2), ph, kk);
    float tr2 = 0.30 - 0.17 - 0.05 * smoothstep(0.0, 1.0, b2.y);
    float bd1 = b1.x - tr1;
    float bd2 = b2.x - tr2;
    float nl = b1.y * 0.5;
    float bd = bd1;
    if (bd2 < bd1)
    {
        nl = 0.5 + 0.5 * b2.y;
        bd = bd2;
    }
    matInfo.x = clamp(nl * (1.0 - smoothstep(0.0, 0.2, bd)), 0.0, 1.0);
    float d2 = bd;
    float xx = nl * 120.0;
    float ff = sin(xx + sin(xx + sin(xx + sin(xx))));
  // ff *= smoothstep(0.0,0.01,kk.y);
    d2 += 0.003 * ff * (1.0 - nl) * (1.0 - nl) * smoothstep(0.0, 0.1, nl);

//   d2 -= (0.05 -
//          0.05 * (1.0 -
//                  pow(textureLod(iChannel0, float2(1.0 * nl, p.z * 0.12), 0.0).x,
//                      1.0))) *
//         nl * (1.0 - nl) * 0.5;

    float d = esmin(d1, d2, 0.2);

  // teeth
    float3 q = float3(p.xy, abs(p.z));
    float3 qh = float3(ph.xy, abs(ph.z));
  {
        float2 s1 = sdSegment(qh, float3(-0.4, -0.1, 0.1), float3(-0.5, -0.4, 0.28));
        float d3 = s1.x - 0.18 * (1.0 - 0.3 * smoothstep(0.0, 1.0, s1.y));
        d = esmin(d, d3, 0.1);
    }

  // eyes
  {
        float2 s1 = sdSegment(qh, float3(-0.2, 0.2, 0.11), float3(-0.3, -0.0, 0.26));
        float d3 = s1.x - 0.19 * (1.0 - 0.3 * smoothstep(0.0, 1.0, s1.y));
        d = esmin(d, d3, 0.03);

        float st = length(qh.xy - float2(-0.31, -0.02));
    // d += 0.005*sin(250.0*st)*exp(-110.0*st*st );
        d += 0.0015 * sin(250.0 * st) * (1.0 - smoothstep(0.0, 0.2, st));

        float3x3 rot = float3x3(0.8, -0.6, 0.0, 0.6, 0.8, 0.0, 0.0, 0.0, 1.0);
        float d4 = sdEllipsoid(mul(rot, (qh - float3(-0.31, -0.02, 0.34))), float3(0.0),
                           float3(0.1, 0.08, 0.07) * 0.7);
        d = esmax(d, -d4, 0.02);
    }

  // body
  {
        float co = cos(0.4);
        float si = sin(0.4);
        float3 w = p;
       // w.xy = mul(float2x2(co, si, -si, co), w.xy);

        float d4 = sdEllipsoid(w, float3(0.6, 0.3, 0.0), float3(0.6, 0.6, 0.6));
        d = esmin(d, d4, 0.1);

        d4 = sdEllipsoid(w, float3(1.8, 0.3, 0.0), float3(1.2, 0.9, 0.7));
        d = esmin(d, d4, 0.2);

        d4 = sdEllipsoid(w, float3(2.1, 0.55, 0.0), float3(1.0, 0.9, 0.6));
        d = esmin(d, d4, 0.1);

        d4 = sdEllipsoid(w, float3(2.0, 0.8, 0.0), float3(0.7, 0.6, 0.8));
        d = esmin(d, d4, 0.1);
    }

  // back-left leg
  {
        float d3 = leg(q, float3(2.6, -0.5, 0.3), float3(2.65, -1.45, 0.3),
                   float3(2.6, -2.1, 0.25), 1.0, 0.0);
        d = esmin(d, d3, 0.1);
    }

  // tail
#if 1
    {
        float2 b = sdBezier(float3(2.8, 0.2, 0.0), float3(3.4, -0.6, 0.0), float3(3.1, -1.6, 0.0), p, kk);
        float tr = 0.10 - 0.07 * b.y;
        float d2 = b.x - tr;
        d = esmin(d, d2, 0.05);
    }
#endif

// front-left leg
#if 0
    {
    float d3 = leg( q, float3(0.8,-0.4,0.3), float3(0.5,-1.55,0.3), float3(0.5,-2.1,0.3), 1.0, 0.0 );
    d = esmin(d,d3,0.15);
    }
#else
  {
        float d3 = leg(p, float3(0.8, -0.4, 0.3), float3(0.7, -1.55, 0.3),
                   float3(0.8, -2.1, 0.3), 1.0, 0.0);
        d = esmin(d, d3, 0.15);
        d3 = leg(p, float3(0.8, -0.4, -0.3), float3(0.4, -1.55, -0.3),
             float3(0.4, -2.1, -0.3), 1.0, 0.0);
        d = esmin(d, d3, 0.15);
    }
#endif

#if 1
  // ear
    float co = cos(0.5);
    float si = sin(0.5);
    float3 w = qh;
    w.xz = mul(float2x2(co, si, -si, co), w.xz);

    float2 ep = w.zy - float2(0.5, 0.4);
    float aa = atan2(ep.x, ep.y);
    float al = length(ep);
    w.x += 0.003 * sin(24.0 * aa) * smoothstep(0.0, 0.5, dot(ep, ep));
//   w.x += 0.02 *
//          textureLod(iChannel1, float2(al * 0.02, 0.5 + 0.05 * sin(aa)), 0.0).x *
//          smoothstep(0.0, 0.3, dot(ep, ep));

    float r =
      0.02 * sin(24.0 * atan2(ep.x, ep.y)) * clamp(-w.y * 1000.0, 0.0, 1.0);
    r += 0.01 * sin(15.0 * w.z);
  // section
    float d4 = length(w.zy - float2(0.5, -0.2 + 0.03)) - 0.8 + r;
    float d5 = length(w.zy - float2(-0.1, 0.6 + 0.03)) - 1.5 + r;
    float d6 = length(w.zy - float2(1.8, 0.1 + 0.03)) - 1.6 + r;
    d4 = esmax(d4, d5, 0.1);
    d4 = esmax(d4, d6, 0.1);

    float wi =
      0.02 + 0.1 * pow(clamp(1.0 - 0.7 * w.z + 0.3 * w.y, 0.0, 1.0), 2.0);
    w.x += 0.05 * cos(6.0 * w.y);

  // cut it!
    d4 = esmax(d4, -w.x, 0.03);
    d4 = esmax(d4, w.x - wi, 0.03);

    matInfo.y = clamp(length(ep), 0.0, 1.0) * (1.0 - smoothstep(-0.1, 0.05, d4));

    d = esmin(d, d4, 0.3 * max(qh.y, 0.0)); // trick -> positional smooth

  // conection hear/head
    float2 s1 = sdBezier(float3(-0.15, 0.3, 0.0), float3(0.1, 0.6, 0.2),
                     float3(0.35, 0.6, 0.5), qh, kk);
    float d3 = s1.x - 0.08 * (1.0 - 0.95 * s1.y * s1.y);
    d = esmin(d, d3, 0.05);

#endif

//   d -= 0.002 * textureLod(iChannel1, 0.5 * p.yz, 0.0).x;
//   d -= 0.002 * textureLod(iChannel1, 0.5 * p.yx, 0.0).x;
//   d += 0.003;
//   d -= 0.005 * textureLod(iChannel0, 0.5 * p.yx, 0.0).x *
//        (0.2 + 0.8 * smoothstep(0.8, 1.3, length(p - float3(-0.5, 0.0, 0.0))));

    float2 res = float2(d, 0.0);
  //=====================
  // teeth
    float2 b = sdBezier(float3(-0.5, -0.4, 0.28), float3(-0.5, -0.7, 0.32),
                    float3(-1.0, -0.8, 0.45), qh, kk);
    float tr = 0.10 - 0.08 * b.y;
    d2 = b.x - tr;
    if (d2 < res.x)
    {
        res = float2(d2, 1.0);
        matInfo.x = b.y;
    }
  //------------------
  // eyeball
    float3x3 rot = float3x3(0.8, -0.6, 0.0, 0.6, 0.8, 0.0, 0.0, 0.0, 1.0);
    d4 = sdEllipsoid(mul(rot, (qh - float3(-0.31, -0.02, 0.33))), float3(0.0),
                   float3(0.1, 0.08, 0.07) * 0.7);
  //if (d4 < res.x)
  //  res = float2(d4, 2.0);

    d = min(d4, min(d, d2));

    return d;
}

float sleg(in float3 p, in float3 pa, in float3 pb, in float3 pc, float m, float h,
           float sc)
{
    float l = sign(pa.z);

    float2 b = sdSegment(p, pa, pb);

    float tr = 0.35 - 0.15 * smoothstep(0.0, 1.0, b.y);
    float d3 = b.x - tr * sc;

    b = sdSegment(p, pb, pc);
    tr = 0.18; // - 0.015*smoothstep(0.0,1.0,b.y);
    d3 = esmin(d3, b.x - tr * sc, 0.1);

  // paw
    float3 ww = normalize(lerp(normalize(pc - pb), float3(0.0, 1.0, 0.0), h));
    float3x3 pr = base(ww);
    float3 fc = mul(pr, ((p - pc))) - float3(0.02, 0.0, 0.0) * (-1.0 + 2.0 * h);
    float d4 = sdEllipsoid(fc, float3(0.0), float3(0.2, 0.15, 0.2));

    d3 = esmin(d3, d4, 0.1);

  // nails
    float d6 = sdEllipsoid(fc, float3(0.14, -0.04, 0.0) * (-1.0 + 2.0 * h),
                         float3(0.1, 0.16, 0.1));
    d6 = min(d6, sdEllipsoid(float3(fc.xy, abs(fc.z)),
                           float3(0.13 * (-1.0 + 2.0 * h), 0.04, 0.13),
                           float3(0.09, 0.14, 0.1)));
    d3 = esmin(d3, d6, 0.001);
    return d3;

    return d3;
}

float3x3 RotMat(float3 axis, float angle)
{
    // http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return float3x3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}

float elephantsdf(float3 p)
{
    p = mul(p, RotMat(float3(0., 1., 0.), -3.14 / 2.0));
    p += float3(0.2, 0.4, 0.);
    const float scale = 0.3;
    p *= 1. / scale;
    float3 matInfo = float3(0);
    return mapElephant(p, matInfo) * scale * 0.9;
}

#ifndef SDF
#define SDF 0
#endif

#include "head.slang"
#include "../../snail.slang"
#include "../../spike.slang"
#include "vase.slang"
#include "knob.slang"
#include "../../helix.slang"
#include "../../jelly.slang"
#include "../../tiefighter.slang"
#include "../../boat.slang"
#include "../../beziersdf.slang"
#include "../../dodeca.slang"
#include "../../mobius.slang"
#include "../../rock.slang"
#include "../../isocahedron.slang"


float sdfSphere(float3 p, float s)
{
    return length(p) - s;    
}

float hsdTorus(float3 p, float3 center, float3 axis, float r, float R)
{
    float3 p2 = p - center;
    float3 e2 = normalize(axis);
    float3 n = cross(e2, normalize(p2));

    float3 e1 = normalize(cross(e2, n));

    float px = dot(e1, p2);
    float py = dot(e2, p2);

    float dist1 = sqrt((px - R) * (px - R) + py * py) - r;
    float dist2 = sqrt((px + R) * (px + R) + py * py) - r;

    if (dist1 * dist2 < 0) //egymásbalóg a tórusz
    {
    
        return min(dist1, dist2);
    }
    
    if (abs(dist1) <= abs(dist2))
        return dist1;
    else
        return dist2;


}

float sdPyramid(float3 p, float h)
{
    float m2 = h * h + 0.25;

    p.xz = abs(p.xz);
    p.xz = (p.z > p.x) ? p.zx : p.xz;
    p.xz -= 0.5;

    float3 q = float3(p.z, h * p.y - 0.5 * p.x, h * p.x + 0.5 * p.y);

    float s = max(-q.x, 0.0);
    float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);

    float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
    float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

    float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);

    return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

float sdOctahedron(float3 p, float s)
{
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    float3 q;
    if (3.0 * p.x < m)
        q = p.xyz;
    else if (3.0 * p.y < m)
        q = p.yzx;
    else if (3.0 * p.z < m)
        q = p.zxy;
    else
        return m * 0.57735027;

    float k = clamp(0.5f * (q.z - q.y + s), 0.0f, s);
    return length(float3(q.x, q.y - s + k, q.z - k));
}

float sdRoundBox(float3 p, float3 b, float r)
{
    float3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdVerticalCapsule(float3 p, float h, float r)
{
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float sdHexPrism(float3 p, float2 h)
{
    const float3 k = float3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
    float2 d = float2(
       length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
       p.z - h.y);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}



float map(float3 p)
{
    #if SDF == 0
        return sdfSphere(p, 0.5);
    #endif
    #if SDF == 1
            return hsdTorus(p, float3(0,0,0),float3(0,1,0),0.1,0.4);
    #endif
    #if SDF == 2
        return sdOctahedron(p,0.3);
    #endif
    #if SDF == 3
        return headsdf(p);
    #endif
    #if SDF == 4
        return spikesdf(p);
    #endif
#if SDF == 5
    return tfsdf(p);
    //return sdPyramid((p + float3(0.0, 1.0, 0.0)) * 0.5, 1.0) * 2.0;
    //return sdHexPrism(p,float2(0.5));
       //return sdVerticalCapsule(p + float3(0.0, 0.5, 0.0), 1.0, 0.5);
#endif
    
    #if SDF == 6
        return sdRoundBox(p,float3(0.4), 0.25);
#endif
  


}

float3 getNormal(float3 p)
{
    float e = 0.0001;
    float3 n;
    n.x = map(p + float3(e, 0, 0)) - map(p - float3(e, 0, 0));
    n.y = map(p + float3(0, e, 0)) - map(p - float3(0, e, 0));
    n.z = map(p + float3(0, 0, e)) - map(p - float3(0, 0, e));

    return normalize(n);
}

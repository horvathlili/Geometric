#ifndef SDF
#define SDF 0
#endif

#include "head.slang"
#include "../../snail.slang"


float sdfSphere(float3 p, float s)
{
    return length(p) - s;    
}

float sdTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
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

/*float sdlotofcircles(float3 p)
{
    
}*/

float map(float3 p)
{
    #if SDF == 0
        return sdfSphere(p, 0.5);
    #endif
    #if SDF == 1
            return sdTorus(p, float2(0.3, 0.1));
    #endif
    #if SDF == 2
        return sdOctahedron(p,0.3);
    #endif
    #if SDF == 3
        return headsdf(p);
    #endif
    #if SDF == 4
        return snailsdf(p);
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

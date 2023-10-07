#ifndef SDF
#define SDF 0
#endif

#include "../../bezierOutlineBuffer.slang"


float sdCircle(float2 p, float r)
{
    return length(p) - r;
}

float sdMoon(float2 p, float d, float ra, float rb)
{
    p.y = abs(p.y);
    float a = (ra * ra - rb * rb + d * d) / (2.0 * d);
    float b = sqrt(max(ra * ra - a * a, 0.0));
    if (d * (p.x * b - p.y * a) > d * d * max(b - p.y, 0.0))
        return length(p - float2(a, b));
    return max((length(p) - ra),
               -(length(p - float2(d, 0)) - rb));
}

float sdHexagram(float2 p, float r)
{
    const float4 k = float4(-0.5, 0.8660254038, 0.5773502692, 1.7320508076);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= 2.0 * min(dot(k.yx, p), 0.0) * k.yx;
    p -= float2(clamp(p.x, r * k.z, r * k.w), r);
    return length(p) * sign(p.y);
}

float sdHorseshoe(float2 p, float2 c,  float r, float2 w)
{
    p.x = abs(p.x);
    float l = length(p);
    p = float2(p.x * -c.x + c.y * p.y, p.x * c.y + p.y * c.x);
    p = float2((p.y > 0.0 || p.x > 0.0) ? p.x : l * sign(-c.x),
             (p.x > 0.0) ? p.y : l);
    p = float2(p.x, abs(p.y - r)) - w;
    return length(max(p, 0.0)) + min(0.0, max(p.x, p.y));
}


float map(float2 p)
{
    #if SDF == 0
        return sdCircle(p, 1);
    #endif
    #if SDF == 1
        return sdMoon(p, 0.5, 1, 0.8);
    #endif
    #if SDF == 2
        return sdHexagram(p, 0.5);
    #endif
    #if SDF == 3
        return sdHorseshoe(p, float2(cos(1.2),sin(1.2)),0.5,float2(0.750,0.2));
    #endif
     #if SDF == 4
       float closestD, closestT;
    float2 closest, _n;
    int closestID;
    bool _corner;
	
    getClosestSegment(p, closestD, closest, closestID, closestT);
    bool inside = isInside(p, closest, closestID, closestT, _n, _corner);

     float dist = closestD * (inside ? -1 : 1);
    return dist;
    #endif
    return 0.0f;
}

float2 getNormal(float2 p)
{
    float e = 0.0001;
    float2 n;
    n.x = map(p + float2(e, 0)) - map(p - float2(e, 0));
    n.y = map(p + float2(0, e)) - map(p - float2(0, e));


#if SDF == 4
     float closestD, closestT;
    float2 closest, _n;
    int closestID;
    bool _corner;
	
    getClosestSegment(p, closestD, closest, closestID, closestT);
    bool inside = isInside(p, closest, closestID, closestT, n, _corner);
#endif
    return normalize(n);

}

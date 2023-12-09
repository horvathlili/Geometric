/*
Copyright 2017 Martijn Steinrucken @BigWings
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/4sXBRn
*/

/******************************************************************************
 This work is a derivative of work by Martijn Steinrucken used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef jelly_glsl
#define jelly_glsl

#define MAX_DISTANCE 100.

#define iTime g3d_SceneTime

static const float halfpi = 1.570796326794896619;

float JELLY_N1(float x)
{
    return frac(sin(x) * 5346.1764);
}
float JELLY_N2(float x, float y)
{
    return JELLY_N1(x + y * 23414.324);
}

float N3(float3 p)
{
    p = frac(p * 0.3183099 + .1);
    p *= 17.0;
    return frac(p.x * p.y * p.z * (p.x + p.y + p.z));
}

struct jelly_de
{
    // data type used to pass the various bits of information used to shajelly_de a jelly_de object
    float d; // final distance to field
    float m; // material
    float3 uv;
    float pump;
    
    float3 id;
    float3 pos; // the world-space coordinate of the fragment
};
    
// ============== Functions I borrowed ;)

//  3 out, 1 in... DAVE HOSKINS
float3 N31(float p)
{
    float3 p3 = frac(float3(p) * float3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// jelly_de functions from IQ
float jelly_smin(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(b, a, h) - k * h * (1.0 - h);
}

float jelly_smax(float a, float b, float k)
{
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return lerp(a, b, h) + k * h * (1.0 - h);
}

float sdSphere(float3 p, float3 pos, float s)
{
    return (length(p - pos) - s);
}

// From http://mercury.sexy/hg_sdf
float2 jelly_pModPolar(inout float2 p, float repetitions, float fix)
{
    float angle = PI * 2.0 / repetitions;
    float a = atan2(p.y, p.x) + angle / 2.;
    float r = length(p);
    float c = floor(a / angle);
    a = a%angle - (angle / 2.) * fix;
    p = float2(cos(a), sin(a)) * r;

    return p;
}

float Dist(float2 P, float2 P0, float2 P1)
{
    //2d point-line distance
    
    float2 v = P1 - P0;
    float2 w = P - P0;

    float c1 = dot(w, v);
    float c2 = dot(v, v);
    
    if (c1 <= 0.)  // before P0
        return length(P - P0);
    
    float b = c1 / c2;
    float2 Pb = P0 + b * v;
    return length(P - Pb);
}

float3 ClosestPoint(float3 ro, float3 rd, float3 p)
{
    // returns the closest point on ray r to point p
    return ro + max(0., dot(p - ro, rd)) * rd;
}

float2 RayRayTs(float3 ro1, float3 rd1, float3 ro2, float3 rd2)
{
    // returns the two t's for the closest point between two rays
    // ro+rd*t1 = ro2+rd2*t2
    
    float3 dO = ro2 - ro1;
    float3 cD = cross(rd1, rd2);
    float v = dot(cD, cD);
    
    float t1 = dot(cross(dO, rd2), cD) / v;
    float t2 = dot(cross(dO, rd1), cD) / v;
    return float2(t1, t2);
}

float DistRaySegment(float3 ro, float3 rd, float3 p1, float3 p2)
{
    // returns the distance from ray r to line segment p1-p2
    float3 rd2 = p2 - p1;
    float2 t = RayRayTs(ro, rd, p1, rd2);
    
    t.x = max(t.x, 0.);
    t.y = clamp(t.y, 0., length(rd2));
                
    float3 rp = ro + rd * t.x;
    float3 sp = p1 + rd2 * t.y;
    
    return length(rp - sp);
}

float2 sph(float3 ro, float3 rd, float3 pos, float radius)
{
    // does a ray sphere intersection
    // returns a float2 with distance to both intersections
    // if both a and b are MAX_DISTANCE then there is no intersection
    
    float3 oc = pos - ro;
    float l = dot(rd, oc);
    float det = l * l - dot(oc, oc) + radius * radius;
    if (det < 0.0)
        return float2(MAX_DISTANCE);
    
    float d = sqrt(det);
    float a = l - d;
    float b = l + d;
    
    return float2(a, b);
}

float rejelly_map(float a, float b, float c, float d, float t)
{
    return ((t - a) / (b - a)) * (d - c) + c;
}

jelly_de jelly_map(float3 p, float3 id)
{

    float t = 62.5;//iTime*2.;
   // float t = iTime * 2.;
    
    float N = N3(id);
    
    jelly_de o;
    o.m = 0.;
    
    float x = (p.y + N * PI * 2.0) * 1. + t;
    float r = 1.;
    
    float pump = cos(x + cos(x)) + sin(2. * x) * .2 + sin(4. * x) * .02;
    
    x = t + N * PI * 2.0;
    p.y -= (cos(x + cos(x)) + sin(2. * x) * .2) * .6;
    p.xz *= 1. + pump * .2;
    
    float d1 = sdSphere(p, float3(0., 0., 0.), r);
    float d2 = sdSphere(p, float3(0., -.5, 0.), r);
    
    o.d = jelly_smax(d1, -d2, .1);
    o.m = 1.;
    
    if (p.y < .5)
    {
        float sway = sin(t + p.y + N * PI * 2.0) * smoothstep(.5, -3., p.y) * N * .3;
        p.x += sway * N; // add some sway to the tentacles
        p.z += sway * (1. - N);
        
        float3 mp = p;
        mp.xz = jelly_pModPolar(mp.xz, 6., 0.);
        
        float d3 = length(mp.xz - float2(.2, .1)) - rejelly_map(.5, -3.5, .1, .01, mp.y);
        if (d3 < o.d)
            o.m = 2.;
        d3 += (sin(mp.y * 10.) + sin(mp.y * 23.)) * .03;
        
        float d32 = length(mp.xz - float2(.2, .1)) - rejelly_map(.5, -3.5, .1, .04, mp.y) * .5;
        d3 = min(d3, d32);
        o.d = jelly_smin(o.d, d3, .5);
        
        if (p.y < .2)
        {
            float3 op = p;
            op.xz = jelly_pModPolar(op.xz, 13., 1.);
            
            float d4 = length(op.xz - float2(.85, .0)) - rejelly_map(.5, -3., .04, .0, op.y);
            if (d4 < o.d)
                o.m = 3.;
            o.d = jelly_smin(o.d, d4, .15);
        }
    }
    o.pump = pump;
    o.uv = p;
    
    o.d *= .8;
    return o;
}

float jellysdf(float3 p)
{
    p += float3(0., -0.6, 0.);
    const float scale = 0.26;
    p *= 1. / scale;
    return jelly_map(p, float3(0.)).d * scale;
}

#endif

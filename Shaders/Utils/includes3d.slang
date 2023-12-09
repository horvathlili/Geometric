#include "ray.slang"
#include "spheretrace.slang"


#ifndef FIELD
#define FIELD 1
#endif


#if FIELD == 0
#include "../Interpolation/filterg03d.slang"
#endif
#if FIELD == 1
#include "../Interpolation/filterg13d.slang"
#endif
#if FIELD == 2
#include "../Interpolation/filterg23d.slang"
#endif


cbuffer psCb
{
    float4 eye;
    float4 center;
    float4 up;
    float ar;
    int res;
    float boundingBox;
    float4x4 viewproj;
    bool box;
    float3 debugpos;
    bool debugging;
    bool showtest;
    int restest;
    float a;
    float b;
    float rel;
};

SamplerState mSampler;

Texture3D texture1;
Texture3D texture2;
Texture3D texture3;
Texture2D testtexture;


bool isOutOfBox(float3 pos)
{
    bool r = (pos.x > -boundingBox / 2.0 && pos.x < boundingBox / 2.0 &&
        pos.y > -boundingBox / 2.0 && pos.y < boundingBox / 2.0 &&
        pos.z > -boundingBox / 2.0 && pos.z < boundingBox / 2.0);
    return !r;

}

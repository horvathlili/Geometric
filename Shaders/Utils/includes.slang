#include "ray.slang"
#include "spheretrace.slang"

#ifndef FIELD
#define FIELD 1
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
};

Texture3D texturefp;
Texture3D texturen;
Texture3D texturennn;
Texture2D testtexture;

bool isOutOfBox(float3 pos)
{
    bool r = (pos.x > -boundingBox / 2.0 && pos.x < boundingBox / 2.0 &&
        pos.y > -boundingBox / 2.0 && pos.y < boundingBox / 2.0 &&
        pos.z > -boundingBox / 2.0 && pos.z < boundingBox / 2.0);
    return !r;

}

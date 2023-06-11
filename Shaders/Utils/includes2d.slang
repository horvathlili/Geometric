
#ifndef FIELD
#define FIELD 1
#endif


#if FIELD == 0
#include "../Interpolation/filterg02d.slang"
#endif
#if FIELD == 1
#include "../Interpolation/filterg12d.slang"
#endif



cbuffer psCb
{
    int res;
    bool debug;
}

Texture2D texture1;
Texture2D texture2;

SamplerState mSampler;


#ifndef FIELD
#define FIELD 1
#endif


#if FIELD == 0
#include "../Interpolation/filterg02d.slang"
#endif
#if FIELD == 3
#include "../Interpolation/filtermsdf.slang"
#endif
#if FIELD == 1
#include "../Interpolation/filterg12d.slang"
#endif



cbuffer psCb
{
    int res;
    bool debug;
    bool originalsdf;
    float boundingBox;
    float dx;
    float dy;
    int bit;
    float fpmax;
}

Texture2D texture1;
Texture2D texture2;
Texture2D textureCSG;
Texture2D msdftexture;
Texture2D osdftexture;

SamplerState mSampler;

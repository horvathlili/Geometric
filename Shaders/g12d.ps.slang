#include "Interpolation/filter2d.slang"

struct psIn
{
    float4 pos : SV_POSITION;
    float3 col : COLOR;
    float2 pixelpos : POSITION;
};

struct PsOut
{
    float4 col : SV_TARGET;
    
};

cbuffer psCb
{
    int res;
    float2 debugpos;
}

Texture2D texture;

PsOut main(psIn input) : SV_TARGET
{
    PsOut o;   

    int a = (filter(input.pixelpos.xy) > 0) ? 1 : 0;
       
    o.col = float4(a, a, a, 1);
  
    return o;
}

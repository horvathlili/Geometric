#include "../SDF/sdf2d.slang"


RWTexture2D<float4> tex;

RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
    int contourN;
};

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;
    float dist = 0;

   
    float2 tt = float2(-boundingBox / 2.0) +(threadId.xy + 0.5) * boundingBox / (float2) res;
    //tt *= float2(4, 2.25);
   
    
    dist = map(tt);
    tex[threadId.xy] = float4(dist,0,0,0);
   
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(dist,0,0,0);
  
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



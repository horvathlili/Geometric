#include "../SDF/sdf2d.slang"

RWTexture2D<float4> tex;

RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
};

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;

    float2 t = float2(-boundingBox / 2.0) + (threadId.xy + 0.5) * boundingBox / (float2) res;
    t *= float2(4, 2.25);

   
    tex[threadId.xy] = float4(map(t),0,0,0);
   
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(map(t),0,0,0);
  
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



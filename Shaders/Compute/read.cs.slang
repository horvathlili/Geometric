#ifndef FIELD
#define FIELD 1
#endif


RWTexture3D<float4> texfp;
RWTexture3D<float4> texn;
RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;
RWStructuredBuffer<float4> posdata;



RWTexture3D<float4> texfpr;
RWTexture3D<float4> texdR;
RWStructuredBuffer<float4> data3;



cbuffer csCb
{
    int res;
};


[numthreads(8, 8,8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xyz >= float3(res)))
        return;

    float4 index = posdata[threadId.x * res * res + threadId.y * res + threadId.z];

    #if FIELD == 0 //3D G0
         texfp[index.xyz] = data1[threadId.x * res * res + threadId.y * res + threadId.z];
    #endif
    
    #if FIELD == 1 //3D G1
        texfp[index.xyz] = data1[threadId.x * res * res + threadId.y * res + threadId.z];
        texn[index.xyz] = data2[threadId.x * res * res + threadId.y * res + threadId.z];
    #endif
    #if FIELD == 2 //3D G2
    texfpr[index.xyz] = data1[threadId.x * res * res + threadId.y * res + threadId.z];
    texdR[index.xyz] = data2[threadId.x * res * res + threadId.y * res + threadId.z];
    texn[index.xyz] = data3[threadId.x * res * res + threadId.y * res + threadId.z];
    #endif
}

#include "../SDF/sdf3d.slang"

RWTexture3D<float4> texfp;
RWTexture3D<float4> texn;
RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;

RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
};


[numthreads(8, 8,8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xyz >= float3(res)))
        return;

    float3 pos = float3(-(float) boundingBox / 2.0);
    pos.x += (float) boundingBox / (float) res * (threadId.x + 0.5);
    pos.y += (float) boundingBox / (float) res * (threadId.y + 0.5);
    pos.z += (float) boundingBox / (float) res * (threadId.z + 0.5);

    float3 n, fp;
    
    n = getNormal(pos);
    fp = pos - map(pos) * n;

    int s = 0;
    while (abs(map(fp)) > 0.000001 && s < 40)
    {
        n = getNormal(fp);
        fp = fp - n * map(fp);
        s++;
    }


    n = getNormal(fp);

    int datai = threadId.x * res * res + threadId.y * res + threadId.z;
     
    texfp[threadId.xyz] = float4(fp,0);
    data1[datai] = float4(fp, 0);
    texn[threadId.xyz] = float4(n, 0);
    data2[datai] = float4(n, 0);
    posdata[datai] = float4(threadId.xyz, 1);
}

#include "../SDF/sdf3d.slang"

RWStructuredBuffer<float> x0;
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

float distP(float4 s, float3 pos)
{
    return s.r * pos.x + s.g * pos.y + s.b * pos.z + s.a;
}




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


    /*float3 delta = boundingBox / float3(res);
    
    float3 xi = (threadId.xyz + 0.5) * delta - boundingBox / 2.0;


    float f[27];
    
    for (int i = -1; i <= 1; i++)
    {
        for (int j = -1; j <= 1; j++)
        {
            for (int k = -1; k <= 1; k++)
            {
                float3 x = xi + float3(i, j, k) * 0.6f * delta;

                f[(i + 1) * 9 + (j + 1) * 3 + (k + 1)] = map(x);
            }
        }
    }

    float4 ai;

    for (int l = 0; l < 4; l++)
    {
        float aa = 0;
        for (int j = 0; j < 27; j++)
        {
            aa += x0[l * 27 + j] * f[j];
        }
        if (l == 3)
        {
            aa -= dot(ai.rgb, xi);
        }
        ai[l] = aa;
    }

    float3 n = ai.rgb;
    float3 fp = pos - distP(ai,pos) * n;

    int s = 0;
    while (abs(distP(ai,fp)) > 0.000001 && s < 40)
    {
       
        fp = fp - n * distP(ai,fp);
        s++;
    }*/


  


    int datai = threadId.x * res * res + threadId.y * res + threadId.z;
     
    texfp[threadId.xyz] = float4(fp,0);
    data1[datai] = float4(fp,0);
    texn[threadId.xyz] = float4(n, 0);
    data2[datai] = float4(n, 0);
    posdata[datai] = float4(threadId.xyz, 1);
}

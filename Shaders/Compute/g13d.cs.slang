#include "../SDF/sdf3d.slang"

RWStructuredBuffer<float> x0;
RWTexture3D<float4> texfp;
RWTexture3D<float4> texn;
RWTexture3D<float4> texn2;
RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;

RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
    float rel;
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

    float3 fp2,n2;

  
  int s = 0;
    while (abs(map(fp)) > 0.001 && s < 40)
    {
        n = getNormal(fp);
        fp = fp - rel*n * map(fp);
        s++;
    }
    s = 0;
   
    n = getNormal(fp);

    int is = map(pos) < 0 ? -1 : 1;
   n = normalize(pos - fp) * is;

   
  
    int inside = 0;
    int outside = 0;

    for (int i = -3; i <= 3; i++)
    {
        for (int j = -3; j <= 3; j++)
        {
            for (int k= -3; k <= 3; k++)
            {
            
                float3 fp3 = fp + float3(i, j, k) *1/7.0f * boundingBox / (float3) res * 0.5;
            
            

            

                if (map(fp3) <= 0)
                {
                    inside++;
                }
                else
                {
                    outside++;
                }
            }

        }
    }

    int conv = 1;

    if (inside >= outside)
    {
        conv = -1;
    }

    int datai = threadId.x * res * res + threadId.y * res + threadId.z;


    float h = -dot(n, fp);
    float d = dot(pos, n) + h;
   
     
    texfp[threadId.xyz] = float4(fp,conv);
    data1[datai] = float4(fp, conv);
    texn[threadId.xyz] = float4(n, 0);
    data2[datai] = float4(n, 0);
    texn2[threadId.xyz] = float4(getNormal(fp), 0);
    posdata[datai] = float4(threadId.xyz, 1);
}

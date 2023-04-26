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


bool equal(float2 n1, float2 n2, float e)
{
    bool b1 = abs(n1.x - n2.x) < e;
    bool b2 = abs(n1.y - n2.y) < e;

    return b1 && b2;
}

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;

    float2 t = float2(-boundingBox / 2.0) + (threadId.xy + 0.5) * boundingBox / (float2) res;
    t *= float2(4, 2.25);

    float2 n = getNormal(t);
    float2 fp = t - n * map(t);

   /* float2 nn[25];

    for (int i = -2; i <= 2; i++)
    {
        for (int j = -2; j <= 2; j++)
        {
            float2 tt = fp + float2(i, j) * 1 / 4.0f * boundingBox / (float2) res * 0.1f;
            
            nn[(i + 2) * 5 + j +2] = getNormal(tt);

        }
    }

    int m = 1;
    int h = -1;

    for (int i = 0; i < 25; i++)
    {
        int db = 0;
        for (int j = 0; j < 25; j++)
        {
            if (equal(nn[i], nn[j], 0.01))
            {
                db++;
            }
        }
        if (db > m)
        {
            m = db;
            h = i;
        }
    }
    if (h > -1)
    {
        n = nn[h];

    }*/
        tex[threadId.xy] = float4(fp, n);
    
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(fp, n);
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



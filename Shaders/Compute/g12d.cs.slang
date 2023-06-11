#include "../SDF/sdf2d.slang"

RWTexture2D<float4> tex;
RWTexture2D<float4> tex2;

RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;
RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
};


bool equal(float2 n1, float2 n2, float e)
{
    /*bool b1 = abs(n1.x - n2.x) < e;
    bool b2 = abs(n1.y - n2.y) < e;*/

    //return b1 && b2;

    return dot(normalize(n1), normalize(n2)) > cos(e);

}

float2 getFootpoint(float2 t)
{
    float2 n = getNormal(t);

    float2 fp = t - normalize(n) * map(t);
    int s = 0;

    while (abs(map(fp)) > 0.0001 && s < 20)
    {
        fp = fp - normalize(getNormal(fp)) * map(fp);
        s++;
    }

    return fp;
}

float sdLine(float2 p, float2 fp, float2 n)
{

    return dot(p - fp, n);
}

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;

    float2 t = float2(-boundingBox / 2.0) + (threadId.xy + 0.5) * boundingBox / (float2) res;
    t *= float2(4, 2.25);

    float2 n = getNormal(t);

    float2 fp = getFootpoint(t);
    
    float2 nn[25];
    float2 tp[25];

    for (int i = -2; i <= 2; i++)
    {
        for (int j = -2; j <= 2; j++)
        {
            float2 tt = fp + float2(i, j) * 1 / 4.0f * boundingBox / (float2) res * 0.1f;
            
            nn[(i + 2) * 5 + j +2] = getNormal(tt);
            tp[(i + 2) * 5 + j + 2] = tt;

        }
    }

    float2 n1;
    
    int m1 = 0;
    int h1 = -1;
    int m2 = 0;
    int h2 = -1;

    for (int i = 0; i < 25; i++)
    {
        int db = 0;
        for (int j = 0; j < 25; j++)
        {
            if (equal(nn[i], nn[j], 0.001))
            {
                db++;
            }
        }
        if (db > m1)
        {
            m1 = db;
            h1 = i;
        }
    }

    float2 fp1 = fp;
    float2 fp2 = fp;
    
    float2 n2 = float2(0, 0);
    if (h1 > -1)
    {
        n1 = nn[h1];
        fp1 = getFootpoint(tp[h1]);

    }
    else
    {
        n1 = getNormal(fp);
    }

    for (int i = 0; i < 25; i++)
    {
        if (equal(nn[i], n1, 0.01))
        {
            nn[i] = float2(0, 0);
        }

    }
    for (int i = 0; i < 25; i++)
    {
        int db = 0;
        for (int j = 0; j < 25; j++)
        {
            if (equal(nn[i], nn[j], 0.001) && (nn[i].x != 0 || nn[i].y != 0) && (nn[j].x != 0 || nn[j].y != 0))
            {
                db++;
            }
        }
        if (db > m2)
        {
            m2 = db;
            h2 = i;
        }
    }

        if (h2 > -1)
        {
            n2 = nn[h2];
        fp2 = getFootpoint(tp[h2]);
    }
        else
        {
            n2 = getNormal(fp);
        }

    if (sdLine(fp1, fp2, n2) > 0 && sdLine(fp2, fp1, n1) > 0)
    {
        n1 = 2 * n1;
    }

    
    tex[threadId.xy] = float4(fp, n);
    tex2[threadId.xy] = float4(n1, n2);
    
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(fp, n);
    data2[datai] = float4(n1, n2);
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



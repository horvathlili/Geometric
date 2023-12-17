#include "../SDF/sdf2d.slang"

RWTexture2D<float3> tex;
RWTexture2D<float3> tex2;

RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;
RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
    int bit;
};


bool equal(float2 fp1, float2 fp2, float e)
{
    return length(fp1 - fp2) < e;

}

float2 fpto8bit(float2 fp)
{
    float2 fp1 = fp / float2(boundingBox) + float2(0.5);
    return fp1;
}
float nto8bit(float n)
{
    float n1 = n / 4 + float(0.5);
    return n1;
}

float2 getFootpoint(float2 t)
{
    float2 n = getNormal(t);

    float2 fp = t - normalize(n) * map(t);
    int s = 0;

    while (abs(map(fp)) > 0.000001 && s < 20)
    {
        fp = fp - normalize(getNormal(fp)) * map(fp);
        s++;
    }

    #if SDF==4
         float closestD, closestT;
        float2 closest, _n;
        int closestID;
        bool _corner;
	
         getClosestSegment(t, closestD, closest, closestID, closestT);
         bool inside = isInside(t, closest, closestID, closestT, n, _corner);

        fp = closest;
    #endif
    return fp;
}

float sdLine(float2 p, float2 fp, float2 n)
{

    return dot(float3(p, 1), float3(n, -dot(fp, n)));
}

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;

    float2 t = float2(-boundingBox / 2.0) + (threadId.xy + 0.5) * boundingBox / (float2) res;
    
    float2 n = normalize(getNormal(t));

    float2 fp = getFootpoint(t);
    float2 fpo = fp;
    
    float2 nn[49];
    float2 tp[49];

    int inside = 0;
    int outside = 0;

    for (int i = -3; i <= 3; i++)
    {
        for (int j = -3; j <= 3; j++)
        {
            float2 tt = t + float2(i, j) * 1 / 6.0f * boundingBox / (float2) res*0.5;
            float2 fp2 = fp + float2(i, j) * 1 / 6.0f * boundingBox / (float2) res * 0.01;
            
            nn[(i + 3) * 7 + j + 3] = getNormal(tt);
            tp[(i + 3) * 7 + j + 3] = getFootpoint(tt);

            

            if (map(fp2) <= 0)
            {
                inside++;
            }
            else
            {
                outside++;
            }

        }
    }

    n = normalize(n);

    float no = map(t) < 0 ? -1 : 1;
    
    //belső sarok
    if (inside > outside)
        no *= 2;

    if (bit == 8)
    {
       // fpo = fpto8bit(fpo);
       // no = nto8bit(no);

    }
    
    tex[threadId.xy] = float3(fp, no);
    
    tex2[threadId.xy] = float3(fpo, no);
    
    int datai = threadId.x * res + threadId.y;

    
    
    data1[datai] = float4(fp, n);
    data2[datai] = float4(fpo, no,0);
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



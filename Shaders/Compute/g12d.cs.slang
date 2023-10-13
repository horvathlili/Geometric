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
    //int contourN;
};


bool equal(float2 fp1, float2 fp2, float e)
{
    return abs(fp1.x - fp2.x) < e && abs(fp1.y - fp2.y) < e;

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
  //  t *= float2(4, 2.25);
   
    float2 n = normalize(getNormal(t));

    float2 fp = getFootpoint(t);
    
    float2 nn[36];
    float2 tp[49];

  // ez itt totál össze vissza ki kell javítani
    for (int i = -3; i <= 3; i++)
    {
        for (int j = -3; j <= 3; j++)
        {
            float2 tt = t + float2(i, j) * 1 / 7.0f * boundingBox / (float2) res*0.1;
            
            nn[(i + 3) * 7 + j + 3] = getNormal(tt);
            tp[(i + 3) * 7 + j + 3] = getFootpoint(tt);
        }
    }

    n = normalize(n);
    
    int db = 0;

    for (int l = 0; l < 49; l++)
    {
       
            
        if (equal(tp[l], fp, 0.0000001))
        {
            db++;
        }
       

    }

    if (db >=40)
    {
        n = float2(10, 10);

        if (map(t) < 0)
        {
            n = float2(-10, -10);
        }
    }
    

   /* if (inside > outside)
        n *= 2;*/
    
    tex[threadId.xy] = float4(fp, n);
    
    tex2[threadId.xy] = float4(n, n);
    
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(fp, n);
    data2[datai] = float4(n, n);
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}



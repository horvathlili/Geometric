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


bool equal(float2 fp1, float2 fp2, float e)
{
    return length(fp1 - fp2) < e;

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
    float2 no = n;

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
    
    int db = 0;

    for (int l = 0; l < 49; l++)
    {
       
            
        if (equal(tp[l], fp, 0.0001))
        {
            db++;
        }
       

    }

    if (db >14)
    {

        //elenőrzöm, hogy kell-e pontot tárolni
        n = float2(10, 10);

        if (map(t) < 0)
        {
            n = float2(-10, -10);
        }
    }


    //pontról van szó

    if (length(n) > 10)
    {
        //nézzük lehet e valami jobb
        float2 fp1, n1, fp3, n3;
        n1 = float2(-10, -10);
        n3 = float2(-10, -10);

        for (int i = -1; i <= 1; i++)
        {
            for (int j = -1; j <= 1; j++)
            {

                if (i == 0 || j == 0) //olyan cellák amikkel interakcióban van
                {
                    float2 tt = t + float2(i, j) * boundingBox / (float2) res;
            
              
               

                    float2 fp2 = getFootpoint(tt);

                    float2 n2 = getNormal(tt);

                    if (!equal(fp2, fp, 0.00001) && abs(sdLine(fp, fp2, n2)) < 0.00001)
                    {
                        if (length(n1) > 4 && map(t) * sdLine(t, fp2, n2) > 0)
                        {
                            fp1 = fp2;
                            n1 = n2;
                        }

                        if (length(n3) > 4 && map(t) * sdLine(t, fp2, n2) < 0)
                        {
                            fp3 = fp2;
                            n3 = n2;
                        }

                        if (abs(sdLine(t, fp2, n2)) < abs(sdLine(t, fp1, n1)) && map(t) * sdLine(t, fp2, n2) > 0)
                        {
                            fp1 = fp2;
                            n1 = n2;
                        }

                        if (abs(sdLine(t, fp2, n2)) < abs(sdLine(t, fp3, n3)) && map(t) * sdLine(t, fp2, n2) < 0)
                        {
                            fp3 = fp2;
                            n3 = n2;
                        }
                    

                    }
                }

            }
        }

        if (length(n1) < 10)
        {
            fp = fp1;
            n = n1;
        }
        else
        {
            if (length(n3) < 10)
            {
                fp = fp3;
                n = n3;
            }
        }
        
        
    }
    
    //belső sarok
    if (inside > outside)
        no *= 2;
    
    tex[threadId.xy] = float4(fp, n);
    
    tex2[threadId.xy] = float4(fpo, no);
    
    int datai = threadId.x * res + threadId.y;

    data1[datai] = float4(fp, n);
    data2[datai] = float4(fpo, no);
    posdata[datai] = float4(threadId.xy, 0, 0);
    
}




RWTexture2D<float4> texcsg;
RWTexture2D<float3> tex8;

Texture2D texture2;


cbuffer csCb
{
    int sdf;
    int res;
    int bit;
    float max;
    float boundingBox;
};


float2 getn2(float2 fp, float n, float2 uv)
{
  
    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 nn = t - fp;

    if (n < 0)
    {
        nn *= -1;
    }

    return nn;
}


float sdLine(float2 p, float2 fp, float2 n)
{

    
    return dot(p - fp, n);
    
}

float csgDist(float2 pp, float2 fp, float2 n, float2 uv)
{
    return sdLine(pp, fp, normalize(n));
}


int csg2nopoint(float2 fp[4],float2 n[4],float2 uv[4], int c1, int c2)
{
    int cc = 0;

                                                                      
   
        //metszet kell
    if (csgDist(fp[c1], fp[c2],n[c2],uv[c2]) <= 0 && csgDist(fp[c2], fp[c1],n[c1],uv[c1]) <= 0)
    {
        cc = 0;

    }

        //unió kell
    if (csgDist(fp[c1], fp[c2], n[c2],uv[c2]) >= 0 && csgDist(fp[c2], fp[c1], n[c1],uv[c1]) >= 0)
    {
        cc = 1;
    }

        
    if (csgDist(fp[c1], fp[c2],n[c2],uv[c2]) * csgDist(fp[c2], fp[c1],n[c1],uv[c1]) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
        cc = 1;

              //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fp[c1], fp[c2], n[c2],uv[c2])) <= boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c2], fp[c1], n[c1],uv[c1]) >= 0)
            {
                cc = 1;
            }
                //return 1;

          
        }

        if (abs(csgDist(fp[c2], fp[c1], n[c1],uv[c1])) < boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c1], fp[c2], n[c2],uv[c2]) >= 0)
            {
                cc = 1;
            }

           
        }

    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
    if (abs(csgDist(fp[c1], fp[c2], n[c2],uv[c2])) < 0.0001 && abs(csgDist(fp[c2], fp[c1], n[c1],uv[c1])) < 0.0001)
    {

            //return 1;

        cc = 1;
            
        
        if (length(n[c1]) > 1 || length(n[c2]) > 1)
        {
                
            cc = 1;
        }
        if (length(n[c1]) <= 1.1 && length(n[c2]) <= 1.1)
        {
                
            cc = 0;
        }

        

    }

    

    return cc;
 
}

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res)))
        return;

    if (any(threadId.xy >= float2(res - 1)))
    {
        tex8[threadId.xy].xy = texture2[threadId.xy].xy / 2.f / float2(max) + float2(0.5f);
        tex8[threadId.xy].z = texture2[threadId.xy].z / 4.f + 0.5f;
        return;
    }

    tex8[threadId.xy].xy = texture2[threadId.xy].xy / 2.f / float2(max) + float2(0.5f);
    tex8[threadId.xy].z = texture2[threadId.xy].z / 4.f + 0.5f;
    
    float c[6];
    int2 uvs = threadId.xy;
    
    float2 fp[4];
    float2 n[4];
    float2 uv[4] = { uvs, uvs + float2(1, 0), uvs + float2(1, 1), uvs + float2(0, 1) };

   

    fp[0] = texture2[uvs].xy;
    n[0] = getn2(fp[0], texture2[uvs].z, uvs);

   
    fp[1] = texture2[uvs + float2(1, 0)].xy;
    n[1] = getn2(fp[1], texture2[uvs + float2(1, 0)].z, uvs + float2(1, 0));
  
    fp[2] = texture2[uvs + float2(1, 1)].xy;
    n[2] = getn2(fp[2], texture2[uvs + float2(1, 1)].z, uvs + float2(1, 1));
   
    fp[3] = texture2[uvs + float2(0, 1)].xy;
    n[3] = getn2(fp[3], texture2[uvs + float2(0, 1)].z, uvs + float2(0, 1));

    /*if (bit == 8)
    {
        fp[0] = fpfrom8bit(fp[0]);
        fp[1] = fpfrom8bit(fp[1]);
        fp[2] = fpfrom8bit(fp[2]);
        fp[3] = fpfrom8bit(fp[3]);
    }*/

    
    for (int i = 0; i < 4; i++)
    {
      
        c[i] = csg2nopoint(fp, n, uv,i, (i + 1) % 4);

    }
   
    
   
        c[4] = csg2nopoint(fp,n,uv, 0, 2);
   
        c[5] = csg2nopoint(fp,n,uv, 1, 3);


    texcsg[threadId.xy] = float4(c[0], c[1], c[2] + c[4] * 10, c[3] + c[5] * 10);
    
    
}




RWTexture2D<float4> texcsg;

Texture2D texture2;


cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
};



float sdLine(float2 p, float2 fp, float2 n)
{

    
    return dot(p - fp, n);
    
}

float csgDist(float2 pp, float2 fp, float2 n)
{
  
    return sdLine(pp, fp, normalize(n));
}


int csg2nopoint(float2 fp[4],float2 n[4], int c1, int c2)
{
    int cc = 0;


   
        //metszet kell
    if (csgDist(fp[c1], fp[c2],n[c2]) <= 0 && csgDist(fp[c2], fp[c1],n[c1]) <= 0)
    {
        cc = 0;

    }

        //unió kell
    if (csgDist(fp[c1], fp[c2], n[c2]) >= 0 && csgDist(fp[c2], fp[c1], n[c1]) >= 0)
    {
        cc = 1;
    }

        
    if (csgDist(fp[c1], fp[c2],n[c2]) * csgDist(fp[c2], fp[c1],n[c1]) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
        cc = 1;

              //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fp[c1], fp[c2], n[c2])) <= boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c2], fp[c1], n[c1]) >= 0)
            {
                cc = 1;
            }
                //return 1;

          
        }

        if (abs(csgDist(fp[c2], fp[c1], n[c1])) < boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c1], fp[c2], n[c2]) >= 0)
            {
                cc = 1;
            }

           
        }

    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
    if (abs(csgDist(fp[c1], fp[c2], n[c2])) < 0.0001 && abs(csgDist(fp[c2], fp[c1], n[c1])) < 0.0001)
    {

            //return 1;

        cc = 1;
            
        
        if (length(n[c1]) > 1 || length(n[c2]) > 1)
        {
                
            cc = 1;
        }
        if (length(n[c1]) <= 1.5 && length(n[c2]) <= 1.5)
        {
                
            cc = 0;
        }

        

    }

    

    return cc;
 
}

[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    
    
    if (any(threadId.xy >= float2(res-1)))
        return;

    
    float c[6];

    
    float2 fp[4];
    float2 n[4];

    int2 uv = threadId.xy;

    fp[0] = texture2[uv].xy;
    n[0] = texture2[uv].zw;
   
    fp[1] = texture2[uv + float2(1, 0)].xy;
    n[1] = texture2[uv + float2(1, 0)].zw;
   
    fp[2] = texture2[uv + float2(1, 1)].xy;
    n[2] = texture2[uv + float2(1, 1)].zw;
   
    fp[3] = texture2[uv + float2(0, 1)].xy;
    n[3] = texture2[uv + float2(0, 1)].zw;


    
    for (int i = 0; i < 4; i++)
    {
      
        c[i] = csg2nopoint(fp, n, i, (i + 1) % 4);

    }
   
    
   
        c[4] = csg2nopoint(fp,n, 0, 2);
   
        c[5] = csg2nopoint(fp,n, 1, 3);


    texcsg[threadId.xy] = float4(c[0], c[1], c[2] + c[4] * 10, c[3] + c[5] * 10);
    
    
}



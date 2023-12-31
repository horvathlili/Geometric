
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

float2 getfp(float dm, float2 n, float2 uv)
{
    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 fp = t - dm * normalize(n);

    return fp;
}


float sdLine(float2 p, float2 fp, float2 n)
{

    
    return dot(p - fp, n);
    
}

float csgDist(float2 pp, float2 fp, float2 n, float2 uv)
{
    return sdLine(pp, fp, normalize(n));
}


int csg2nopoint(float2 fp[4], float2 n[4], float2 uv[4], int c1, int c2)
{
    int cc = 0;

                                                                      
   
        //metszet kell
    if (csgDist(fp[c1], fp[c2], n[c2], uv[c2]) <= 0 && csgDist(fp[c2], fp[c1], n[c1], uv[c1]) <= 0)
    {
        cc = 0;

    }

        //unió kell
    if (csgDist(fp[c1], fp[c2], n[c2], uv[c2]) >= 0 && csgDist(fp[c2], fp[c1], n[c1], uv[c1]) >= 0)
    {
        cc = 1;
    }

        
    if (csgDist(fp[c1], fp[c2], n[c2], uv[c2]) * csgDist(fp[c2], fp[c1], n[c1], uv[c1]) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
        cc = 1;

              //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fp[c1], fp[c2], n[c2], uv[c2])) <= boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c2], fp[c1], n[c1], uv[c1]) >= 0)
            {
                cc = 1;
            }
                //return 1;

          
        }

        if (abs(csgDist(fp[c2], fp[c1], n[c1], uv[c1])) < boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c1], fp[c2], n[c2], uv[c2]) >= 0)
            {
                cc = 1;
            }

           
        }

    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
    if (abs(csgDist(fp[c1], fp[c2], n[c2], uv[c2])) < 0.0001 && abs(csgDist(fp[c2], fp[c1], n[c1], uv[c1])) < 0.0001)
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

   

    fp[0] = getfp(texture2[uvs].x, texture2[uvs].zw, uvs);
    n[0] = texture2[uvs].zw;

    n[1] = texture2[uvs + float2(1, 0)].zw;
    fp[1] = getfp(texture2[uvs + float2(1, 0)].x, n[1], uvs + float2(1, 0));
  
    n[2] = texture2[uvs + float2(1, 1)].zw;
    fp[2] = getfp(texture2[uvs + float2(1, 1)].x, n[2], uvs + float2(1, 1));

    n[3] = texture2[uvs + float2(0, 1)].zw;
    fp[3] = getfp(texture2[uvs + float2(0, 1)].x, n[3], uvs + float2(0, 1));
    /*if (bit == 8)
    {
        fp[0] = fpfrom8bit(fp[0]);
        fp[1] = fpfrom8bit(fp[1]);
        fp[2] = fpfrom8bit(fp[2]);
        fp[3] = fpfrom8bit(fp[3]);
    }*/

   

    
    for (int i = 0; i < 4; i++)
    {
      
        c[i] = csg2nopoint(fp, n, uv, i, (i + 1) % 4);

    }
   
    
   
    c[4] = csg2nopoint(fp, n, uv, 0, 2);
   
    c[5] = csg2nopoint(fp, n, uv, 1, 3);

    int csum = c[0] + c[1] + c[2] + c[3];

    int op[3], geo[4], tree;
    
    
    if (csum == 2)
    {
        
        float d = 10000;
        bool a = false;
        int b = 0;
        int i1 = -1;
        int i2;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
              //  d = min(d, max(cd[i], cd[(i + 1) % 4]));
                i2 = i;
                if (i1 == -1)
                    i1 = i;
                
                if (c[(i + 1) % 4] == 0)
                {
                    a = true;
                    b = i;
                }
            }
        }
        //return 1;
       // result = d;

       

        if (a)
        {

            
            

            int cc = c[b % 2 + 4];

            if (cc == 0)
            {
                //result = max(max(cd[b], cd[(b + 1) % 4]), cd[(b + 2) % 4]);
                //result = min(result, cd[(b + 3) % 4]);

                tree = 1;
                op[0] = 0;
                op[1] = 0;
                op[2] = 1;
                geo[0] = b;
                geo[1] = (b + 1) % 4;
                geo[2] = (b + 2) % 4;
                geo[3] = (b + 3) % 4;

            }
            else
            {
               // result = min(min(cd[b], cd[(b + 3) % 4]), cd[(b + 2) % 4]);
               // result = max(result, cd[(b + 1) % 4]);
                tree = 1;
                op[0] = 1;
                op[1] = 1;
                op[2] = 0;
                geo[0] = b;
                geo[1] = (b + 3) % 4;
                geo[2] = (b + 2) % 4;
                geo[3] = (b + 1) % 4;
            }
        }
        else
        {
            
            tree = 0;
            op[0] = 0;
            op[1] = 1;
            op[2] = 0;
            geo[0] = i1;
            geo[1] = (i1 + 1) % 4;
            geo[2] = i2;
            geo[3] = (i2 + 1) % 4;
            
        }
    }



    //EZ!!!!!!!
    //3 metszet 1 unió
    if (csum == 1)
    {

       
        float d1;
        float d2;

        int u1, u2, i1, i2;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 1)
            {
                i1 = i;
                i2 = (i + 1) % 4;
                u1 = (i + 2) % 4;
                u2 = (i + 3) % 4;

            }
        }

        //d1 = max(cd[u1], cd[u2]);
        //d2 = min(cd[i1], cd[i2]);
               
        
        //result = max(d1, d2);
        
        tree = 0;
        op[0] = 0;
        op[1] = 0;
        op[2] = 1;
        geo[0] = u1;
        geo[1] = u2;
        geo[2] = i1;
        geo[3] = i2;

       
    }


    //3 unió, egy metszet
    if (csum == 3)
    {
       // return 1;
        float d1;
        float d2;

        int u1, u2, i1, i2;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
                i1 = i;
                i2 = (i + 1) % 4;
                u1 = (i + 2) % 4;
                u2 = (i + 3) % 4;

            }
        }

       // d1 = min(cd[u1], cd[u2]);
      //  d2 = max(cd[i1], cd[i2]);
               
        tree = 0;
        op[0] = 1;
        op[1] = 1;
        op[2] = 0;
        geo[0] = u1;
        geo[1] = u2;
        geo[2] = i1;
        geo[3] = i2;

        if (c[i1 % 2 + 4] == 0)
        {
           // d1 = max(min(cd[u1], cd[i2]), cd[i1]);

            //result = min(d1, cd[u2]);

            tree = 1;
            op[0] = 1;
            op[1] = 0;
            op[2] = 1;
            geo[0] = u1;
            geo[1] = i2;
            geo[2] = i1;
            geo[3] = u2;
        }

        if (c[i2 % 2 + 4] == 0)
        {
           // d1 = max(max(cd[i1], cd[u2]), cd[i2]);

           // result = min(d1, cd[u1]);

            tree = 1;
            op[0] = 0;
            op[1] = 0;
            op[2] = 1;
            geo[0] = i1;
            geo[1] = u2;
            geo[2] = i2;
            geo[3] = u1;
        }
         

       
    }


    //csak unió, ez jó!
    if (csum == 4)
    {
        tree = 0;
        op[0] = 1;
        op[1] = 1;
        op[2] = 1;
        geo[0] = 0;
        geo[1] = 1;
        geo[2] = 2;
        geo[3] = 3;
    }


    // csak metszet (íves felület) ez jó!
    if (csum == 0)
    {
        tree = 0;
        op[0] = 0;
        op[1] = 0;
        op[2] = 0;
        geo[0] = 0;
        geo[1] = 1;
        geo[2] = 2;
        geo[3] = 3;
    }

    texcsg[threadId.xy] = float4(tree * 10 + geo[0], op[0] * 10 + geo[1], op[1] * 10 + geo[2], op[2] * 10 + geo[3]);
    
    
}



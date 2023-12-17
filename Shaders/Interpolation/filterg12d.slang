#ifndef INTERP
#define INTERP 0
#endif

static float2 fps[4];
static float ns[4];

float2 fpfrom8bit(float2 fp)
{
    float2 fp1 = 2.f*fpmax * (fp - 0.5);
    return fp1;
}
float nfrom8bit(float n)
{
    float n1 = 4 * (n - 0.5);
    return n1;
}

float2 getn(float2 fp, float2 uv)
{
    float2 fp = texture2[uv].xy;
    float n = texture2[uv].z;

    if (bit == 8)
    {
    
        fp = fpfrom8bit(fp);
        n = nfrom8bit(n);
    }

    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 nn = t - fp;

    if (n < 0)
    {
        nn *= -1;
    }

    return nn;
}

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

    
    return dot(p-fp, n);
    
}

float noInterp(float2 p)
{
    int2 uv = p * (res);

    float2 fp = texture2[uv].xy;
    float n = texture2[uv].z;

    if (bit == 8)
    {
        n = nfrom8bit(n);
        fp = fpfrom8bit(fp);
    }

    float2 nn = getn2(fp, n,uv);

    

    float2 pp = (p - 0.5) *boundingBox;

    return sdLine(pp, fp, normalize(nn));
}


float csgDist(float2 pp, int i, int2 uv )
{
    float2 fp = fps[i].xy;
    float n = ns[i];

    float2 nn;
    
    if (bit == 8)
    {
    
        fp = fpfrom8bit(fp);
        n = nfrom8bit(n);

    }

    nn = getn2(fp,n, uv);
    
   
  
    return sdLine(pp, fp, normalize(nn));    
}

float bilinear(float2 p)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv,0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);
    
    float2 fp, n;
    float nn;
    fp = texture2[uv].xy;
    nn = texture2[uv].z;
    if (bit == 8)
    {
        fp = fpfrom8bit(fp);
        nn = nfrom8bit(nn);
    }
    n = getn2(fp, nn, uv);
    float d1 = sdLine(pos, fp, normalize(n));
    fp = texture2[uv + float2(1, 0)].xy;
    nn = texture2[uv + float2(1, 0)].z;
    if (bit == 8)
    {
        fp = fpfrom8bit(fp);
        nn = nfrom8bit(nn);
    }
    n = getn2(fp, nn, uv + float2(1, 0));
    float d2 = sdLine(pos, fp, normalize(n));;
    fp = texture2[uv + float2(0, 1)].xy;
    nn = texture2[uv + float2(0, 1)].z;
    if (bit == 8)
    {
        fp = fpfrom8bit(fp);
        nn = nfrom8bit(nn);
    }
    n = getn2(fp, nn, uv + float2(0, 1));
    float d3 = sdLine(pos, fp, normalize(n));;
    fp = texture2[uv + float2(1, 1)].xy;
    nn = texture2[uv + float2(1, 1)].z;
    if (bit == 8)
    {
        fp = fpfrom8bit(fp);
        nn = nfrom8bit(nn);
    }
    n = getn2(fp, nn, uv + float2(1, 1));
    float d4 = sdLine(pos, fp, normalize(n));;

    

    float d11 = lerp(d1, d2, ab.x);
    float d22 = lerp(d3, d4, ab.x);

    
    return lerp(d11, d22, ab.y);
}



float csg(float2 p,bool points)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);

    fps[0] = texture2[uv].xy;
    ns[0] = texture2[uv].z;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].z;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].z;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].z;

   
   
    float2 uvs[4] = { uv+float2(0, 0),uv+ float2(1, 0),uv+ float2(1, 1),uv+ float2(0, 1) };

    float result = 0;

    float c[6],cd[4];

    float4 cc = textureCSG[uv];
    c[0] = cc.r;
    c[1] = cc.g;
    c[2] = cc.b % 10;
    c[3] = cc.a % 10;
    c[4] = int(cc.b / 10);
    c[5] = int(cc.a / 10);

    for (int i = 0; i < 4; i++)
    {
        cd[i] = csgDist(pos, i,uvs[i]);
    }

   
  
        int csum = c[0] + c[1] + c[2] + c[3];

    if (csum == 2)
    {
        
        float d = 10000;
        bool a = false;
        int b = 0;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
                d = min(d, max(cd[i], cd[(i + 1) % 4]));
                if (c[(i + 1) % 4] == 0)
                {
                    a = true;
                    b = i;
                }
            }
        }
        //return 1;
        result = d;

       

        if (a)
        {

            
            

            int cc = c[b % 2 + 4];

            if (cc == 0)
            {
                result = max(max(cd[ b], cd[(b + 1) % 4]),cd[(b + 2) % 4]);
                result = min(result, cd[ (b + 3) % 4]);

            }
            else
            {
                result = min(min(cd[ b], cd[(b + 3) % 4]), cd[ (b + 2) % 4]);
                result = max(result, cd[ (b + 1) % 4]);

            }
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

        d1 = max(cd[ u1], cd[ u2]);
        d2 = min(cd[ i1], cd[ i2]);
               
        
        result = max(d1, d2);         

       
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

        d1 = min(cd[ u1], cd[ u2]);
        d2 = max(cd[ i1], cd[ i2]);
               
        
        result = min(d1, d2);

        if (c[i1%2 + 4] == 0)
        {
            d1 = max(min(cd[ u1], cd[ i2]), cd[ i1]);

            result = min(d1, cd[ u2]);

          // return 1;
        }

        if (c[i2%2 + 4] == 0)
        {
            d1 = max(max(cd[ i1], cd[ u2]), cd[ i2]);

            result = min(d1, cd[ u1]);

            //return 1;
        }
         

       
    }


    //csak unió, ez jó!
    if (csum == 4)
    {
        float d = 10000000;

        for (int i = 0; i <4; i++)
        {
            d = min(cd[ i], d);
        }
        //return 0;

        // if (c[4] == 0 || c[5] == 0)
          //return 1;
        result = d;
    }


    // csak metszet (íves felület) ez jó!
    if (csum == 0)
    {
        float d = -10000000;

        for (int i = 0; i < 4; i++)
        {
            d = max(cd[ i], d);
        }


       
       //return 0;
        result = d;
    }
    
   //return csg2(uv, pos);

    
    return result;
}



float filter(float2 p)
{
    #if INTERP == 0
    return noInterp(p);
    #endif
    #if INTERP == 1
    return bilinear(p);
    #endif
    #if INTERP == 2
    return csg(p,true);
    #endif
    #if INTERP == 3
    return csg(p,false);
    #endif

    return 0.0f;
}


float debugplane(float2 pp,float2 p, int i)
{
    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (pp - 0.5) * boundingBox;
   
    
    //float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(0, 1), uv + float2(1, 1) };

    /*fps[0] = texture2[uv].xy;
    ns[0] = texture2[uv].zw;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].zw;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].zw;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].zw;
    
    float2 fp = fps[i].xy;
    float2 n = ns[i];*/

    return 0;
    //return sdLine(pos, fp, normalize(n)) < 0 ? 1 : 0;

   
}

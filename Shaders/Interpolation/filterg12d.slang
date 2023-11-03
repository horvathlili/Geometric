#ifndef INTERP
#define INTERP 0
#endif

static float2 fps[4];
static float2 ns[4];



float sdLine(float2 p, float2 fp, float2 n)
{

    
    return dot(p-fp, n);
    
}

float noInterp(float2 p)
{
    int2 uv = p * (res);

    float2 fp = texture2[uv].xy;
    float2 n = texture2[uv].zw;
   

    float2 pp = (p - 0.5) *boundingBox;

   
    if (length(n) > 10)
    {
       
        if (n.x == -10)
            return -length(pp - fp);
        return length(pp - fp);

       
    }

    return sdLine(pp, fp, normalize(n));
}


float csgDist(float2 pp, int uv)
{
    float2 fp = fps[uv].xy;
    float2 n = ns[uv].xy;
  
    return sdLine(pp, fp, normalize(n));    
}

float bilinear(float2 p)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv,0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);
    
    float2 fp, n;
    fp = texture2[uv].xy;
    n = normalize(texture2[uv].zw);
    float d1 = sdLine(pos, fp, n);
    fp = texture2[uv + float2(1, 0)].xy;
    n = normalize(texture2[uv + float2(1, 0)].zw);
    float d2 = sdLine(pos, fp, n);;
    fp = texture2[uv + float2(0, 1)].xy;
    n = normalize(texture2[uv + float2(0, 1)].zw);
    float d3 = sdLine(pos, fp, n);;
    fp = texture2[uv + float2(1, 1)].xy;
    n = normalize(texture2[uv + float2(1, 1)].zw);
    float d4 = sdLine(pos, fp, n);;

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
    ns[0] = texture2[uv].zw;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].zw;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].zw;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].zw;

   
   
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
        cd[i] = csgDist(pos, i);
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

        d1 = min(csgDist(pos, u1), csgDist(pos, u2));
        d2 = max(csgDist(pos, i1), csgDist(pos, i2));
               
        
        result = min(d1, d2);

        if (c[i1%2 + 4] == 0)
        {
            d1 = max(min(csgDist(pos, u1), csgDist(pos, i2)), csgDist(pos, i1));

            result = min(d1, csgDist(pos, u2));

          // return 1;
        }

        if (c[i2%2 + 4] == 0)
        {
            d1 = max(max(csgDist(pos, i1), csgDist(pos, u2)), csgDist(pos, i2));

            result = min(d1, csgDist(pos, u1));

            //return 1;
        }
         

       
    }


    //csak unió, ez jó!
    if (csum == 4)
    {
        float d = 10000000;

        for (int i = 0; i <4; i++)
        {
            d = min(csgDist(pos, i), d);
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
            d = max(csgDist(pos, i), d);
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

    fps[0] = texture2[uv].xy;
    ns[0] = texture2[uv].zw;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].zw;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].zw;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].zw;
    
    float2 fp = fps[i].xy;
    float2 n = ns[i];
  
    return sdLine(pos, fp, normalize(n)) < 0 ? 1 : 0;

   
}

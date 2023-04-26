#ifndef INTERP
#define INTERP 0
#endif

float sdLine(float2 p, float2 fp, float2 n)
{

    return dot(p - fp, n);
}

float noInterp(float2 p)
{
    int2 uv = p * (res);

    float2 fp = texture[uv].xy;
    float2 n = texture[uv].zw;

    float2 pp = (p - 0.5) * 2 * float2(4, 2.25);

    return sdLine(pp, fp, n);
}

float bilinear(float2 p)
{

    int2 uv = p * (res-1);
    float2 pos = (p - 0.5) * 2 * float2(4, 2.25);
    float2 ab = (p * (res - 1) - uv);
    
    float2 fp, n;
    fp = texture[uv].xy;
    n = texture[uv].zw;
    float d1 = sdLine(pos, fp, n);
    fp = texture[uv + float2(1, 0)].xy;
    n = texture[uv + float2(1, 0)].zw;
    float d2 = sdLine(pos, fp, n);
    fp = texture[uv + float2(0, 1)].xy;
    n = texture[uv + float2(0, 1)].zw;
    float d3 = sdLine(pos, fp, n);
    fp = texture[uv + float2(1, 1)].xy;
    n = texture[uv + float2(1, 1)].zw;
    float d4 = sdLine(pos, fp, n);

    float d11 = (1 - ab.x) * d1 + ab.x * d2;
    float d22 = (1 - ab.x) * d3 + ab.x * d4;

    
    return (1 - ab.y) * d11 + ab.y * d22;
}

float csg(float2 p)
{

    int2 uv = p * (res - 1);
    float2 pos = (p - 0.5) * 2 * float2(4, 2.25);
    float2 ab = (p * (res - 1) - uv);
    
    float2 fp[4];
    float2 n[4];
    fp[0] = texture[uv].xy;
    n[0] = texture[uv].zw;
    fp[1] = texture[uv + float2(1, 0)].xy;
    n[1] = texture[uv + float2(1, 0)].zw;
    fp[2] = texture[uv + float2(1, 1)].xy;
    n[2] = texture[uv + float2(1, 1)].zw;
    fp[3] = texture[uv + float2(0, 1)].xy;
    n[3] = texture[uv + float2(0, 1)].zw;

    float2 pp[4] = { float2(0, 0), float2(1, 0), float2(1, 1), float2(0, 1) };


//    return sdLine(pos, fp[2], n[2]);

    float result = 0;

    float c[4];
    
    for (int i = 0; i < 4; i++)
    {
        
        if (sdLine(fp[i], fp[(i + 1) % 4], n[(i + 1) % 4]) * sdLine(fp[(i + 1) % 4], fp[i], n[i]) >= 0)
        {
            if (sdLine(fp[i], fp[(i + 1) % 4], n[(i + 1) % 4]) < 0)
            {
                c[i] = 0;
            }
            else
            {

                if (sdLine(fp[i], fp[(i + 1) % 4], n[(i + 1) % 4]) == 0 || sdLine(fp[(i + 1) % 4], fp[i], n[i]) == 0)
                {
                    //return 0;
                    c[i] = 0;
                }
                else
                {
                        c[i] = 1;
                    
                }
            }
        }
        else
        {
            
            if (sdLine(fp[i], fp[(i + 1) % 4], n[(i + 1) % 4]) <= 0)
            {
                
                if (length(ab - pp[i]) < length(ab - pp[(i + 1) % 4]))
                {
                   
                    c[i] = 0;
                }
                else
                {
                    
                    c[i] = 1;
                }
            }
            else
            {
                if (length(ab - pp[i]) < length(ab - pp[(i + 1) % 4]))
                {
                    
                    c[i] = 1;
                }
                else
                {
                    //return 0;
                    c[i] = 0;
                }
            }
            c[i] = 0;
           
            
        }

    }
    
    int csum = c[0] + c[1] + c[2] + c[3];

    if (csum == 2)
    {
     
        float d = 10000;
          

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
                d = min(d, max(sdLine(pos, fp[i], n[i]), sdLine(pos, fp[(i + 1) % 4], n[(i + 1) % 4])));

            }
        }
        //return 0;
        result = d;
        
        
    }



    //EZ!!!!!!!
    //3 metszet 1 unió
    if (csum == 1)
    {
        float d1;
        float d2;

       
        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 1)
            {
                d1 = min(sdLine(pos, fp[i], n[i]), sdLine(pos, fp[(i + 1) % 4], n[(i + 1) % 4]));
                d2 = max(sdLine(pos, fp[(i + 2) % 4], n[(i + 2) % 4]), sdLine(pos, fp[(i + 3) % 4], n[(i + 3) % 4]));
               

            }
          
        }
        //return 0;
        result = max(d1, d2);

    }


    //3 unió, egy metszet
    if (csum == 3)
    {
        float d1;
        float d2;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
                d1 = max(sdLine(pos, fp[i], n[i]), sdLine(pos, fp[(i + 1) % 4], n[(i + 1) % 4]));
                d2 = min(sdLine(pos, fp[(i + 2) % 4], n[(i + 2) % 4]), sdLine(pos, fp[(i + 3) % 4], n[(i + 3) % 4]));
            }
        }
        //return 0;
        result = min(d1, d2);
    }


    //csak unió, ez jó!
    if (csum == 4)
    {
        float d = 10000000;

        for (int i = 0; i < 4; i++)
        {
            d = min(sdLine(pos, fp[i], n[i]), d);
        }
        //return 0;
        result = d;
    }


    // csak metszet (íves felület) ez jó!
    if (csum == 0)
    {
        float d = -10000000;

        for (int i = 0; i < 4; i++)
        {
            d = max(sdLine(pos, fp[i], n[i]), d);
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
    return csg(p);
    #endif

    return 0.0f;
}

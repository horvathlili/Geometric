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

    float2 fp = texture1[uv].xy;
    float2 n = texture1[uv].zw;
    //float2 n2 = texture2[uv].zw;

    float2 pp = (p - 0.5) * 2 * float2(4, 2.25);

    return sdLine(pp, fp, n);
}

float csgDist(float2 pp, int2 uv)
{
    float2 fp = texture1[uv].xy;
    float2 n = texture2[uv].xy;
    float2 n2 = texture2[uv].zw;

    bool union = false;
   
    if (length(n) > 1)
        union = true;

    //n = texture1[uv].zw;

    n = normalize(n);
   // return sdLine(pp, fp, n);

    if(!union)
        return max(sdLine(pp, fp, n), sdLine(pp, fp, n2));
    return min(sdLine(pp, fp, n), sdLine(pp, fp, n2));
    
}

float bilinear(float2 p)
{

    int2 uv = p * (res-1);
    float2 pos = (p - 0.5) * 2 * float2(4, 2.25);
    float2 ab = (p * (res - 1) - uv);
    
    float2 fp, n;
    fp = texture1[uv].xy;
    n = texture1[uv].zw;
    float d1 = sdLine(pos, fp, n);
    fp = texture1[uv + float2(1, 0)].xy;
    n = texture1[uv + float2(1, 0)].zw;
    float d2 = sdLine(pos, fp, n);;
    fp = texture1[uv + float2(0, 1)].xy;
    n = texture1[uv + float2(0, 1)].zw;
    float d3 = sdLine(pos, fp, n);;
    fp = texture1[uv + float2(1, 1)].xy;
    n = texture1[uv + float2(1, 1)].zw;
    float d4 = sdLine(pos, fp, n);;

    float d11 = (1 - ab.x) * d1 + ab.x * d2;
    float d22 = (1 - ab.x) * d3 + ab.x * d4;

    
    return (1 - ab.y) * d11 + ab.y * d22;
}



float csg(float2 p)
{

    int2 uv = p * (res -1);
    float2 pos = (p - 0.5) * 2 * float2(4, 2.25);
    float2 ab = (p * (res - 1) - uv);
    
    float2 fp[4];
    float2 n[4];
    float2 n2[4];
    float2 n1[4];
    fp[0] = texture1[uv].xy;
    n[0] = texture1[uv].zw;
    n1[0] = texture2[uv].xy;
    n2[0] = texture2[uv].zw;
    fp[1] = texture1[uv + float2(1, 0)].xy;
    n[1] = texture1[uv + float2(1, 0)].zw;
    n1[1] = texture2[uv + float2(1, 0)].xy;
    n2[1] = texture2[uv + float2(1, 0)].zw;
    fp[2] = texture1[uv + float2(1, 1)].xy;
    n[2] = texture1[uv + float2(1, 1)].zw;
    n1[2] = texture2[uv + float2(1, 1)].xy;
    n2[2] = texture2[uv + float2(1, 1)].zw;
    fp[3] = texture1[uv + float2(0, 1)].xy;
    n[3] = texture1[uv + float2(0, 1)].zw;
    n1[3] = texture2[uv + float2(0, 1)].xy;
    n2[3] = texture2[uv + float2(0, 1)].zw;

    float2 pp[4] = { float2(0, 0), float2(1, 0), float2(1, 1), float2(0, 1) };

    float2 uvs[4] = { uv+float2(0, 0),uv+ float2(1, 0),uv+ float2(1, 1),uv+ float2(0, 1) };

   // return csgDist(pos, uvs[0]);

    float result = 0;

    float c[4];
    
    for (int i = 0; i < 4; i++)
    {
        
        if (csgDist(fp[i], uvs[(i + 1) % 4]) * csgDist(fp[(i + 1) % 4], uvs[i]) >= 0)
        {
            if (csgDist(fp[i], uvs[(i + 1) % 4]) < 0)
            {
                c[i] = 0;
            }
            else
            {

                if (csgDist(fp[i], uvs[(i + 1) % 4]) == 0 || csgDist(fp[(i + 1) % 4], uvs[i]) == 0)
                {
                   
                    c[i] = 1;
                }
                else
                {
                    if ((dot(n1[i], n2[i]) < 0 || dot(n1[(i + 1) % 4], n2[(i + 1) % 4]) < 0) &&
                        (dot(n1[i], n2[i]) > 0 || dot(n1[(i + 1) % 4], n2[(i + 1) % 4]) > 0))
                    {
                        c[i] = 0;
                    }
                    else
                    {
                        c[i] = 1;
                    }
                }
            }
        }
        else
        {
            
            if (csgDist(fp[i], uvs[(i + 1) % 4]) <= 0)
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
            
        }
        
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
                d = min(d, max(csgDist(pos, uvs[i]), csgDist(pos, uvs[(i + 1) % 4])));
                if (c[(i + 1) % 4] == 0)
                {
                    a = true;
                    b = i;
                }
            }
        }
        //return 0;
        result = d;

        if (a)
        {
            int cc = -1;
            if (csgDist(fp[b], uvs[(b + 2) % 4]) * csgDist(fp[(b + 2) % 4], uvs[b]) >= 0)
            {
                if (csgDist(fp[b], uvs[(b + 2) % 4]) < 0)
                {
                    cc = 0;
                }
                else
                {

                    if (csgDist(fp[b], uvs[(b + 2) % 4]) == 0 || csgDist(fp[(b + 2) % 4], uvs[b]) == 0)
                    {
                   
                        cc = 1;
                    }
                    else
                    {
                        if ((dot(n1[b], n2[b]) < 0 || dot(n1[(b + 2) % 4], n2[(b + 2) % 4]) < 0) &&
                        (dot(n1[b], n2[b]) > 0 || dot(n1[(b + 2) % 4], n2[(b + 2) % 4]) > 0))
                        {
                            cc = 0;
                        }
                        else
                        {
                            cc = 1;
                        }
                    }
                }
            }
            else
            {
            
                if (csgDist(fp[b], uvs[(b + 2) % 4]) <= 0)
                {
                
                    if (length(ab - pp[b]) < length(ab - pp[(b + 2) % 4]))
                    {
                   
                        cc = 0;
                    }
                    else
                    {
                    
                        cc = 1;
                    }
                }
                else
                {
                    if (length(ab - pp[b]) < length(ab - pp[(b + 2) % 4]))
                    {
                    
                        cc = 1;
                    }
                    else
                    {
                    //return 0;
                        cc = 0;
                    }
                }
            
            }

            if (cc == 0)
            {
                result = max(max(csgDist(pos, uvs[b]), csgDist(pos, uvs[(b + 1) % 4])),csgDist(pos, uvs[(b + 2) % 4]));
                result = min(result, csgDist(pos, uvs[(b + 3) % 4]));

            }
            else
            {
                result = min(min(csgDist(pos, uvs[b]), csgDist(pos, uvs[(b + 3) % 4])), csgDist(pos, uvs[(b + 2) % 4]));
                result = max(result, csgDist(pos, uvs[(b + 1) % 4]));

            }
        }
        
        
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
                d1 = min(csgDist(pos, uvs[i]), csgDist(pos, uvs[(i + 1) % 4]));
                d2 = max(csgDist(pos, uvs[(i + 2) % 4]), csgDist(pos, uvs[(i + 3) % 4]));
               

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
                d1 = max(csgDist(pos, uvs[i]), csgDist(pos, uvs[(i + 1) % 4]));
                d2 = min(csgDist(pos, uvs[(i + 2) % 4]), csgDist(pos, uvs[(i + 3) % 4]));
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
            d = min(csgDist(pos, uvs[i]), d);
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
            d = max(csgDist(pos, uvs[i]), d);
        }

       //return 0;
        result = d;
    }
    
   //return csg2(uv, pos);

    
    return result;
}

float csg3(float2 p)
{
    int2 uv = p * (res - 1);
    float2 pos = (p - 0.5) * 2 * float2(4, 2.25);
    float2 ab = (p * (res - 1) - uv);
    
    float2 fp[4];
    float2 n[4];
    float2 n2[4];
    float2 n1[4];
    fp[0] = texture1[uv].xy;
    n[0] = texture1[uv].zw;
    n1[0] = texture2[uv].xy;
    n2[0] = texture2[uv].zw;
    fp[1] = texture1[uv + float2(1, 0)].xy;
    n[1] = texture1[uv + float2(1, 0)].zw;
    n1[1] = texture2[uv + float2(1, 0)].xy;
    n2[1] = texture2[uv + float2(1, 0)].zw;
    fp[2] = texture1[uv + float2(0, 1)].xy;
    n[2] = texture1[uv + float2(0, 1)].zw;
    n1[2] = texture2[uv + float2(0, 1)].xy;
    n2[2] = texture2[uv + float2(0, 1)].zw;
    fp[3] = texture1[uv + float2(1, 1)].xy;
    n[3] = texture1[uv + float2(1, 1)].zw;
    n1[3] = texture2[uv + float2(1, 1)].xy;
    n2[3] = texture2[uv + float2(1, 1)].zw;

    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(0, 1), uv + float2(1, 1) };


    if (length(ab) > length(float2(1, 1) - ab))
    {
        fp[0] = fp[3];
        n[0] = n[3];
        n1[0] = n1[3];
        n2[0] = n2[3];
        uvs[0] = uvs[3];
    }

    float c[3];
    
    for (int i = 0; i < 3; i++)
    {
        
        if (csgDist(fp[i], uvs[(i + 1) % 3]) * csgDist(fp[(i + 1) % 3], uvs[i]) >= 0)
        {
            if (csgDist(fp[i], uvs[(i + 1) % 3]) < 0)
            {
                c[i] = 0;
            }
            else
            {

                if (csgDist(fp[i], uvs[(i + 1) % 3]) == 0 || csgDist(fp[(i + 1) % 3], uvs[i]) == 0)
                {
                   
                    c[i] = 1;
                }
                else
                {
                    if ((dot(n1[i], n2[i]) < 0 || dot(n1[(i + 1) % 3], n2[(i + 1) % 3]) < 0) &&
                        (dot(n1[i], n2[i]) > 0 || dot(n1[(i + 1) % 3], n2[(i + 1) % 3]) > 0))
                    {
                        c[i] = 0;
                    }
                    else
                    {
                        c[i] = 1;
                    }
                }
            }
        }
        else
        {
            
            c[i] = 0;
            
        }
        
    }
    
    int csum = c[0] + c[1] + c[2];

    if (csum == 0)
    {
            float d = -1000000;
    
        for (int i = 0; i < 3; i++)
        {
            d = max(d, csgDist(pos, uvs[i]));
        }

        return d;
    }

    if (csum == 3)
    {
        float d = 1000000;
    
        for (int i = 0; i < 3; i++)
        {
            d = min(d, csgDist(pos, uvs[i]));
        }

        return d;
    }

    if (csum == 1)
    {

        float d;
        int ii;
        for (int i = 0; i < 3; i++){
            if (c[i] == 1)
            {
                d = min(csgDist(pos, uvs[i]), csgDist(pos, uvs[(i + 1)%3]));
                ii = i;
            }
        }

        d = max(d, csgDist(pos, uvs[(ii + 2) % 3]));
        return d;
    }

    if (csum == 2)
    {

        float d;
        int ii;
        for (int i = 0; i < 3; i++)
        {
            if (c[i] == 0)
            {
                d = max(csgDist(pos, uvs[i]), csgDist(pos, uvs[(i + 1) % 3]));
                ii = i;
            }
        }

        d = min(d, csgDist(pos, uvs[(ii + 2) % 3]));
        return d;
    }
    
    return 1;

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
    #if INTERP == 3
    return csg3(p);
    #endif

    return 0.0f;
}

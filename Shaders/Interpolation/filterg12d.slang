#ifndef INTERP
#define INTERP 0
#endif

float sdLine(float2 p, float2 fp, float2 n)
{

    float h = -dot(n, fp);
    return dot(p, n) + h;
    
}

float noInterp(float2 p)
{
    int2 uv = p * (res);

    float2 fp = texture1[uv].xy;
    float2 n = texture1[uv].zw;
    //float2 n2 = texture2[uv].zw;

    float2 pp = (p - 0.5) *boundingBox;
//    (p - 0.5) * 2 * float2(4, 2.25);

    //float2 t = float2(-5, -5) + (threadId.xy + 0.5) * 40 / (float2) res;
    //t *= float2(4, 2.25);

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
    //return sdLine(pp, fp, n);

    if (!union)
        return max(sdLine(pp, fp, n), sdLine(pp, fp, n2));
    return min(sdLine(pp, fp, n), sdLine(pp, fp, n2));
    
}

float bilinear(float2 p)
{

    int2 uv = p * (res-1);
    float2 pos = (p - 0.5) * boundingBox;
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

int csg2(float2 p, int c1, int c2)
{
    float2 fp[4],n[4];
    int2 uv = p * int2(res - 1);
    float2 pos = (p - 0.5) * boundingBox;
    
    fp[0] = texture1[uv].xy; 
    fp[1] = texture1[uv + float2(1, 0)].xy; 
    fp[2] = texture1[uv + float2(1, 1)].xy;
    fp[3] = texture1[uv + float2(0, 1)].xy;
    n[0] = texture1[uv].zw;
    n[1] = texture1[uv + float2(1, 0)].zw;
    n[2] = texture1[uv + float2(1, 1)].zw;
    n[3] = texture1[uv + float2(0, 1)].zw;
    
    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(1, 1), uv + float2(0, 1) };

    int cc = 0;

        //metszet kell
    if (csgDist(fp[c1], uvs[c2]) <= 0 && csgDist(fp[c2], uvs[c1]) <= 0)
    {
        cc = 0;

    }

        //unió kell
    if (csgDist(fp[c1], uvs[c2]) >= 0 && csgDist(fp[c2], uvs[c1]) >= 0)
    {
        cc = 1;
    }

        
    if (csgDist(fp[c1], uvs[c2]) * csgDist(fp[c2], uvs[c1]) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
            cc = 1;

       //blend!!
            

       // cc = 1;
            //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fp[c1], uvs[c2])) <= boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c2], uvs[c1]) > 0)
            {
                cc = 1;
            }
                //return 1;
        }

        if (abs(csgDist(fp[c2], uvs[c1])) < boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fp[c1], uvs[c2]) > 0)
            {
                cc = 1;
            }
        }

            //blend (itt most x mentén)

           
           
    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
    if (csgDist(fp[c1], uvs[c2]) == 0 && csgDist(fp[c2], uvs[c1]) == 0)
    {

            //return 1;

        cc = 1;
            
        if (length(n[c1]) > 1 && length(n[c2]) > 1)
        {
                
            cc = 1;
        }
        if (length(n[c1]) <= 1 && length(n[c2]) <= 1)
        {
                
            cc = 0;
        }

          

    }

    return cc;
 
}

float csg(float2 p)
{

    int2 uv = p * int2(res -1);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (p * float2(res - 1) - uv);
    
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

    float result = 0;

    float c[6],cd[4];
    
    for (int i = 0; i < 4; i++)
    {
        c[i] = csg2(p, i, (i + 1) % 4);
    }

    c[4] = csg2(p, 0, 2);
    c[5] = csg2(p, 1, 3);


    //debughoz
    /*if (c[0] == 0)
    {
        return max(csgDist(pos, uvs[0]), csgDist(pos, uvs[1]));

    }

    return min(csgDist(pos, uvs[0]), csgDist(pos, uvs[1]));*/

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
        //return 1;
        result = d;

       

        if (a)
        {

            
            int cc = c[b % 2 + 4];
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

            cc = c[b % 2 + 4];

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

        d1 = max(csgDist(pos, uvs[u1]), csgDist(pos, uvs[u2]));
        d2 = min(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2]));
               
        
        result = max(d1, d2);

        /*if (c[i1%2 + 4] == 1)
        {
            d1 = min(min(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2])), csgDist(pos, uvs[u1]));

            result = max(d1, csgDist(pos, uvs[u2]));

            return 1;
        }

        if (c[i2%2 + 4] == 1)
        {
            d1 = min(min(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2])), csgDist(pos, uvs[u2]));

            result = max(d1, csgDist(pos, uvs[u1]));

            return 1;
        }*/
         

       
    }


    //3 unió, egy metszet
    if (csum == 3)
    {
        
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

        d1 = min(csgDist(pos, uvs[u1]), csgDist(pos, uvs[u2]));
        d2 = max(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2]));
               
        
        result = min(d1, d2);

        if (c[i1%2 + 4] == 0)
        {
            d1 = max(max(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2])), csgDist(pos, uvs[u1]));

            result = min(d1, csgDist(pos, uvs[u2]));

            //return 1;
        }

        if (c[i2%2 + 4] == 0)
        {
            d1 = max(max(csgDist(pos, uvs[i1]), csgDist(pos, uvs[i2])), csgDist(pos, uvs[u2]));

            result = min(d1, csgDist(pos, uvs[u1]));

            //return 1;
        }
         

       
    }


    //csak unió, ez jó!
    if (csum == 4)
    {
        float d = 10000000;

        for (int i = 0; i <4; i++)
        {
            d = min(csgDist(pos, uvs[i]), d);
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
    float2 pos = (p - 0.5) * boundingBox;
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


    if (1-ab.x<ab.y)
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


float debugplane(float2 pp,float2 p, int i)
{
    int2 uv = p * int2(res - 1);
    float2 pos = (pp - 0.5) * boundingBox;
    
    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(0, 1), uv + float2(1, 1) };

    float2 fp = texture1[uvs[i]].xy;
    float2 n = texture2[uvs[i]].xy;
    float2 n2 = texture2[uvs[i]].zw;

    bool union = false;
   
    if (length(n) > 1)
        union = true;

    //n = texture1[uv].zw;

    n = normalize(n);
   //return sdLine(pos, fp, n) < 0 ? 1 : 0;

    if (!union)
        return max(sdLine(pos, fp, n), sdLine(pos, fp, n2)) < 0? 1:0;
    return min(sdLine(pos, fp, n), sdLine(pos, fp, n2))<0?1:0;
    
}

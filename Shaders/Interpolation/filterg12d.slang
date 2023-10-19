#ifndef INTERP
#define INTERP 0
#endif

static float2 fps[4];
static float2 ns[4];



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

    if (length(n) > 10)
    {
       
        if (n.x == -10)
            return -length(pp - fp);
        return length(pp - fp);

       
    }

    //float2 t = float2(-5, -5) + (threadId.xy + 0.5) * 40 / (float2) res;
    //t *= float2(4, 2.25);

    return sdLine(pp, fp, n);
}


float csgDist(float2 pp, int uv)
{
    float2 fp = fps[uv].xy;
    float2 n = ns[uv].xy;

    if (length(n) > 10)
    {
       
        if (n.x == -10)
            return -length(pp - fp);
        return length(pp - fp);

       
    }
  
    return sdLine(pp, fp, normalize(n));

    
    
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
    
    int2 uv = p * int2(res - 1);
    float2 pos = (p - 0.5) * boundingBox;

    
    
    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(1, 1), uv + float2(0, 1) };

    int cc = 0;


    
        //unió kell
    if (csgDist(fps[c1], c2) > 0 && csgDist(fps[c2], c1) > 0)
    {
        cc = 1;
    }

        
    if (csgDist(fps[c1], c2) * csgDist(fps[c2], c1) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
            cc = 1;

         //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fps[c1], c2)) <= boundingBox / (float) (res - 1) * 0.1)
        {
            cc = 0;
                //return 1;
        }

        if (abs(csgDist(fps[c2], c1)) < boundingBox / (float) (res - 1) * 0.1)
        {
            cc = 0;
          
        }

            
        //cc = 0;
           
           
    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
   if (csgDist(fps[c1], c2) == 0 && csgDist(c2, c1) == 0)
    {

            //return 1;

        cc = 1;
            
        /*if (length(n[c1]) > 1 && length(n[c2]) > 1)
        {
                
            cc = 1;
        }
        if (length(n[c1]) <= 1 && length(n[c2]) <= 1)
        {
                
            cc = 0;
        }*/

        cc = 0;

    }

   





    //vmelyik csúcs

    
    
   
    
        if (length(ns[c1]) > 4 || length(ns[c2]) > 4)
        {

        

            if (length(ns[c2]) > 4)
            {
                cc = 0;
                if (csgDist(fps[c2], c1) >= 0) // a pont a félsíkon kívül van
                {
                    cc = 1;
                }

            //a pont kb a félsíkon van
                if (abs(csgDist(fps[c2], c1)) < boundingBox / (float) (res - 1) * 0.01)
                {


                  
                if (ns[c2].x <= 0)
                {
                    cc = 0;
                    

                }
                else
                {
                    cc = 1;
                    
                }

                }

       
            }

            if (length(ns[c1]) > 4)
            {
                cc = 0;
                if (csgDist(fps[c1], c2) >= 0) // a pont a félsíkon kívül van
                {
                    cc = 1;
                }

            //a pont kb a félsíkon van
                if (abs(csgDist(fps[c1], c2)) < boundingBox / (float) (res - 1) * 0.01)
                {

                   
                
                if (ns[c1].x <= 0)
                {
                    cc = 0;
                    /*if (csgDist(pos, c2) > 0)
                    {
                        cc = 0;
                            ns[c1] *= -1;
                     }*/
                }
                else
                {
                    cc = 1;
                    /*if (csgDist(pos, c2) <= 0)
                    {
                        cc = 1;
                            ns[c1] *= -1;
                        }*/
                }
                
                }
    
       
            }
        
       
        
        }
   if (length(ns[c1]) > 4 && length(ns[c2]) > 4)
    {
        cc = 1;
    }
   
   
    

    


    return cc;
 
}

int csg2nopoint(float2 p, int c1, int c2)
{
    
    int2 uv = p * int2(res - 1);
    float2 pos = (p - 0.5) * boundingBox;

   

    
    
    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(1, 1), uv + float2(0, 1) };

    int cc = 0;


   
        //metszet kell
    if (csgDist(fps[c1], c2) <= 0 && csgDist(fps[c2], c1) <= 0)
    {
        cc = 0;

    }

        //unió kell
    if (csgDist(fps[c1], c2) >= 0 && csgDist(fps[c2], c1) >= 0)
    {
        cc = 1;
    }

        
    if (csgDist(fps[c1], c2) * csgDist(fps[c2], c1) < 0)
    {

            
            //itt kell majd interpolálni és lehetnek pontatlanságok           
            
            //amúgy legyen unió egyelőre
        cc = 1;

         //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fps[c1], c2)) <= boundingBox / (float) (res - 1) * 0.1)
        {

            cc = 0;

            //belső sarok
            if (length(ns[c1]) > 1 || length(ns[c2]) > 1)
            {
                
                cc = 1;
            }
         
        }

        if (abs(csgDist(fps[c2], c1)) < boundingBox / (float) (res - 1) * 0.1)
        {

            cc = 0;
            if (length(ns[c1]) > 1 || length(ns[c2]) > 1)
            {
                
                cc = 1;
            }
          
          
        }

              //pontatlanságok - az egyik majdnem rajta van a másikon
        if (abs(csgDist(fps[c1], c2)) <= boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fps[c2], c1) > 0)
            {
                cc = 1;
            }
                //return 1;
        }

        if (abs(csgDist(fps[c2], c1)) < boundingBox / (float) (res - 1) * 0.01)
        {
            cc = 0;
            if (csgDist(fps[c1], c2) > 0)
            {
                cc = 1;
            }
        }

            
        //cc = 1;
           
           
    }

        //mindkettő 0 -> belső vagy külső sarok??? - ezt előre kéne tárolni valahogy
    if (abs(csgDist(fps[c1], c2)) < 0.0001 && abs(csgDist(fps[c2], c1)) < 0.0001)
    {

            //return 1;

        cc = 1;
            
        
        if (length(ns[c1]) > 1 || length(ns[c2]) > 1)
        {
                
            cc = 1;
        }
        if (length(ns[c1]) <= 1.0001 && length(ns[c2]) <= 1.0001)
        {
                
            cc = 0;
        }

        

    }

   




    //vmelyik csúcs

    
    
   
    
  
   
   
    

    


    return cc;
 
}

float csg(float2 p,bool points)
{

    int2 uv = p * int2(res -1);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (p * float2(res - 1) - uv);

    if (points)
    {
        fps[0] = texture1[uv].xy;
        ns[0] = texture1[uv].zw;
   
        fps[1] = texture1[uv + float2(1, 0)].xy;
        ns[1] = texture1[uv + float2(1, 0)].zw;
   
        fps[2] = texture1[uv + float2(1, 1)].xy;
        ns[2] = texture1[uv + float2(1, 1)].zw;
   
        fps[3] = texture1[uv + float2(0, 1)].xy;
        ns[3] = texture1[uv + float2(0, 1)].zw;
    }
    else //csak félsíkok (csúcsokban lehet hibás)
    {
        fps[0] = texture2[uv].xy;
        ns[0] = texture2[uv].zw;
   
        fps[1] = texture2[uv + float2(1, 0)].xy;
        ns[1] = texture2[uv + float2(1, 0)].zw;
   
        fps[2] = texture2[uv + float2(1, 1)].xy;
        ns[2] = texture2[uv + float2(1, 1)].zw;
   
        fps[3] = texture2[uv + float2(0, 1)].xy;
        ns[3] = texture2[uv + float2(0, 1)].zw;
    }
   
    float2 pp[4] = { float2(0, 0), float2(1, 0), float2(1, 1), float2(0, 1) };

    float2 uvs[4] = { uv+float2(0, 0),uv+ float2(1, 0),uv+ float2(1, 1),uv+ float2(0, 1) };

    float result = 0;

    float c[6],cd[4];
    
    for (int i = 0; i < 4; i++)
    {
        if (points)
        {
            c[i] = csg2(p, i, (i + 1) % 4);
        }
        else
        {
            c[i] = csg2nopoint(p, i, (i + 1) % 4);

        }
    }

   
    if (points)
    {
        c[4] = csg2(p, 0, 2);
   
        c[5] = csg2(p, 1, 3);
    }
    else
    {
        c[4] = csg2nopoint(p, 0, 2);
   
        c[5] = csg2nopoint(p, 1, 3);

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
                d = min(d, max(csgDist(pos, i), csgDist(pos, (i + 1) % 4)));
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
                result = max(max(csgDist(pos, b), csgDist(pos, (b + 1) % 4)),csgDist(pos, (b + 2) % 4));
                result = min(result, csgDist(pos, (b + 3) % 4));

            }
            else
            {
                result = min(min(csgDist(pos, b), csgDist(pos, (b + 3) % 4)), csgDist(pos, (b + 2) % 4));
                result = max(result, csgDist(pos, (b + 1) % 4));

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

        d1 = max(csgDist(pos, u1), csgDist(pos, u2));
        d2 = min(csgDist(pos, i1), csgDist(pos, i2));
               
        
        result = max(d1, d2);         

       
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

        d1 = min(csgDist(pos, u1), csgDist(pos, u2));
        d2 = max(csgDist(pos, i1), csgDist(pos, i2));
               
        
        result = min(d1, d2);

        if (c[i1%2 + 4] == 0)
        {
            d1 = max(max(csgDist(pos, i1), csgDist(pos, i2)), csgDist(pos, u1));

            result = min(d1, csgDist(pos, u2));

            //return 1;
        }

        if (c[i2%2 + 4] == 0)
        {
            d1 = max(max(csgDist(pos, i1), csgDist(pos, i2)), csgDist(pos, u2));

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
    int2 uv = p * int2(res - 1);
    float2 pos = (pp - 0.5) * boundingBox;

    fps[0] = texture1[uv].xy;
    ns[0] = texture1[uv].zw;
   
    fps[1] = texture1[uv + float2(1, 0)].xy;
    ns[1] = texture1[uv + float2(1, 0)].zw;
   
    fps[2] = texture1[uv + float2(1, 1)].xy;
    ns[2] = texture1[uv + float2(1, 1)].zw;
   
    fps[3] = texture1[uv + float2(0, 1)].xy;
    ns[3] = texture1[uv + float2(0, 1)].zw;
    
    //float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(0, 1), uv + float2(1, 1) };

   
    
    float2 fp = fps[i].xy;
    float2 n = ns[i];

    if (length(n) > 4)
        return 0;
  
    return sdLine(pos, fp, normalize(n)) < 0 ? 1 : 0;

   
}

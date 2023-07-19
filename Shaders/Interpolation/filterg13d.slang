#ifndef INTERP
#define INTERP 0
#endif

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdPlane(float3 p, float3 n, float3 x)
{
  // n must be normalized
    float h = -dot(n, x);
    return dot(p, n) + h;
}

float sdCircle(float3 p, float3 n, float3 x, float r)
{

    float dd = dot(p - x, n);

    float s = dd < 0 ? -1 : 1;

    float3 c = p - dd * n;
    if (length(c - x) > r)
    {
        c = x + normalize(c - x) * r;
        return length(p - c);

    }
    return s * length(p - c);
    
}

float noInterp(float3 pos)
{
    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res);

    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float sr = boundingBox / (float) res * 2.0f;


    return sdCircle(pos, t2.xyz, t1.xyz,sr);
    
    return max(sdSphere(pos - t1.xyz, sr), sdPlane(pos, t2.xyz, t1.xyz));
}

float4 debug(float3 pos,float3 debugpos)
{
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res);

    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float sr = boundingBox / (float) res * 2.0f;
   
    return float4(t1.xyz, sdPlane(pos, t2.xyz, t1.xyz));
}

float getTexture(float3 uvw, float3 pos)
{
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float sr = boundingBox / (float) res * 2.0f;

    return sdCircle(pos, t2.xyz, t1.xyz, sr);
    return max(sdSphere(pos - t1.xyz, sr), sdPlane(pos, t2.xyz, t1.xyz));
}

float trilinear( float3 pos)
{
    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * float3(res - 1);
    
    float d000 = getTexture(uvw, pos);
    float d100 = getTexture(uvw + float3(1, 0, 0), pos);
    float d010 = getTexture(uvw + float3(0, 1, 0), pos);
    float d001 = getTexture(uvw + float3(0, 0, 1), pos);
    float d110 = getTexture(uvw + float3(1, 1, 0), pos);
    float d101 = getTexture(uvw + float3(1, 0, 1), pos);
    float d011 = getTexture(uvw + float3(0, 1, 1), pos);
    float d111 = getTexture(uvw + float3(1, 1, 1), pos);

    float a1 = uvw.x - (int) uvw.x;
    float ha1 = 6 * pow(a1, 5) - 15 * pow(a1, 4) + 10 * pow(a1, 3);
  
    float d00 = d000 * (1 - ha1) + d100 * ha1;
    float d01 = d001 * (1 - ha1) + d101 * ha1;
    float d10 = d010 * (1 - ha1) + d110 * ha1;
    float d11 = d011 * (1 - ha1) + d111 * ha1;
  

    float a2 = uvw.y - (int) uvw.y;
    float ha2 = 6 * pow(a2, 5) - 15 * pow(a2, 4) + 10 * pow(a2, 3);
    float d0 = d00 * (1 - ha2) + d10 * ha2;
    float d1 = d01 * (1 - ha2) + d11 * ha2;
   

    float a3 = uvw.z - (int) uvw.z;
    float ha3 = 6 * pow(a3, 5) - 15 * pow(a3, 4) + 10 * pow(a3, 3);
    return  (d0 * (1 - ha3) + d1 * ha3);

    return 0;

}




float getcsg(float c[4], float3 fp[4], float3 n[4], float3 pos)
{
    int csum = c[0] + c[1] + c[2] + c[3];
    float result = 0;

    float e = boundingBox / (float) res * 2.0f;
    
    if (csum == 2)
    {
     
        float d = 10000;
          

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 0)
            {
                d = min(d, max(max(sdSphere(pos - fp[i], e), sdPlane(pos, n[i], fp[i])), max(sdSphere(pos - fp[(i + 1) % 4], e), sdPlane(pos, n[(i + 1) % 4], fp[(i + 1) % 4]))));

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
                d1 = min(max(sdSphere(pos - fp[i], e), sdPlane(pos, n[i], fp[i])), max(sdSphere(pos - fp[(i + 1) % 4], e), sdPlane(pos, n[(i + 1) % 4], fp[(i + 1) % 4])));
                d2 = max(max(sdSphere(pos - fp[(i + 2) % 4], e), sdPlane(pos, n[(i + 2) % 4], fp[(i + 2) % 4])), max(sdSphere(pos - fp[(i + 3) % 4], e), sdPlane(pos, n[(i + 3) % 4], fp[(i + 3) % 4])));
               

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
                d1 = max(max(sdSphere(pos - fp[i], e), sdPlane(pos, n[i], fp[i])), max(sdSphere(pos - fp[(i + 1) % 4], e), sdPlane(pos, n[(i + 1) % 4], fp[(i + 1) % 4])));
                d2 = min(max(sdSphere(pos - fp[(i + 2) % 4], e), sdPlane(pos, n[(i + 2) % 4], fp[(i + 2) % 4])), max(sdSphere(pos - fp[(i + 3) % 4], e), sdPlane(pos, n[(i + 3) % 4], fp[(i + 3) % 4])));
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
            d = min(max(sdSphere(pos - fp[i], e), sdPlane(pos, n[i], fp[i])), d);
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
            d = max(max(sdSphere(pos - fp[i], e), sdPlane(pos, n[i], fp[i])), d);
        }

       //return 0;
        result = d;
    }

    return result;
}

float csg( float3 pos)
{

    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * float3(res - 1, res - 1, res - 1);
        
    float3 fp[4];
    float3 n[4];
    fp[0] = texture1[uvw].xyz;
    n[0] = texture2[uvw].xyz;
    fp[1] = texture1[uvw + float3(1, 0, 0)].xyz;
    n[1] = texture2[uvw + float3(1, 0, 0)].xyz;
    fp[2] = texture1[uvw + float3(1, 0, 1)].xyz;
    n[2] = texture2[uvw + float3(1, 0, 1)].xyz;
    fp[3] = texture1[uvw + float3(0, 0, 1)].xyz;
    n[3] = texture2[uvw + float3(0, 0, 1)].xyz;

    float3 fp2[4];
    float3 n2[4];
    fp2[0] = texture1[uvw + float3(0, 1, 0)].xyz;
    n2[0] = texture2[uvw + float3(0, 1, 0)].xyz;
    fp2[1] = texture1[uvw + float3(1, 1, 0)].xyz;
    n2[1] = texture2[uvw + float3(1, 1, 0)].xyz;
    fp2[2] = texture1[uvw + float3(1, 1, 1)].xyz;
    n2[2] = texture2[uvw + float3(1, 1, 1)].xyz;
    fp2[3] = texture1[uvw + float3(0, 1, 1)].xyz;
    n2[3] = texture2[uvw + float3(0, 1, 1)].xyz;

    float e = boundingBox / (float) res * 2.0f;

//    return sdLine(pos, fp[2], n[2]);

    float result1 = 0;
    float result2 = 0;

    float c[4];
    float c2[4];
    float c3[4];
    
    for (int i = 0; i < 4; i++)
    {
        
     
        if (sdPlane(fp[i], n[(i + 1) % 4], fp[(i + 1) % 4]) <= 0)
        {
            c[i] = 0;
        }
        else
        {

            if (sdPlane(fp[i], n[(i + 1) % 4], fp[(i + 1) % 4]) == 0)
            {
                   
                if (dot(n[i], n[(i + 1) % 4]) > 0)
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
                c[i] = 1;
            }
        }

        if (sdPlane(fp2[i], n2[(i + 1) % 4], fp2[(i + 1) % 4]) <= 0)
        {
            c2[i] = 0;
        }
        else
        {

            if (sdPlane(fp2[i], n2[(i + 1) % 4], fp2[(i + 1) % 4]) == 0)
            {
                   
                if (dot(n2[i], n2[(i + 1) % 4]) > 0)
                {
                    c2[i] = 0;
                }
                else
                {
                    c2[i] = 1;
                }
                    
            }
            else
            {
                c2[i] = 1;
            }
        }
        if (sdPlane(fp[i], n2[i], fp2[i]) <= 0)
        {
            c3[i] = 0;
        }
        else
        {

            if (sdPlane(fp[i], n2[i], fp2[i]) == 0)
            {
                   
                if (dot(n[i], n2[i]) > 0)
                {
                    c3[i] = 0;
                }
                else
                {
                    c3[i] = 1;
                }
                    
            }
            else
            {
                c3[i] = 1;
            }
        }
         

    }
    
    
    
    //return result1;
    int csum1 = c[0] + c[2] + c2[0] + c2[2];
    int csum2 = c[1] + c[3] + c2[1] + c2[3];
    int csum3 = c3[0] + c3[1] + c3[2] + c3[3];

    int cc = -1;

    

    //van egy tengely
    if (csum3 == 4 || cc == 3)
    {
        
        result1 = getcsg(c, fp, n, pos);
    
        result2 = getcsg(c, fp2, n2, pos);
        return min(result1, result2);
    }
    if (csum1 == 4 || cc == 1)
    {
        float3 fpp1[4];
        fpp1[0] = fp[0];
        fpp1[1] = fp[3];
        fpp1[2] = fp2[0];
        fpp1[3] = fp2[3];

        float3 fpp2[4];
        fpp2[0] = fp[1];
        fpp2[1] = fp[2];
        fpp2[2] = fp2[1];
        fpp2[3] = fp2[2];
        float3 np1[4];
        np1[0] = n[0];
        np1[1] = n[3];
        np1[2] = n2[0];
        np1[3] = n2[3];

        float3 np2[4];
        np2[0] = n[1];
        np2[1] = n[2];
        np2[2] = n2[1];
        np2[3] = n2[2];

        float cp1[4];
        cp1[0] = c[3];
        cp1[1] = c3[3];
        cp1[2] = c2[3];
        cp1[3] = c3[0];
        float cp2[4];
        cp2[0] = c[1];
        cp2[1] = c3[2];
        cp2[2] = c2[1];
        cp2[3] = c3[1];

        result1 = getcsg(cp1, fpp1, np1, pos);
    
        result2 = getcsg(cp2, fpp2, np2, pos);
        return min(result1, result2);
    }
    if (csum2 == 4 || cc == 2)
    {
        float3 fpp1[4];
        fpp1[0] = fp[0];
        fpp1[1] = fp[1];
        fpp1[2] = fp2[1];
        fpp1[3] = fp2[0];

        float3 fpp2[4];
        fpp2[0] = fp[3];
        fpp2[1] = fp[2];
        fpp2[2] = fp2[2];
        fpp2[3] = fp2[3];
        float3 np1[4];
        np1[0] = n[0];
        np1[1] = n[1];
        np1[2] = n2[1];
        np1[3] = n2[0];

        float3 np2[4];
        np2[0] = n[3];
        np2[1] = n[2];
        np2[2] = n2[2];
        np2[3] = n2[3];

        float cp1[4];
        cp1[0] = c[0];
        cp1[1] = c3[1];
        cp1[2] = c2[0];
        cp1[3] = c3[0];
        float cp2[4];
        cp2[0] = c[2];
        cp2[1] = c3[2];
        cp2[2] = c2[2];
        cp2[3] = c3[3];

        result1 = getcsg(cp1, fpp1, np1, pos);
    
        result2 = getcsg(cp2, fpp2, np2, pos);
        return min(result1, result2);
    }

    if (csum3 == 0 || cc == 3)
    {
        
        result1 = getcsg(c, fp, n, pos);
    
        result2 = getcsg(c, fp2, n2, pos);
        return max(result1, result2);
       

    }
    if (csum1 == 0 || cc == 1)
    {
        float3 fpp1[4];
        fpp1[0] = fp[0];
        fpp1[1] = fp[3];
        fpp1[2] = fp2[0];
        fpp1[3] = fp2[3];

        float3 fpp2[4];
        fpp2[0] = fp[1];
        fpp2[1] = fp[2];
        fpp2[2] = fp2[1];
        fpp2[3] = fp2[2];
        float3 np1[4];
        np1[0] = n[0];
        np1[1] = n[3];
        np1[2] = n2[0];
        np1[3] = n2[3];

        float3 np2[4];
        np2[0] = n[1];
        np2[1] = n[2];
        np2[2] = n2[1];
        np2[3] = n2[2];

        float cp1[4];
        cp1[0] = c[3];
        cp1[1] = c3[3];
        cp1[2] = c2[3];
        cp1[3] = c3[0];
        float cp2[4];
        cp2[0] = c[1];
        cp2[1] = c3[2];
        cp2[2] = c2[1];
        cp2[3] = c3[1];

        result1 = getcsg(cp1, fpp1, np1, pos);
    
        result2 = getcsg(cp2, fpp2, np2, pos);
        return max(result1, result2);
        
    }
    if (csum2 == 0 || cc == 2)
    {
        float3 fpp1[4];
        fpp1[0] = fp[0];
        fpp1[1] = fp[1];
        fpp1[2] = fp2[1];
        fpp1[3] = fp2[0];

        float3 fpp2[4];
        fpp2[0] = fp[3];
        fpp2[1] = fp[2];
        fpp2[2] = fp2[2];
        fpp2[3] = fp2[3];
        float3 np1[4];
        np1[0] = n[0];
        np1[1] = n[1];
        np1[2] = n2[1];
        np1[3] = n2[0];

        float3 np2[4];
        np2[0] = n[3];
        np2[1] = n[2];
        np2[2] = n2[2];
        np2[3] = n2[3];

        float cp1[4];
        cp1[0] = c[0];
        cp1[1] = c3[1];
        cp1[2] = c2[0];
        cp1[3] = c3[0];
        float cp2[4];
        cp2[0] = c[2];
        cp2[1] = c3[2];
        cp2[2] = c2[2];
        cp2[3] = c3[3];

        result1 = getcsg(cp1, fpp1, np1, pos);
    
        result2 = getcsg(cp2, fpp2, np2, pos);
        return max(result1, result2);
    }

   

    result1 = getcsg(c, fp, n, pos);
    
    result2 = getcsg(c, fp2, n2, pos);

    if (csum3 <= 2)
    {
        return max(result1, result2);
    }
    else
    {
        return min(result1, result2);
    }

}

float filter(float3 p)
{
    #if INTERP == 0
    return noInterp(p);
    #endif
    #if INTERP == 1
    return trilinear(p);
    #endif
    #if INTERP == 2
    return csg(p);
    #endif

    return 0.0f;
}


float getDifference(float3 p1, float3 p2,)
{
    return filter(p1) - filter(p2);
}

float3 getNormal_filter(float3 pos)
{
    float e = 0.00001;
    float3 n;

    {
        float3 p1 = pos + float3(e, 0, 0);
        float3 p2 = pos - float3(e, 0, 0);

        n.x = getDifference(p1, p2);
    }
    {
        float3 p1 = pos + float3(0, e, 0);
       
        float3 p2 = pos - float3(0, e, 0);
   
        n.y = getDifference(p1, p2);
    }
    {
    
        float3 p1 = pos + float3(0, 0, e);
     
        float3 p2 = pos - float3(0, 0, e);
      
        n.z = getDifference(p1, p2);
    }
    return n;
}

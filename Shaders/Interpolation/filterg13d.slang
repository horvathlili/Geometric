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

    float dd = sdPlane(p, n, x);

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

    //return t1.r * pos.x + t1.g * pos.y + t1.b * pos.z + t1.a;


    float sr = boundingBox / (float) res * 2.0f;

    return sdCircle(pos, t2.xyz, t1.xyz,sr);
   //return sdPlane(pos, normalize(t2.xyz), t1.xyz);
   // return max(sdSphere(pos - t1.xyz,sr), sdPlane(pos, t2.xyz, t1.xyz));
}

float4 debug(float3 pos,float3 debugpos)
{
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res);

    uvw = clamp(uvw, 0, res - 1);

    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float sr = boundingBox / (float) res * 2.0f;

    float d = sdPlane(pos, t2.xyz, t1.xyz);

   /* if (d < 0.0001)
    {
        d = abs(d) - 0.0001;

    }*/
   
    return float4(t1.xyz, d);
}

float getTexture(float3 uvw, float3 pos)
{
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];


    //return t1.r * pos.x + t1.g * pos.y + t1.b * pos.z + t1.a;

    float sr = boundingBox / (float) res * 2.0f;

   return sdCircle(pos, t2.xyz, t1.xyz, sr);
    return max(sdSphere(pos - t1.xyz, sr), sdPlane(pos, t2.xyz, t1.xyz));
}



float trilinear( float3 pos)
{
    float3 pp = ((pos) / float3(boundingBox) + 0.5);
    
    float3 fuvw = clamp(pp * (float(res)) - 0.5, 0, float(res) - 1);
    int3 uvw = clamp(fuvw, 0, res - 2);
   
    
    float d000 = getTexture(uvw, pos);
    float d100 = getTexture(uvw + float3(1, 0, 0), pos);
    float d010 = getTexture(uvw + float3(0, 1, 0), pos);
    float d001 = getTexture(uvw + float3(0, 0, 1), pos);
    float d110 = getTexture(uvw + float3(1, 1, 0), pos);
    float d101 = getTexture(uvw + float3(1, 0, 1), pos);
    float d011 = getTexture(uvw + float3(0, 1, 1), pos);
    float d111 = getTexture(uvw + float3(1, 1, 1), pos);

    float a1 = fuvw.x - uvw.x;
    float ha1 = 6 * pow(a1, 5) - 15 * pow(a1, 4) + 10 * pow(a1, 3);
   ha1 = -2 * pow(a1, 3) + 3 * pow(a1, 2);
    ha1 = a1;
  
    float d00 = d000 * (1 - ha1) + d100 * ha1;
    float d01 = d001 * (1 - ha1) + d101 * ha1;
    float d10 = d010 * (1 - ha1) + d110 * ha1;
    float d11 = d011 * (1 - ha1) + d111 * ha1;
  

    float a2 = fuvw.y -  uvw.y;
    float ha2 = 6 * pow(a2, 5) - 15 * pow(a2, 4) + 10 * pow(a2, 3);
    ha2 = -2 * pow(a2, 3) + 3 * pow(a2, 2);

    ha2 = a2;
    float d0 = d00 * (1 - ha2) + d10 * ha2;
    float d1 = d01 * (1 - ha2) + d11 * ha2;
   

    float a3 = fuvw.z - uvw.z;
    float ha3 = 6 * pow(a3, 5) - 15 * pow(a3, 4) + 10 * pow(a3, 3);
    ha3 = -2 * pow(a3, 3) + 3 * pow(a3, 2);
    ha3 = a3;
    return  (d0 * (1 - ha3) + d1 * ha3);

    return 0;

}


float opSmoothIntersection
    (
    float d1, float d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2 - d1) / k, 0.0, 1.0);
   // return lerp(d2, d1, h) + k * h * (1.0 - h);

    return max(d1, d2);
}

float opSmoothUnion
    (
    float d1, float d2, float k)
{
    return min(d1, d2);
    return -opSmoothIntersection(-d1, -d2, k);
}



int4 tetrav(float3 p)
{
 
    if (p.y <= p.z && p.z <= p.x)
    {
         return int4(0, 1, 2, 6);
    }
    if (p.z < p.y  && p.y<= p.x)
    {
         return int4(0, 1, 5, 6);
    }
    if (p.z <= p.x && p.x <=p.y)
    {
       return int4(0, 4, 5, 6);

    }
    if (p.y <= p.x && p.x<= p.z)
    {
       
        return int4(0, 2, 3, 6);
    }
    if (p.x <= p.y && p.y<= p.z)
    {
       
        return int4(0,3,7,6);
    }
    if (p.x <= p.z && p.z<= p.y)
    {
       
        return int4(0, 4, 7, 6);
    }

    return int4(0,0,0,0);
}

float csg2(float3 p)
{
    float3 p1 = ((p) / float3(boundingBox) + 0.5);
    
    float3 fuvw = clamp(p1 * (float(res)) - 0.5, 0, float(res) - 1);
    int3 uvw = clamp(fuvw, 0, res - 2);
   
    float3 pp[8];

    pp[0] = float3(0, 0, 0);
    pp[1] = float3(1, 0, 0);
    pp[2] = float3(1, 0, 1);
    pp[3] = float3(0, 0, 1);
    pp[4] = float3(0, 1, 0);
    pp[5] = float3(1, 1, 0);
    pp[6] = float3(1, 1, 1);
    pp[7] = float3(0, 1, 1);

    int4 ix = tetrav(fuvw - int3(uvw));    
    
    float3 fp[4];
    float3 n[4],n2[4];
    float conv[4];
    fp[0] = texture1[uvw + pp[ix.r]].xyz;
    n[0] = texture2[uvw + pp[ix.r]].xyz;
    n2[0] = texture2[uvw + pp[ix.r]].xyz;
    conv[0] = texture1[uvw + pp[ix.r]].w;
    fp[1] = texture1[uvw + pp[ix.g]].xyz;
    n[1] = texture2[uvw + pp[ix.g]].xyz;
    n2[1] = texture2[uvw + pp[ix.g]].xyz;
    conv[1] = texture1[uvw + pp[ix.g]].w;
    fp[2] = texture1[uvw + pp[ix.b]].xyz;
    n[2] = texture2[uvw + pp[ix.b]].xyz;
    n2[2] = texture2[uvw + pp[ix.b]].xyz;
    conv[2] = texture1[uvw + pp[ix.b]].w;
    fp[3] = texture1[uvw + pp[ix.a]].xyz;
    n[3] = texture2[uvw + pp[ix.a]].xyz;
    n2[3] = texture2[uvw + pp[ix.a]].xyz;
    conv[3] = texture1[uvw + pp[ix.a]].w;
    
    float d[4];

    float e = boundingBox / (float) res ;

    float k = 0.005;
    k = 0;
    float sr = boundingBox / (float) res * 2.0f ;
    
    for (int i = 0; i < 4; i++)
    {
        //d[i] = max(sdSphere(p - fp[i], sr), sdPlane(p, n[i], fp[i]));
        d[i] = sdCircle(p, n[i], fp[i], sr);
    }

    int cc[4][4];
    int c[4] = { 0, 0, 0, 0 };
    int csum = 0;
   

    for (int j = 0; j < 4; j++)
    {

        cc[j][j] = 0;
        for (int k = j + 1; k < 4; k++)
        {

            cc[j][k] = -1;
            cc[k][j] = -1;
            if (sdPlane(fp[j], n[k], fp[k]) <= 0 && sdPlane(fp[k], n[j], fp[j]) <= 0)
            {
                cc[j][k] = 0;
                cc[k][j] = 0;
            }

            if (sdPlane(fp[j], n[k], fp[k]) > 0 && sdPlane(fp[k], n[j], fp[j]) > 0)
            {
                cc[j][k] = 1;
                c[j]++;
                cc[k][j] = 1;
                c[k]++;
                csum++;
            }
            
            

            if (cc[j][k] == -1)
            {
                if (conv[j] == -1  && conv[k] == -1)
                {
                    cc[j][k] = 1;
                    c[j]++;
                    cc[k][j] = 1;
                    c[k]++;
                    csum++;
                }
                else
                {
                    
                    cc[j][k] = 0;
                    cc[k][j] = 0;
                }
            }

        }

    }


    if (csum == 0)
    {
        return opSmoothIntersection(opSmoothIntersection(d[0], d[1],k), opSmoothIntersection(d[2], d[3],k), k);
    }

    if (csum == 6)
    {
        return opSmoothUnion(opSmoothUnion(d[0], d[1],k), opSmoothUnion(d[2], d[3],k),k);
    }

    if (csum == 1)
    {

        int i = 0;
        float dist = -100000;
        while (i < 4 && c[i] == 0)
        {
            i++;
        }

        for (int j = 0; j < 4; j++)
        {
            if (cc[i][j] == 1)
            {
                dist = opSmoothUnion(d[i], d[j],k);
            }
        }
       

        for (int j = 0; j < 4; j++)
        {
            if (c[j] == 0)
            {
                dist = opSmoothIntersection(dist, d[j],k);
            }
        }

        return dist;

    }

    if (csum == 5)
    {

        int i = 0;
        float dist = -100000;
        while (i < 4 && c[i] == 2)
        {
            i++;
        }

        for (int j = 0; j < 4; j++)
        {
            if (cc[i][j] == 0)
            {
                dist = opSmoothIntersection(d[i], d[j],k);
            }
        }

        for (int j = 0; j < 4; j++)
        {
            if (c[j] == 2)
            {
                dist = opSmoothUnion(dist, d[j],k);
            }
        }

        return dist;

    }

    if (csum == 2) //4 metszet 2 unió
    {

        //két külön darab vagy egyben van?
        bool tri = false;
        int u1, u2, u3,i4;
        u2 = -1;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 2)
            {
                u1 = i;
                for (int j = 0; j < 4; j++)
                {
                    if (cc[i][j] == 1 && u2 == -1)
                    {
                        u2 = j;
                    }
                    if (cc[i][j] == 1 )
                    {
                        u3 = j;
                    }
                    if (cc[i][j] == 0 && i!= j)
                    {
                        i4 = j;
                    }
                }

                tri = true;

            }
        }

        if (tri == true)
        {
            float dist;
            dist = opSmoothIntersection(d[u2], d[u3],k);
            dist = opSmoothUnion(dist, d[u1],k);
            return opSmoothIntersection(dist, d[i4],k);
        }
        else
        {
            float dist = -1000000;
            for (int i = 0; i < 4; i++)
            {
                if (c[i] == 1)
                {
                    for (int j = 0; j < 4; j++)
                    {
                        if (cc[i][j] == 1)
                        {
                        
                            dist = opSmoothIntersection(dist, min(d[i], d[j]),k);

                        }
                    }

                }
            }

            return dist;

        }

    }

    if (csum == 4) // 2 metszet 4 unió
    {

        //két külön darab vagy egyben van?
        bool tri = false;
        int u1, u2, u3, i4;
        u2 = -1;

        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 1) //ehhez 2 metszet tartozik
            {
                u1 = i;
                for (int j = 0; j < 4; j++)
                {
                    if (cc[i][j] == 0 && u2 == -1 && i!=j)
                    {
                        u2 = j;
                    }
                    if (cc[i][j] == 0 && i!= j)
                    {
                        u3 = j;
                    }
                    if (cc[i][j] == 1 && i != j)
                    {
                        i4 = j;
                    }
                }

                tri = true;

            }
        }

        if (tri == true)
        {
            float dist;
            dist = opSmoothUnion(d[u2], d[u3],k);
            dist = opSmoothIntersection(dist, d[u1],k);
            return opSmoothUnion(dist, d[i4],k);
        }
        else
        {
            float dist = 1000000;
            for (int i = 0; i < 4; i++)
            {
                if (c[i] == 2)
                {
                    for (int j = 0; j < 4; j++)
                    {
                        if (cc[i][j] == 0 && i!=j)
                        {
                        
                            dist = opSmoothUnion(dist, opSmoothIntersection(d[i], d[j],k),k);

                        }
                    }

                }
            }

            //return max(max(d[0], d[1]), max(d[2], d[3]));
            return dist;

        }

    }

    if (csum == 3)
    {
        for (int i = 0; i < 4; i++)
        {
            if (c[i] == 3) //3 metszve, utolsó unióban minddel
            {
                float dist = -10000000;
                for (int j = 0; j < 4; j++)
                {
                    if (i != j)
                    {
                        dist = max(dist, d[j]);
                    }
                }

                return min(dist, d[i]);

            }

            if (c[i] == 0) //3 unió, utolsó metszetben minddel
            {
                float dist = 10000000;
                for (int j = 0; j < 4; j++)
                {
                    if (i != j)
                    {
                        dist = min(dist, d[j]);
                    }
                }

                return max(dist, d[i]);

            }
        }

    }
    
    //return 10;
    return trilinear(p);
    
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
    return csg2(p);
    #endif

    return 0.0f;
}


float getDifference(float3 p1, float3 p2,)
{
    return filter(p1) - filter(p2);
}

float3 getNormal_filter(float3 pos)
{
    
    float e = 0.000001;
    float3 n;

    
        float3 p1 = pos + float3(e, 0, 0);
        float3 p2 = pos - float3(e, 0, 0);

        n.x = getDifference(p1, p2);
    
    
        float3 p12 = pos + float3(0, e, 0);
       
        float3 p22 = pos - float3(0, e, 0);
   
        n.y = getDifference(p12, p22);
    
    
    
        float3 p13 = pos + float3(0, 0, e);
     
        float3 p23 = pos - float3(0, 0, e);
      
        n.z = getDifference(p13, p23);

   
    return normalize(n);
}

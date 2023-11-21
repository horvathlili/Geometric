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


float sdCylinder(float3 p, float r, float3 c, float3 n, float3 d)
{
    float x = dot(p - c, n);
    float y = dot(p - c, d);

    return length(float2(x, y)) - r;

}


float sdTorus(float3 p, float3 center, float3 axis, float r, float R)
{
    float3 p2 = p - center;
    float3 e2 = normalize(axis);
    float3 n = cross(e2, normalize(p2));

    float3 e1 = normalize(cross(e2, n));

    float px = dot(e1, p2);
    float py = dot(e2, p2);

    float dist1 = sqrt((px - R) * (px - R) + py * py) - r;
    float dist2 = sqrt((px + R) * (px + R) + py * py) - r;

    if (dist1 * dist2 < 0) //egymásbalóg a tórusz
    {
    
        return min(dist1, dist2);
    }
    
    if (abs(dist1) <= abs(dist2))
        return dist1;
    else
        return dist2;


}

float sdTorusWithFootpointRepresentation(float3 p, float3 fp, float3 axis, float kr, float kR, float3 n, float inside, float sr)
{
    

    //smaller
    float r = 1.0f / abs(kr);
    float R;

    //bigger (according to the orientation of the torus)
    if (kr * kR > 0)
    {
        R = 1.0f / abs(kR) - r;
    }
    else
    {
        R = 1.0f / abs(kR) + r;
    }

    //calculate center
    float3 c = fp + n / kR;

    //return sdPlane(p, n, fp);

    //calculate frequently used values
    float dSphere = sdSphere((p - fp), sr);
    float dTorus = sdTorus(p, c, axis, r, R);

    if (R < 0.01)
    {
        R = 0;
        float3 c = fp + n / kr;
        dTorus = sdSphere(p - c, r);
    }

    float sign = 1;
    if (sdPlane(p, n, fp) < 0)
    {
        sign = -1;
    }

    //if the curvature is small use a plane
    if (abs(kr) < 0.1 && abs(kR) < 0.1)
    {
        return sign * max(sign * sdPlane(p, normalize(n), fp), dSphere);
    }

    sign = 1;

   
    
    //cylinder
    if (abs(kR) < 0.1 && abs(kr) > 0.1)
    {
        c = fp + n * 1 / kr;

        if (sdPlane(p, n, fp) < 0)
        {
            sign = -1;

     

        
        }
       

        float dCylinder = sdCylinder(p, r, c, n, axis);
        
        if (kr > 0)
        {
            if (r <= sr) //the radius is smaller than the intersecting sphere
                return sign * max(sign * -dCylinder, max(sdPlane(p, n, fp + n * 0.005f), dSphere));
           
            return sign * max(sign * -dCylinder, dSphere);
        }
        
        if (r <= sr)
            return sign * max(sign * dCylinder, max(sdPlane(p, n, fp + n * 0.005f), dSphere));
           
        return sign * max(sign * dCylinder, dSphere);
    }


    

    sign = 1;
   

    if (sdPlane(p, n, fp) < 0)
    {
        sign = -1;

     

        
    }
   /* else
    {
        /*if (kR > 0)
        {
            if (kr <= 0 && dTorus < 0 && length(p - fp) < sr)
            {
                sign = -1;

            }

        
            if (kr > 0 && dTorus > 0 && length(p - fp) < sr)
            {
                sign = -1;

            }
        }
    }*/

    if (kr <= 0 && dTorus > 0 && length(p - fp) < 2 * sr)
    {
        sign = 1;

    }

        
    if (kr > 0 && dTorus < 0 && length(p - fp) < 2 * sr)
    {
        sign = 1;

    }

    if (kr <= 0 && dTorus < 0 && length(p - fp) < 2 * sr)
    {
        sign = -1;

    }

        
    if (kr > 0 && dTorus > 0 && length(p - fp) < 2 * sr)
    {
        sign = -1;

    }
    
    if (r < sr)
        sign = 1;
    
    if (length(fp - p) > sr)
    {
        sign = inside;
    }
    
    
    dTorus *= sign;

  
    
   
    
    
    //different cases of the torus
    if (kr > 0)
    {
       
        if (kR <= 0)
        {
            if (r <= sr) //the radius is smaller than the intersecting sphere
                return sign * max(-dTorus, max(sdPlane(p, n, fp + n * 0.005f), dSphere));
           
            return sign * max(-dTorus, dSphere);
        }
        else
        {
          
            return sign * max(-dTorus, dSphere);
        }

    }
    else
    {

        
        if (kR < 0)
        {
            
            return sign * max(dTorus, dSphere);
        }
        else
        {
            if (r <= sr) //the radius is smaller than the intersecting sphere
                return sign * max(dTorus, max(sdPlane(p, n, fp + n * 0.005f), dSphere));
           
            return sign * max(dTorus, dSphere);
           
           
        }
    }

    //return 1;
}


float noInterp(float3 pos)
{

    //float3 p1 = ((pos) / float3(boundingBox) + 0.5);

    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res);

    
    
   // float3 fuvw = clamp(p1 * (float(res)) - 0.5, 0, float(res) - 1);
    //int3 uvw = clamp(fuvw, 0, res - 2);
  
    
    //float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res-0.00001);

    float3 texelcenter = -float3(boundingBox / 2.0f) + ((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 d = normalize(t2.xyz);
    float r = t1.w;
    float R = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;
    float inside = texture3[uvw].w;

    float sr = boundingBox / (float) res;
   
    return sdTorusWithFootpointRepresentation(pos, fp, d, r, R, n, inside, sr);
}

float4 debug(float3 pos, float3 debugpos)
{
   
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res - 0.0001);

    float3 texelcenter = -float3(boundingBox / 2.0f) + ((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 axis = t2.xyz;
    float kr = t1.w;
    float kR = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;
    float inside = texture3[uvw].w;
     //if the curvature is small use a plane
    if (abs(kr) < 0.1 && abs(kR) < 0.1)
    {
        return sdPlane(pos, normalize(n), fp);
    }

    //smaller
    float r = 1.0f / abs(kr);
    float R;

   

    //bigger (according to the orientation of the torus)
    if (kr * kR > 0)
    {
        R = 1.0f / abs(kR) - r;
    }
    else
    {
        R = 1.0f / abs(kR) + r;
    }

    //calculate center
    float3 c = fp + n / kR;

    if (abs(kR) < 0.1 || abs(kr) < 0.1)
    {
        //return 1;
        c = fp + n * 1 / kr;
        return sdCylinder(pos, r, c, n, axis);
    }

    //ha nem metszünk gömbbel
   
  //  return float4(fp, sdTorus(pos, c, axis, r, R));

    
    float3 p = pos;
    float sr = boundingBox / (float) res;

    float dTorus = sdTorus(pos, c, axis, r, R);
    float dSphere = sdSphere((p - fp), sr);

    float sign = 1;


    /*if (sdPlane(debugpos, n, fp) < 0)
    {
        sign = -1;
        
    }
   // sign = 1;

   /* if (r < sr)
        sign = 1;

    if (length(fp - debugpos) > sr)
    {
        sign = inside;
    }

    dTorus *= sign;*/

    float d = 1;;
    //different cases of the torus
    if (kr > 0)
    {
       
        if (kR <= 0)
        {

            d = sign * max(-dTorus, dSphere);
            if (r <= sr) //the radius is smaller than the intersecting sphere
                d = sign * max(-dTorus, max(sdPlane(p, sign * n, fp + sign * n * 0.005f), dSphere));
           
          
        }
        else
        {
           
            d = sign * max(-dTorus, dSphere);
        }

    }
    else
    {
        if (kR < 0)
        {
            
            d = sign * max(dTorus, dSphere);
        }
        else
        {

            d = sign * max(dTorus, dSphere);
            if (r <= 2 * sr) //the radius is smaller than the intersecting sphere
                d = sign * max(dTorus, max(sdPlane(p, sign * n, fp + sign * n * 0.005f), dSphere));
           
         
           
           
        }
    }

    
    return float4(fp, dTorus);
 

   

}

float4 debug2(float3 pos, float3 debugpos)
{
   
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res - 0.0001);

    float3 texelcenter = -float3(boundingBox / 2.0f) + ((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 axis = t2.xyz;
    float kr = t1.w;
    float kR = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;
     //if the curvature is small use a plane
    float sr = boundingBox / (float) res;
    float sign = 1;
  
    

    //smaller
    float r = 1.0f / abs(kr);
    float R;

    //bigger (according to the orientation of the torus)
    if (kr * kR > 0)
    {
        R = 1.0f / abs(kR) - r;
    }
    else
    {
        R = 1.0f / abs(kR) + r;
    }

    float3 cc = fp - n * r;


    float3 p = ((pos) / float3(boundingBox) + 0.5);

    //calculate center
    float3 c = fp + n / kR;

    if (abs(kr) < 0.01 && abs(kR) < 0.1)
    {
        return max(sdPlane(pos, normalize(sign * n), fp), sdSphere((pos - fp), sr));
    }

     //calculate frequently used values
    float dSphere = sdSphere((p - fp), sr);
    float dTorus = sdTorus(p, c, axis, r, R);

    sign = 1;

    //if the curvature is small use a plane
    if (abs(kr) < 0.01 && abs(kR) < 0.1)
    {
        return max(sdPlane(p, normalize(sign * n), fp), dSphere);
    }

    if (dot(n, normalize(p - fp)) < 0)
    {
        sign = -1;

    }
    
    //cylinder
   /* if (abs(kR) < 0.1 || abs(kr) < 0.1)
    {
        c = fp + n * 1 / kr;
        if (kr > 0)  
            return sign * max(sign * -sdCylinder(p, r, c, n, axis), dSphere);
        return sign * max(sign * sdCylinder(p, r, c, n, axis), dSphere);
    }*/


    sign = 1;
    if (dot(n, normalize(p - fp)) < 0)
    {
        sign = -1;

        if (kR <= 0 && dTorus > 0 && length(p - fp) < sr)
        {
            sign = 1;

        }

        if (kR > 0 && dTorus < 0 && length(p - fp) < sr)
        {
            sign = 1;

        }
    }

    //sign = 1;
    dTorus *= sign;

   

    //different cases of the torus
    if (kr > 0)
    {
       
        if (kR <= 0)
        {
            if (r <= sr) //the radius is smaller than the intersecting sphere
                return sign * max(-dTorus, max(sdPlane(p, sign * n, fp + sign * n * 0.005f), dSphere));
           
            return sign * max(-dTorus, dSphere);
        }
        else
        {
           
            return sign * max(-dTorus, dSphere);
        }

    }
    else
    {
        if (kR < 0)
        {
            
            return sign * max(dTorus, dSphere);
        }
        else
        {
            if (r <= 2 * sr) //the radius is smaller than the intersecting sphere
                return sign * max(dTorus, max(sdPlane(p, sign * n, fp + sign * n * 0.005f), dSphere));
           
            return sign * max(dTorus, dSphere);
           
           
        }
    }

    return 1;
}


float getTexture(float3 uvw, float3 pos)
{
  
    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 d = t2.xyz;
    float r = t1.w;
    float R = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;

    float inside = texture3[uvw].w;

    float sr = boundingBox / (float) res;
   
    return sdTorusWithFootpointRepresentation(pos, fp, d, r, R, n, inside, sr);
}

float trilinear(float3 pos)
{
    float3 p1 = ((pos) / float3(boundingBox) + 0.5);
    
    float3 fuvw = clamp(p1 * (float(res)) - 0.5, 0, float(res) - 1);
    int3 uvw = clamp(fuvw, 0, res - 2);
    
    float d000 = getTexture(uvw, pos);
    float d100 = getTexture(uvw + float3(1, 0, 0), pos);
    float d010 = getTexture(uvw + float3(0, 1, 0), pos);
    float d001 = getTexture(uvw + float3(0, 0, 1), pos);
    float d110 = getTexture(uvw + float3(1, 1, 0), pos);
    float d101 = getTexture(uvw + float3(1, 0, 1), pos);
    float d011 = getTexture(uvw + float3(0, 1, 1), pos);
    float d111 = getTexture(uvw + float3(1, 1, 1), pos);

    float a1 = fuvw.x - (int) uvw.x;
    float ha1 = 6 * pow(a1, 5) - 15 * pow(a1, 4) + 10 * pow(a1, 3);
    float d00 = d000 * (1 - ha1) + d100 * ha1;
    float d01 = d001 * (1 - ha1) + d101 * ha1;
    float d10 = d010 * (1 - ha1) + d110 * ha1;
    float d11 = d011 * (1 - ha1) + d111 * ha1;

    float a2 = fuvw.y - (int) uvw.y;
    float ha2 = 6 * pow(a2, 5) - 15 * pow(a2, 4) + 10 * pow(a2, 3);
    float d0 = d00 * (1 - ha2) + d10 * ha2;
    float d1 = d01 * (1 - ha2) + d11 * ha2;


    float a3 = fuvw.z - (int) uvw.z;
    float ha3 = 6 * pow(a3, 5) - 15 * pow(a3, 4) + 10 * pow(a3, 3);
    return d0 * (1 - ha3) + d1 * ha3;

}


float filter(float3 p)
{
#if INTERP == 0
   // return sdExact(p);
    return noInterp(p);
#endif
#if INTERP == 1
    return trilinear(p);
#endif
    return 0.0f;
}


float getDifference(float3 p1, float3 p2,)
{
    return filter(p1) - filter(p2);
}

float3 getNormal_filter(float3 pos)
{
    float e = 0.000005;
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

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

    if (abs(dist1) <= abs(dist2))
        return dist1;
    else
        return dist2;


}

float sdTorusWithFootpointRepresentation(float3 p, float3 fp, float3 axis,float kr, float kR, float3 n, float sr)
{
    
    float sign = 1;
    if (dot(n, normalize(fp - p)) > 0 && length(fp - p) < 0.1)
    {
        sign = -1;
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

    //calculate frequently used values
    float dSphere = sdSphere((p - fp), sr);
    float dTorus = sdTorus(p, c, axis, r, R);

    //if the curvature is small use a plane
    if (abs(kr) < 0.01 && abs(kR) < 0.1)
    {
        return max(sdPlane(p, normalize(sign * n), fp), dSphere);
    }


    //cylinder
    if (abs(kR) < 0.1 || abs(kr) < 0.1)
    {
        c = fp + n * 1 / kr;
        if (kr > 0)  
         return sign * max(sign * -sdCylinder(p, r, c, n, axis),dSphere);
        return sign * max(sign * sdCylinder(p, r, c, n, axis), dSphere);
    }
    
    if (dot(n, normalize(fp - p)) > 0 && length(fp - p)<0.1)
    {
        dTorus = -dTorus;
        sign = -1;
    }
    //return sdPlane(p, n, fp);
        

    //different cases of the torus
    if (kr > 0)
    {
       
        if (kR <= 0)
        {
            if ( r <= sr) //the radius is smaller than the intersecting sphere
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
            if (r <= 2*sr) //the radius is smaller than the intersecting sphere
                return sign * max(dTorus, max(sdPlane(p, sign * n, fp + sign * n * 0.005f), dSphere));
           
            return sign * max(dTorus,  dSphere);
           
           
        }            
    }

    return 1;
}

float sdExact(float3 pos)
{
    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res - 0.00001);

    float3 texelcenter = -float3(boundingBox / 2.0f) + ((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 d = normalize(t2.xyz);
    float kr = t1.w;
    float kR = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;

    float sr = boundingBox / (float) res;
    float sign = 1;
    if (dot(n, normalize(fp - pos)) > 0 && length(fp - pos) < 0.1)
    {
        sign = -1;
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

    float3 cc = fp - n * r;
    

    //calculate center
    float3 c = fp + n / kR;

    if (abs(kr) < 0.01 && abs(kR) < 0.1)
    {
        return max(sdPlane(pos, normalize(sign * n), fp), sdSphere((pos - fp), sr));
    }


    if (abs(kR) < 0.1 || abs(kr) < 0.1)
    {
        c = fp + n * 1 / kr;
        if (kr > 0)  
            return sign * max(sign * -sdCylinder(pos, r, c, n, d), sdSphere((pos - fp), sr));
        return sign * max(sign * sdCylinder(pos, r, c, n, d), sdSphere((pos - fp), sr));
    }
    
    float dTorus = sdTorus(pos, c, d, r, R);



    
   //here i project on the plane of the axis and p-c
  //
    float3 p2 = pos - c;
    float3 e2 = normalize(d);
    float3 norm = cross(e2, normalize(p2));

    float3 e1 = normalize(cross(e2, norm));

    float px = dot(e1, p2);
    float py = dot(e2, p2);

    float nx = dot(e1, n);
    float ny = dot(e2, n);

    float2 norm2 = normalize(float2(nx, ny));
    
    float dist1 = sqrt((px-R) * (px - R) + py * py) - r;
    float dist2 = sqrt((px + R) * (px + R) + py * py) - r;

   
    float3 fpp = fp - c;
    float fpx = dot(e1, fpp);
    float fpy = dot(e2, fpp);

    float fd1 = length(float2(R, 0) - float2(fpx, fpy));
    float fd2 = length(float2(-R, 0) - float2(fpx, fpy));

    float2 cp;
    
    //return dTorus;
    if (fd1 < fd2)
    {
        dTorus = dist1;
        cp = float2(R, 0);

    }
    else
    {
        dTorus = dist2;
        cp = float2(-R, 0);
    }
       
    float sig = 1;
    if (kr > 0)
    {
        norm2 *=  -1;
        sig *= -1;
    }

   
 
    
    float ra = radians(a);

    float2x2 rot1 = float2x2(cos(ra), -sin(ra), sin(ra), cos(ra));

    float2 s1 = normalize(mul(rot1, norm2));
    float2 ep1 = cp + s1 * r;

    float2x2 rot2 = float2x2(cos(-ra), -sin(-ra), sin(-ra), cos(-ra));

    float2 s2 = normalize(mul(rot2, norm2));
    float2 ep2 = cp + s2 * r;

    //here i project on the plane of the normal and dxn
    float sig2 = 1;
    if (kR > 0)
    {
        sig2 *= -1;
    }
    float3 s_p2 = pos - c;
    float3 s_e1 = normalize(sig2 * n);
    float3 s_e2 = normalize(cross(s_e1, d));

    float s_px = dot(s_e1, s_p2);
    float s_py = dot(s_e2, s_p2);

    float2 s_norm2 = normalize(float2(1, 0));

           
      
   
    float rb = radians(b);

    if (dot(normalize(float2(s_px, s_py)), s_norm2) > cos(rb))
    {
        if (dot(normalize(float2(px, py) - cp), norm2) > cos(ra))
        {
        //return abs(dTorus);
            float de = length(cp - float2(px, py));

            if (de > r && kr > 0)
            {
          
                return min(min(dTorus * sig, -length(cp + s1 * de - float2(px, py))), -length(cp + s2 * de - float2(px, py)));


            }
       
            return dTorus * sig;
        }
        else
        {
            return min(length(float2(px, py) - ep1), length(float2(px, py) - ep2));
        }

    }

    return 0.5*length(pos - fp);

    //ha egyikben sincs benne -> szélső körtől távolság

    //forgatni a s_norm2-t erre arra
     //visszaváltani 3d-be
    float2x2 s_rot1 = float2x2(cos(rb), -sin(rb), sin(rb), cos(rb));

    float2 s_s1 = normalize(mul(s_rot1, s_norm2));
    float3 rnorm1 = normalize(s_e1 * s_s1.x + s_e2 * s_s1.y);

    float2x2 s_rot2 = float2x2(cos(-rb), -sin(-rb), sin(-rb), cos(-rb));

    float2 s_s2 = normalize(mul(s_rot2, s_norm2));
    float3 rnorm2 = normalize(s_e1 * s_s2.x + s_e2 * s_s2.y);   

    //rnorm1 és d-nek a síkjára vetíteni p-cp-t

            float fdist; //ebben lesz az itt kapott távolság
             p2 = pos - c;

            e2 = normalize(d);
            e1 = normalize(rnorm1);

            px = dot(e1, p2);
            py = dot(e2, p2);

    
            nx = dot(e1, rnorm1);
            ny = dot(e2, rnorm1);

              norm2 = normalize(float2(nx, ny));
    
            dist1 = sqrt((px - R) * (px - R) + py * py) - r;
            dist2 = sqrt((px + R) * (px + R) + py * py) - r;

            fpp = fp - c;
            fpx = dot(e1, fpp);
            fpy = dot(e2, fpp);
    
            fd1 = length(float2(R, 0) - float2(fpx, fpy));
            fd2 = length(float2(-R, 0) - float2(fpx, fpy));


   
            if (fd1 < fd2)
            {   
                dTorus = dist1;
                cp = float2(R, 0);
                
            }
            else
            {
                dTorus = dist2;
                cp = float2(-R, 0);
            }

            rot1 = float2x2(cos(ra), -sin(ra), sin(ra), cos(ra));

            s1 = normalize(mul(rot1, norm2));
            ep1 = cp + s1 * r;

            rot2 = float2x2(cos(-ra), -sin(-ra), sin(-ra), cos(-ra));

            s2 = normalize(mul(rot2, norm2));
            ep2 = cp + s2 * r;

            if (dot(normalize(float2(px, py) - cp), norm2) > cos(ra))
            {
           
                float de = length(cp - float2(px, py));
                if (de > r && kr > 0)
                {
          
                    fdist = min(min(dTorus * sig, -length(cp + s1 * de - float2(px, py))), -length(cp + s2 * de - float2(px, py)));


                }   
                else
                {   
       
                    fdist = dTorus * sig;
                }
            }
            else
            {
       

                fdist = min(length(float2(px, py) - ep1), length(float2(px, py) - ep2));

            }


    //rnorm2 síkjába vetítés
    e1 = normalize(rnorm2);

    px = dot(e1, p2);
    py = dot(e2, p2);

    nx = dot(e1, rnorm2);
    ny = dot(e2, rnorm2);

    norm2 = normalize(float2(nx, ny));
    
    dist1 = sqrt((px - R) * (px - R) + py * py) - r;
    dist2 = sqrt((px + R) * (px + R) + py * py) - r;

   
    fpp = fp - c;
    fpx = dot(e1, fpp);
    fpy = dot(e2, fpp);

    fd1 = length(float2(R, 0) - float2(fpx, fpy));
    fd2 = length(float2(-R, 0) - float2(fpx, fpy));

    
    
    //return dTorus;
    if (fd1 < fd2)
    {
        dTorus = dist1;
        cp = float2(R, 0);

    }
    else
    {
        dTorus = dist2;
        cp = float2(-R, 0);
    }

    rot1 = float2x2(cos(ra), -sin(ra), sin(ra), cos(ra));

    s1 = normalize(mul(rot1, norm2));
    ep1 = cp + s1 * r;

    rot2 = float2x2(cos(-ra), -sin(-ra), sin(-ra), cos(-ra));

    s2 = normalize(mul(rot2, norm2));
    ep2 = cp + s2 * r;
    
    if (dot(normalize(float2(px, py) - cp), norm2) > cos(ra))
    {
        //return abs(dTorus);
        float de = length(cp - float2(px, py));

        if (de > r && kr > 0)
        {
          
            return min(fdist, min(min(dTorus * sig, -length(cp + s1 * de - float2(px, py))), -length(cp + s2 * de - float2(px, py))));


        }
       
        return min(fdist, dTorus * sig);
    }
 
    //köröktől távolságok
     
    return max(fdist, min(length(float2(px, py) - ep1), length(float2(px, py) - ep2)));
   
    }

float noInterp(float3 pos)
{
    
    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res-0.00001);

    float3 texelcenter = -float3(boundingBox / 2.0f)+((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 d = normalize(t2.xyz);
    float r = t1.w;
    float R = t2.w;    

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;

    float sr = boundingBox / (float) res  ;
   
    return sdTorusWithFootpointRepresentation(pos, fp, d, r, R, n, sr);
}

float4 debug2(float3 pos, float3 debugpos)
{
   
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res-0.0001);

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
        c = fp +n*1/kr;
        return sdCylinder(pos, r, c, n, axis);
    }

    //ha nem metszünk gömbbel
   
    return float4(fp, sdTorus(pos, c, axis, r, R));
}

float4 debug(float3 pos, float3 debugpos)
{
   
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res - 0.0001);

    float3 texelcenter = -float3(boundingBox / 2.0f) + ((int3) uvw + float3(0.5)) * float3(boundingBox) / (float) res;

    
    
    float4 t1 = texture1[uvw];
    float4 t2 = texture2[uvw];

    float3 fp = t1.xyz;
    float3 d = t2.xyz;
    float kr = t1.w;
    float kR = t2.w;

    //calculating the normalvector for the representation conversion
    float3 n = texture3[uvw].xyz;
     //if the curvature is small use a plane
    float sr = boundingBox / (float) res;
    float sign = 1;
    if (dot(n, normalize(fp - pos)) > 0 && length(fp - pos) < 0.1)
    {
        sign = -1;
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

    float3 cc = fp - n * r;
    

    //calculate center
    float3 c = fp + n / kR;

    if (abs(kr) < 0.01 && abs(kR) < 0.1)
    {
        return max(sdPlane(pos, normalize(sign * n), fp), sdSphere((pos - fp), sr));
    }

    //calculate frequently used values
 
    float dTorus = sdTorus(pos, c, d, r, R);
   

   

    float3 p2 = pos - c;
    float3 e2 = normalize(d);
    float3 norm = cross(e2, normalize(p2));

    float3 e1 = normalize(cross(e2, norm));

    float px = dot(e1, p2);
    float py = dot(e2, p2);

    float nx = dot(e1, n);
    float ny = dot(e2, n);

    float2 norm2 = normalize(float2(nx, ny));
    
    float dist1 = sqrt((px - R) * (px - R) + py * py) - r;
    float dist2 = sqrt((px + R) * (px + R) + py * py) - r;

   
    
    float3 fpp = fp - c;
    float fpx = dot(e1, fpp);
    float fpy = dot(e2, fpp);

    float fd1 = length(float2(R, 0) - float2(fpx, fpy));
    float fd2 = length(float2(-R, 0) - float2(fpx, fpy));

    float2 cp;
    
    //return dTorus;
    if (fd1 < fd2)
    {
        dTorus = dist1;
        cp = float2(R, 0);

    }
    else
    {
        dTorus = dist2;
        cp = float2(-R, 0);
    }
    float sig = 1;
    if (kr > 0)
    {
        norm2 *= -1;
        sig *= -1;
    }
    

    float a = 90;
    float ra = radians(a);

    float2x2 rot1 = float2x2(cos(ra), -sin(ra), sin(ra), cos(ra));

    float2 s1 = normalize(mul(rot1, norm2));
    float2 ep1 = cp + s1 * r;

    float2x2 rot2 = float2x2(cos(-ra), -sin(-ra), sin(-ra), cos(-ra));

    float2 s2 = normalize(mul(rot2, norm2));
    float2 ep2 = cp + s2 * r;
    
    if (dot(normalize(float2(px, py) - cp), norm2) > cos(ra))
    {
        //return abs(dTorus);
        float de = length(cp - float2(px, py));

        if (de > r && kr > 0)
        {
          
            return min(min(dTorus * sig, -length(cp + s1 * de - float2(px, py))), -length(cp + s2 * de - float2(px, py)));


        }

        {

            float sig2 = 1;
            if (kR > 0)
            {
                sig2 *= -1;
            }
            float3 p2 = pos - c;
            float3 e1 = normalize(sig2 * n);
            float3 e2 = normalize(cross(e1, d));

            float px = dot(e1, p2);
            float py = dot(e2, p2);

            float2 norm2 = normalize(float2(1, 0));

           
      
            float a = 10;
            float ra = radians(a);

            if (dot(normalize(float2(px, py)), norm2) > cos(ra))
            {

            
                return dTorus * sig;
            }
            else
            {
                return 1;
                return max(length(float2(px, py) - ep1), length(float2(px, py) - ep2));
            }
    
        }
        
        return dTorus * sig;
    }



    //széle számolása

    //széléhez mutató vektor

   
    
    return min(length(float2(px, py) - ep1), length(float2(px, py) - ep2));
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

    float sr = boundingBox / (float) res*1.5f;
   
    return sdTorusWithFootpointRepresentation(pos, fp, d, r, R, n, sr);
}

float trilinear(float3 pos)
{
    float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res-1);

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
    return d0 * (1 - ha3) + d1 * ha3;

}


float filter(float3 p)
{
    #if INTERP == 0
    return sdExact(p);
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

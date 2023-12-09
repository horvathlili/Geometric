float4 sphereTrace(float3 pixelpos)
{
    Ray r;
    if (!box)
    {
        r = getRay(eye.xyz, center.xyz, up.xyz, ar, pixelpos.x, pixelpos.y);
    }
    else
    {
        r.v = normalize(pixelpos - eye.xyz);
        r.p = pixelpos;
        
    }

   
    
    float t = 0.0f;
    int i;
    float h;
    int n = 100;
    float3 pos = r.p + t * r.v;
   
       
    for (i = 0; i <n; i++)
    {
        pos = r.p + t * r.v;
       
        h = filter(pos);
       
        if (h < 0.0001 || isOutOfBox(pos))
            break;
        t += rel*h;
    }

    float3 hitpos = pos;
    float hit = 0;
    if (i >= n || isOutOfBox(pos))
        hit = 1;
    return float4(hitpos, hit);
}



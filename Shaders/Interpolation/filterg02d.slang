#ifndef INTERP
#define INTERP 0
#endif

float sdLine(float2 p, float2 fp, float2 n)
{

    return dot(p - fp, n);
}

float noInterp(float2 p)
{
    int2 uv = p*res;

    float4 t1 = texture1[uv];



 
    return t1.x;
}



float bilinear(float2 p)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);
    
    
    float d1 = texture1[uv].x;
   
    float d2 = texture1[uv + float2(1, 0)].x;
   
    float d3 = texture1[uv + float2(0, 1)].x;
   
    float d4 = texture1[uv + float2(1, 1)].x;

    float d11 = (1 - ab.x) * d1 + ab.x * d2;
    float d22 = (1 - ab.x) * d3 + ab.x * d4;

    
    return (1 - ab.y) * d11 + ab.y * d22;
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

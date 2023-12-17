#ifndef INTERP
#define INTERP 0
#endif




float noInterp(float3 pos)
{
    float3 uvw = ((pos) / float3(boundingBox) + 0.5);

    float4 t1 = texture1.SampleLevel(mSampler, uvw, 0);


   
   
    return t1.x;
}

float4 debug(float3 pos,float3 debugpos)
{
    float3 uvw = ((debugpos) / float3(boundingBox) + 0.5) * (res);

    float4 t1 = texture1.Sample(mSampler, uvw);
  
   
    return float4(t1.x,0,0,0);
}

float getTexture(float3 uvw, float3 pos)
{
    float4 t1 = texture1.Sample(mSampler, uvw);
  

   
    return t1.x;
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
    return d0 * (1 - ha3) + d1 * ha3;

    return 0;

}






float filter(float3 p)
{
    #if INTERP == 0
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
    float3 uvw = ((pos) / float3(boundingBox) + 0.5);
   
    return texture1.SampleLevel(mSampler, uvw, 0).gba;
}


#include "Shaders/Utils/includes2d.slang"
#include "Shaders/SDF/sdf2d.slang"




RWStructuredBuffer<float> seconderrors;
RWStructuredBuffer<float> firsterrors;
RWStructuredBuffer<float> inferrors;
RWStructuredBuffer<float> pixerrors;

cbuffer csCb
{
    int testres;
};




float2 getQueryPoint(float2 p)
{
    float2 pos = float2(0,0);
    pos.x += (float)1.f / (float) testres * (p.x + 0.5);
    pos.y += (float)1.f / (float) testres * (p.y + 0.5);
  
    return pos;
}



[numthreads(8, 8)]
void main(uint2 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xy >= float2(testres)))
        return;

    float error = 0;
    float seconderror = 0;
    float firsterror = 0;
    float inferror = 0;
    float pixerror = 0;

    float2 pos = getQueryPoint(threadId.xy);

    float2 ppos = (pos - 0.5) * boundingBox;

  
    #if FIELD != 3
       
   

   
        error = abs(map(ppos) - filter(pos));

        
        
        seconderror += (error * error);


        firsterror += error;

        if (error > inferror)
        {
            inferror = error;
        }
    
    int a = (filter(pos) > 0) ? 1 : -1;
    int ao = (map(ppos) > 0) ? 1 : -1;
   
    if (a*ao < 0 )
    {
        pixerror = 1;
    }
    
  #endif
    #if FIELD == 3
     
  
         float4 te = msdftexture.SampleLevel(mSampler, pos,0);
   
   float dd =   (te.x -0.5) ;
    int a = (dd > 0) ? 1 : -1;

    te= osdftexture.SampleLevel(mSampler, pos,0);
    float ddo = (te.x-0.5);
    int ao = (ddo > 0) ? 1 : -1;

    if (a*ao <0)
        pixerror = 1;
    
#endif
 
    seconderrors[threadId.x * testres + threadId.y] = seconderror;
    firsterrors[threadId.x * testres + threadId.y] = firsterror;
    inferrors[threadId.x * testres + threadId.y] = inferror;
    pixerrors[threadId.x * testres + threadId.y] = pixerror;
}


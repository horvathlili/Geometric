#include "Shaders/Utils/includes2d.slang"
#include "Shaders/SDF/sdf2d.slang"




RWStructuredBuffer<float> seconderrors;
RWStructuredBuffer<float> firsterrors;
RWStructuredBuffer<float> inferrors;

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

  

        float2 pos = getQueryPoint(threadId.xy);

    float2 ppos = (pos - 0.5) * boundingBox;
        error = abs(map(ppos) - filter(pos));

        
        
        seconderror += (error * error);


        firsterror += error;

        if (error > inferror)
        {
            inferror = error;
        }
    
    
    
    seconderrors[threadId.x * testres + threadId.y] = seconderror;
    firsterrors[threadId.x * testres + threadId.y] = firsterror;
    inferrors[threadId.x * testres + threadId.y] = inferror;
}


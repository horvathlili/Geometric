#include "../Utils/includes3d.slang"
#include "../SDF/sdf3d.slang"




RWStructuredBuffer<float> seconderrors;
RWStructuredBuffer<float> firsterrors;
RWStructuredBuffer<float> inferrors;
RWStructuredBuffer<float> checkerrors;


cbuffer csCb
{
    int testres;
};




float3 getQueryPoint(float3 p)
{
    float3 pos = float3(-(float) boundingBox / 2.0);
    pos.x += (float) boundingBox / (float) testres * (p.x + 0.5);
    pos.y += (float) boundingBox / (float) testres * (p.y + 0.5);
    pos.z += (float) boundingBox / (float) testres * (p.z + 0.5);

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
   

    for (int i = 0; i < testres; i++)
    {

        float3 pos = getQueryPoint(float3(threadId.xy, i));
        error = abs(map(pos) - filter(pos));

       // if (map(pos )<0)
         //  error = 0;

        float3 uvw = ((pos) / float3(boundingBox) + 0.5) * (res);

    

        float4 t1 = texture1[uvw];
        
        seconderror += (error * error);
        
        
        firsterror += error;

        if (error > inferror)
        {
            inferror = error;
           
            //firsterrors[threadId.x * testres + threadId.y] = filter(t1.xyz);
            //checkerrors[threadId.x * testres + threadId.y] = t1.z;
        }
    }
    
    
    seconderrors[threadId.x * testres + threadId.y] = seconderror;
   firsterrors[threadId.x * testres + threadId.y] = firsterror;
    inferrors[threadId.x * testres + threadId.y] = inferror;
}


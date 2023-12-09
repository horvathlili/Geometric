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

        float3 fp, n;

        n = getNormal(pos);
        fp = pos - map(pos) * n;

   
  
        int s = 0;
        while (abs(map(fp)) > 0.01 && s < 40)
        {
            n = getNormal(fp);
            fp = fp - n * map(fp);
            s++;
        }

        int is = map(pos) < 0 ? -1 : 1;

        error = abs(is * length(fp - pos) - filter(pos));

       // if (is <0)
         //   error = 0;

        seconderror += (error * error);

        
        
        firsterror += error;

        if (error > inferror)
        {
            inferror = error;

         
        }
    }

    float4 pp = texture1[float3(threadId.xy, 0)];
    
    
    seconderrors[threadId.x * testres + threadId.y] = seconderror;
   firsterrors[threadId.x * testres + threadId.y] = firsterror;
    inferrors[threadId.x * testres + threadId.y] = inferror;
}


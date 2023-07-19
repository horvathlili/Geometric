#include "../Utils/includes3d.slang"
#include "../SDF/sdf3d.slang"


RWTexture2D<float4> tex;

RWStructuredBuffer<float> errors;
RWStructuredBuffer<float2> randoms;

cbuffer csCb
{
    int testres;
};

float3 getRandomPointOnSphere(float i, float j,float r)
{
    float k = i * testres + j;
    float N= testres * testres;
    

    float h = 1 - ((2 * k - 1) / N);

    float u = acos(h);

    float L = sqrt(N * radians(180));

    float v = L * u;

    float3 psphere = float3(r*sin(v) * cos(u), r*cos(v), r*sin(v) * sin(u));

    return psphere;

}


float3 getPointOnSphere(int i, int j)
{
    float u = radians((i + 0.5) * 360 / (float) (testres + 1));
    float v = radians((j + 0.5) * 180 / (float) (testres + 1));

    float3 psphere = float3( sin(v) * cos(u),  cos(v),  sin(v) * sin(u));

    return psphere;

}

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

    for (int i = 1; i < 50; i++)
    {
        
    
        float3 pos;
        pos = getRandomPointOnSphere(threadId.x, threadId.y,0.03*i);


        float3 no = getNormal_filter(pos);
        float3 fp = pos - filter(pos) * normalize(no);

        int s = 0;
        while (abs(filter(fp)) > 0.00001 && s < 40)
        {
            no = getNormal_filter(fp);
            fp = fp - normalize(no) * filter(fp);
            s++;
        }
    
    
        
        if (abs(map(fp)) > error)
            error = abs(map(fp));

        no = getNormal(pos);
        fp = pos - map(pos) * normalize(no);

        s = 0;
        while (abs(map(fp)) > 0.00001 && s < 40)
        {
            no = getNormal(fp);
            fp = fp - normalize(no) * map(fp);
            s++;
        }
    
    
        
        if (abs(filter(fp)) > error)
            error = abs(filter(fp));

    }
    
    tex[threadId.xy] = float4(1, 1 - error, 1 - error, 1);
    errors[threadId.x * testres + threadId.y] = error;
   
}


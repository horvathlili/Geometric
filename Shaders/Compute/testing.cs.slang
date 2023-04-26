#include "../Utils/includes.slang"
#include "../SDF/sdf3d.slang"


RWTexture2D<float4> tex;

RWStructuredBuffer<float> errors;
RWStructuredBuffer<float2> randoms;

cbuffer csCb
{
    int testres;
};

float3 getRandomPointOnSphere(float i, float j)
{
    float u = randoms[i * testres + j].x;
    float v = randoms[i * testres + j].y;

    u = 2 * radians(180) * u;
    v = acos(2 * v - 1);

    float3 psphere = float3(sin(v) * cos(u), cos(v), sin(v) * sin(u));

    return psphere;

}


float3 getPointOnSphere(int i, int j)
{
    float u = radians((i + 0.5) * 360 / (float) (testres + 1));
    float v = radians((j + 0.5) * 180 / (float) (testres + 1));

    float3 psphere = float3( sin(v) * cos(u),  cos(v),  sin(v) * sin(u));

    return psphere;

}

[numthreads(8, 8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xyz >= float3(testres)))
        return;
    
    Ray r;
    r.p = getRandomPointOnSphere(threadId.x,threadId.y);
    r.v = normalize(-r.p);

    float t = 0.0f;
    int i;
    float h;
    int n = 100;
    float3 pos = r.p + t * r.v;
   
       
    for (i = 0; i < n; i++)
    {
        pos = r.p + t * r.v;
       
        h = filter(pos);
       
        if (h < 0.0001 || isOutOfBox(pos))
            break;
        t += h;
    }

    float3 hitpos = r.p + t * r.v;

    float error = 0;
    if (!isOutOfBox(pos))
    {
        error = map(hitpos);

    }
    
    tex[threadId.xy] = float4(1,1-error,1-error, 1);
    errors[threadId.x * testres + threadId.y] = error;
   
}


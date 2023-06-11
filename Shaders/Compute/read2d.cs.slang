RWTexture2D<float4> tex1;
RWTexture2D<float4> tex2;
RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;
RWStructuredBuffer<float4> posdata;


cbuffer csCb
{
    int res;
};


[numthreads(8, 8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xy >= float2(res)))
        return;

    float4 index = posdata[threadId.x * res + threadId.y];

    tex1[index.xy] = data1[threadId.x * res  + threadId.y];
    tex2[index.xy] = data2[threadId.x * res + threadId.y];
}

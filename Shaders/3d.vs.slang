struct vsOut
{
    float4 pos : SV_POSITION;
    float3 col : COLOR;
    float3 pixelpos : POSITION;
};

struct vsIn
{
    float3 pos : POSITION;
    float3 col : COLOR;
};

cbuffer vsCb
{
    float4x4 viewproj;
    float4x4 model;
    bool box;
};


vsOut main(vsIn input)
{
    vsOut output;
    if (!box)
    {
        output.pos = float4(input.pos, 1);
        output.col = input.col;
        output.pixelpos = input.pos;
    }
    else
    {
        float3 p = mul(float4(input.pos, 1), model).xyz;
        output.pos = mul(float4(p, 1), viewproj);
        output.col = input.col;
        output.pixelpos = p;
    }
    return output;
}

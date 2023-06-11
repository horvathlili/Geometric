struct vsOut
{
    float4 pos : SV_POSITION;
    float3 col : COLOR;
    float2 pixelpos : POSITION;
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
   
    output.pos = float4(input.pos, 1);
    output.col = input.col;
    output.pixelpos = input.pos.xy * 0.5 + 0.5;
    return output;
}


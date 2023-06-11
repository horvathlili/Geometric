#include "Utils/includes2d.slang"
#include "SDF/sdf2d.slang"
struct psIn
{
    float4 pos : SV_POSITION;
    float3 col : COLOR;
    float2 pixelpos : POSITION;
};

struct PsOut
{
    float4 col : SV_TARGET;
    
};



PsOut main(psIn input) : SV_TARGET
{
    PsOut o;


    float d = filter(input.pixelpos.xy);
    int a = (d > 0) ? 1 : 0;
       
    o.col = float4(a, a, a, 1);

    if (debug)
    {
        
        float3 col = (a > 0.0) ? float3(0.9, 0.6, 0.3) : float3(0.65, 0.85, 1.0);
        col *=1.0 - exp(-6.0 * abs(d));
    col *= 0.8 + 0.2 * cos(150.0 * d);
    col = lerp(col, float3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

       
        

        

       

    o.col = float4(col, 1);
    }
    return o;
}

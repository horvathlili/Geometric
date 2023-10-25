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

    float2 pp = (input.pixelpos.xy- float2(0.25,0.1)) * float2(2, 1.125);
    float d = filter(pp);
    int a = (d > 0) ? 0 : 1;
    if (abs(pp.x) >= 1 || abs(pp.y) >= 1 || pp.y < 0 || pp.x<0) 
    {
        o.col = float4(1, 1, 1, 1);
    }
    else
    {
       // float d = filter(pp);
       



     

        
        o.col = float4(a,a,a, 1);
        
    }

    

    if (debug)
    {
        
        float3 col = (a > 0.0) ? float3(0.9, 0.6, 0.3) : float3(0.65, 0.85, 1.0);
        col *=1.0 - exp(-6.0 * abs(d));
    col *= 0.8 + 0.2 * cos(150.0 * d);
    col = lerp(col, float3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

       
        

        

       




        float2 p =  float2(dx, dy);
       
        int2 uv = p * int2(res - 1);
       // p *=   float2(2, 1.125);

        float4 color = float4(0, 0, 0, 0);

       color += (debugplane(pp, p, 0) * float4(0.25, 0, 0, 1));
        float2 fp0 = texture1[uv].xy;
        color += (debugplane(pp,p, 1) * float4(0, 0.25, 0, 1));
        float2 fp1 = texture1[uv + float2(1, 0)].xy;
        color += (debugplane(pp,p, 2) * float4(0, 0, 0.25, 1));
        float2 fp2 = texture1[uv + float2(1, 1)].xy;
        color += (debugplane(pp,p, 3) * float4(0.25, 0.25, 0.25, 1));
        float2 fp3 = texture1[uv + float2(0, 1)].xy;
        
        if (o.col.r == 1)
        {
            
            if (color.a != 0)
            {
                o.col = 0.5 * color;
            }
        }
        else
        {
            o.col = color;
        }

        float2 pp2 = (pp - 0.5) * boundingBox;
        
        if (length(pp- p) < 0.01)
        {
            o.col = float4(1, 0, 0, 1);
        }

        if (length(pp2 - fp0) < 0.01)
        {
            o.col = float4(1, 0, 0, 1);
        }

        if (length(pp2 - fp1) < 0.01)
        {
            o.col = float4(0, 1, 0, 1);
        }
        if (length(pp2 - fp2) < 0.01)
        {
            o.col = float4(0, 0, 1, 1);
        }
        if (length(pp2 - fp3) < 0.01)
        {
            o.col = float4(1, 1, 1, 1);
        }
        o.col = float4(col, 1);
    }
    return o;
}

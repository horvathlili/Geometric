#include "Utils/includes.slang"

struct psIn
{
    float4 pos : SV_POSITION;
    float3 col : COLOR;
    float3 pixelpos : POSITION;
};

struct PsOut
{
    float4 col : SV_TARGET;
    float depth : SV_Depth;
};

PsOut main(psIn input) : SV_TARGET
{
    PsOut o;

    float4 hitpos = sphereTrace(input.pixelpos);
   
    if (hitpos.w == 1)
    {
        o.col = float4(1, 1, 1, 1);
    }
    else
    {

        float3 La = float3(0.4, 0.4, 0.4);
        float3 Ld = float3(0.8, 0.8, 0.8);
        
        float3 Ka = float3(0.2, 0.4, 0.6);
        float3 Kd = float3(0.8, 0.8, 0.8);
            
        float3 light_dir = float3(-1, -1, -1);
        
        float3 ambient = La * Ka;
        float3 diffuse = clamp(dot(normalize(-light_dir), normalize(getNormal_filter(hitpos.xyz))), 0, 1) * Ld * Kd;

        o.col = float4(ambient + diffuse, 1);

    }

    if (debugging)
    {
        Ray r;
        if (!box)
        {
            r = getRay(eye.xyz, center.xyz, up.xyz, ar, input.pixelpos.x, input.pixelpos.y);
        }
        else
        {
            r.v = normalize(input.pixelpos - eye.xyz);
            r.p = input.pixelpos + 0.001 * r.v;
        
        }
        float t = 0.0f;
        int i;
        float h;
        int n = 100;
        float3 pos = r.p + t * r.v;
   
        for (i = 0; i < n; i++)
        {
            pos = r.p + t * r.v;

            h = debug(pos,debugpos).w;
        
            if (h < 0.0001 || isOutOfBox(pos))
                break;
            t += h;
        }

        float3 hitpos2 = r.p + t * r.v;
        float3 fp = debug(hitpos2, debugpos).xyz;
        
        if (i >= n || isOutOfBox(pos))
        {
            o.col += float4(0, 0, 0, 1);
        }
        else
        {
            if (length(eye.xyz - hitpos.xyz) > length(eye.xyz - hitpos2))
            {
                if (o.col.r == 1 && o.col.g == 1 && o.col.b == 1)
                {
                    o.col = float4(0.1, 0.1, 0.5, 1);
                }
                else
                {
                    o.col += float4(0, 0, 0.5, 1);
                }

                
            }
          
            if (dot(r.v, normalize(float3(fp - r.p))) > 0.9999)
            {
                o.col = float4(1,0,0, 1);
            }
        }
    }
  
    return o;
}

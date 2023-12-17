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


float4 debug1(float a,float d)
{
    float3 col = (a > 0.0) ? float3(0.9, 0.6, 0.3) : float3(0.65, 0.85, 1.0);
    col *= 1.0 - exp(-6.0 * abs(d));
    col *= 0.8 + 0.2 * cos(150.0 * d);
    col = lerp(col, float3(1.0), 1.0 - smoothstep(0.0, 0.01, abs(d)));

    return float4(col, 1);
   
}

/*float4 debug2(float2 pp,float  a)
{
    float2 p = float2(dx, dy);
       
    int2 uv = p * int2(res - 1);
    
    float4 color = float4(0, 0, 0, 0);

    float4 col = float4(a,a,a, 1);
    
    color += (debugplane(pp, p, 0) * float4(0.25, 0, 0, 1));
    float2 fp0 = texture1[uv].xy;
    color += (debugplane(pp, p, 1) * float4(0, 0.25, 0, 1));
    float2 fp1 = texture1[uv + float2(1, 0)].xy;
    color += (debugplane(pp, p, 2) * float4(0, 0, 0.25, 1));
    float2 fp2 = texture1[uv + float2(1, 1)].xy;
    color += (debugplane(pp, p, 3) * float4(0.25, 0.25, 0.25, 1));
    float2 fp3 = texture1[uv + float2(0, 1)].xy;
        
    if (col.r == 1)
    {
            
        if (color.a != 0)
        {
            col = 0.5 * color;
        }
    }
    else
    {
        col = color;
    }

    float2 pp2 = (pp - 0.5) * boundingBox;
        
    if (length(pp - p) < 0.01)
    {
        col = float4(1, 0, 0, 1);
    }

    if (length(pp2 - fp0) < 0.01)
    {
        col = float4(1, 0, 0, 1);
    }

    if (length(pp2 - fp1) < 0.01)
    {
        col = float4(0, 1, 0, 1);
    }
    if (length(pp2 - fp2) < 0.01)
    {
        col = float4(0, 0, 1, 1);
    }
    if (length(pp2 - fp3) < 0.01)
    {
        col = float4(1, 1, 1, 1);
    }

    return col;
}
    
*/
float3 inter(float2 pos)
{
    int l = (int) floor(pos.x);
    int b = (int) floor(pos.y);
    int r = l + 1;
    int t = b + 1;
    double lr = pos.x - l;
    double bt = pos.y - b;
    l = clamp(l,0, 32 - 1), r = clamp(r,0, 32 - 1);
    b = clamp(b,0,32 - 1), t = clamp(t,0, 32 - 1);
 

    return lerp(lerp(msdftexture[l][b], msdftexture[r][b], lr), lerp(msdftexture[l][t], msdftexture[r][t], lr), bt);

}
float median(float r, float g, float b)
{
    return max(min(r, g), min(max(r, g), b));
}

PsOut main(psIn input) : SV_TARGET
{
    PsOut o;

    float2 pp = (input.pixelpos.xy- float2(0.25,0.1)) * float2(2, 1.125);
  
    float d = filter(pp);

    int a = (d > 0) ? 1 : 0;

    a = (float) (d > 0);
    if (abs(pp.x) >= 1 || abs(pp.y) >= 1 || pp.y < 0 || pp.x<0) 
    {
        o.col = float4(1, 1, 1, 1);

       
      
    }
    else
    {
        o.col = float4(a,a,a, 1);

       

        if (debug)
        {
            float2 ppos = (pp - 0.5) * boundingBox;
          o.col =debug1(a,d);
         //   o.col = float4(float3(map(ppos) - filter(pp))*10, 1);

        }

        if (originalsdf)
        {

            float2 ppos = (pp - 0.5) * boundingBox;
            a = map(ppos) > 0 ? 0: 1;
            o.col = float4(a, a, a, 1);
        }
    }
    return o;
}

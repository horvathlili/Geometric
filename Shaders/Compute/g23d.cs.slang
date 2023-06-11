#include "../SDF/sdf3d.slang"
#include "../Utils/Ray.slang"

#ifndef NUMBER
#define NUMBER 5
#endif

RWTexture3D<float4> texfpr;
RWTexture3D<float4> texdR;
RWTexture3D<float4> texn;
RWStructuredBuffer<float> x0;
RWStructuredBuffer<float4> data1;
RWStructuredBuffer<float4> data2;
RWStructuredBuffer<float4> data3;
RWStructuredBuffer<float4> posdata;

cbuffer csCb
{
    int sdf;
    int res;
    float boundingBox;
    float finegridsize;
    int finegridres;
};


bool IsNaN(float x)
{
    return (asuint(x) & 0x7fffffff) > 0x7f800000;
}

[numthreads(8, 8,8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    if (any(threadId.xyz >= float3(res)))
        return;
    
    float3 pos = float3(-(float) boundingBox / 2.0);
    pos.x += (float) boundingBox / (float) res * (threadId.x + 0.5);
    pos.y += (float) boundingBox / (float) res * (threadId.y + 0.5);
    pos.z += (float) boundingBox / (float) res * (threadId.z + 0.5);


    //calculate footpoint and normal at footpoint
    float3 n, fp;
    
    n = getNormal(pos);
    fp = pos - map(pos) * n;

    int s = 0;
    while (abs(map(fp)) > 0.00001 && s < 40)
    {
        n = getNormal(fp);
        fp = fp - n * map(fp);
        s++;
    }
    n = getNormal(fp);

    //inside
    bool inside = map(pos) < 0;

    //calculate local base
    float3 b1, b2;
    
    if (n.z < -0.999999999f) // Handle the singularity
    {
        b1 = float3(0.0f, -1.0f, 0.0f);
        b2 = float3(-1.0f, 0.0f, 0.0f);
    }
    else
    {
        const float a = 1.0f / (1.0f + n.z);
        const float b = -n.x * n.y * a;
        b1 = normalize(float3(1.0f - n.x * n.x * a, b, -n.x));
        b2 = normalize(float3(b, 1.0f - n.y * n.y * a, -n.y));
    }

    //calculate f (first get points and normal on the fine grid)

    
    float step = finegridsize / (float) finegridres / 2.0f;
    int number = finegridres * 2 + 1;
    
    float f[NUMBER*NUMBER*3];
    
    for (int i = -finegridres; i <= finegridres; i++)
    {
        for (int j = -finegridres; j <= finegridres; j++)
        {
            //point on the fine grid
            float3 pp = fp + b1 * (float) i * step + b2 * (float) j * step;

            //projecting the point to the surface
            float3 n_i, pp_i;

            Ray r;
            r.p = pp;
            r.v = -n;

            float t = 0.0f;
            float h;
            int k = 100;
           
            for (int i = 0; i < k; i++)
            {
                pp_i = r.p + t * r.v;
       
                h = map(pp_i);
        
                if (abs(h) < 0.000001 || h > 2)
                    break;
                
                t += h;
            }
            
            pp_i = r.p + t * r.v;
            n_i = getNormal(pp_i);
            
            //converting to local base
            float3 localp = float3(dot(pp_i - fp, b1), dot(pp_i - fp, b2), dot(pp_i - fp, n));
            float3 localn = float3(dot(n_i, b1), dot(n_i, b2), dot(n_i, n));

            //writing the data to f
            f[((i + finegridres) * number + (j + finegridres)) * 3] = localp.z;
            f[((i + finegridres) * number + (j + finegridres)) * 3 + 1] = -localn.x / localn.z;
            f[((i + finegridres) * number + (j + finegridres)) * 3 + 2] = -localn.y / localn.z;

        }
    }

    //result array x = (A,B,C,D,E,F,G)
    float x[7];

    for (int l = 0; l < 7; l++)
    {
       float xx = 0;
        for (int j = 0; j < number*number*3; j++)
        {
           xx += x0[l * number*number* 3 + j] * f[j];
        }
        x[l] = xx;
    }

    //calculate curvatures
   float A = x[0] ;
    float B = x[1];
    float C = x[2];

    float r, R;

   

    float D = sqrt(max(0, (A + C) * (A + C) - 4 * (A * C - B * B)));

    R = 0.5f * ((A + C) - D);
    r = 0.5f * ((A + C) + D);
    
    if (abs(R) > abs(r))
    {
        R = 0.5f * ((A + C) + D);
        r = 0.5f * ((A + C) - D);
    }   

    float lambda = r;
    
    
    float2 axis = float2(1, (A - lambda) / -B);
    float3 d = normalize(axis.x * b1 + axis.y * b2);

    
     

    int datai = threadId.x * res * res + threadId.y * res + threadId.z;
  
    texfpr[threadId.xyz] = float4(fp, r);
    data1[datai] = float4(fp, r);
    texdR[threadId.xyz] = float4(d,R);
    data2[datai] = float4(d, R);
    texn[threadId.xyz] = float4(n, 1);
    data3[datai] = float4(n, 1);
    posdata[datai] = float4(threadId.xyz, 1);
}

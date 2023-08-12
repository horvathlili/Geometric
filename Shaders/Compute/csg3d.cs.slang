
Texture3D texture1;
Texture3D texture2;
RWStructuredBuffer<float>csg;
RWStructuredBuffer<float> csg2;

cbuffer csCb
{ 
    int res;
};

float sdSphere(float3 p, float s)
{
    return length(p) - s;
}

float sdPlane(float3 p, float3 n, float3 x)
{
  // n must be normalized
    float h = -dot(n, x);
    return dot(p, n) + h;
}

float getcsg(float3 fp1, float3 fp2, float3 n1, float3 n2)
{
    
    if (sdPlane(fp1, n2, fp2) <= 0)
    {
        return 0;
    }
    else
    {

        if (sdPlane(fp1, n2, fp2) == 0)
        {
                   
            if (dot(n1, n2) > 0)
            {
                return 0;
            }
            else
            {
                return 1;
            }
                    
        }
        else
        {
            return 1;
        }
    }


      
       
}



[numthreads(8, 8,8)]
void main(uint3 threadId : SV_DispatchThreadID)
{
    float3 uvw = threadId.xyz; 


    //alsó 4 csúcs
    float3 fp[8];
    float3 n[8];
    fp[0] = texture1[uvw].xyz;
    n[0] = texture2[uvw].xyz;
    fp[1] = texture1[uvw + float3(1, 0, 0)].xyz;
    n[1] = texture2[uvw + float3(1, 0, 0)].xyz;
    fp[2] = texture1[uvw + float3(1, 0, 1)].xyz;
    n[2] = texture2[uvw + float3(1, 0, 1)].xyz;
    fp[3] = texture1[uvw + float3(0, 0, 1)].xyz;
    n[3] = texture2[uvw + float3(0, 0, 1)].xyz;


    //felső 4 csúcs
    fp[4] = texture1[uvw + float3(0, 1, 0)].xyz;
    n[4] = texture2[uvw + float3(0, 1, 0)].xyz;
    fp[5] = texture1[uvw + float3(1, 1, 0)].xyz;
    n[5] = texture2[uvw + float3(1, 1, 0)].xyz;
    fp[6] = texture1[uvw + float3(1, 1, 1)].xyz;
    n[6] = texture2[uvw + float3(1, 1, 1)].xyz;
    fp[7] = texture1[uvw + float3(0, 1, 1)].xyz;
    n[7] = texture2[uvw + float3(0, 1, 1)].xyz;

   

    float3 c[8];
    float3 s[8];

    float cs[8];

    int cc = 0;

    for (int i = 0; i < 8; i++)
    {
        if (i < 4)
        {
            s[i].x = (i + 1) % 4;
            s[i].y = (i + 3) % 4;
            s[i].z = i+4;
        }
        else
        {
            s[i].x = (i + 1) % 4 + 4;
            s[i].y = (i + 3) % 4 + 4;
            s[i].z = i - 4;
        }

        c[i].x = getcsg(fp[(int) i], fp[(int) s[i].x], n[i], n[(int) s[i].x]);
        c[i].y = getcsg(fp[(int) i], fp[(int)s[i].y], n[i], n[(int) s[i].y]);
        c[i].z = getcsg(fp[i], fp[(int) s[i].z], n[i], n[(int) s[i].z]);

        cs[i] = c[i].x + c[i].y + c[i].z;
        cc = cc + c[i].x + c[i].y + c[i].z;
    }

    
    int datai = threadId.x * res * res + threadId.y * res + threadId.z;

    csg[datai] = cc/2;
    csg2[datai] = 0;

    cc = cc / 2;
    
    if (cc > 6)
    {
        for (int i = 0; i < 8; i++)
        {
            cs[i] = 3 - cs[i];
        }
            cc = 12 - cc;
    }

    if (cc == 2)
    {
        bool b = false;
        //egybe van a kettő
        for (int i = 0; i < 8; i++)
        {
            if (cs[i] == 2)
            {
                b = true;
            }
        }

        csg2[datai] = 2;
        if (b)
        {
            csg2[datai] = 1;
        }

    }

    if (cc == 3)
    {
        bool b = false;
        int b2 = 0;
        //egybe van a kettő
        for (int i = 0; i < 8; i++)
        {
            if (cs[i] == 3)
            {
                b = true;
            }

            if (cs[i] == 2)
            {
                b2++;
            }
        }

        csg2[datai] = 4;
        if (b)
        {
            csg2[datai] = 1; //egy csúcsból
        }

        if (b2 == 2)
        {
            csg2[datai] = 2; //csíkban
        }

        if (b2 == 1)
        {
            csg2[datai] = 3; //2+1
        }

    }

    if (cc == 4)
    {
        bool b = false;
        int b2 = 0;
        int b1 = 0;
        //egybe van a kettő
        for (int i = 0; i < 8; i++)
        {
            if (cs[i] == 3)
            {
                b = true;
            }

            if (cs[i] == 2)
            {
                b2++;
            }

            if (cs[i] == 1)
            {
                b1++;
            }
            
        }

        csg2[datai] = 7; // külön
        if (b && b2 == 0)
        {
            csg2[datai] = 1; //egy csúcsból + 1
        }
        if (b && b2 == 1)
        {
            csg2[datai] = 2; //egy csúcsból 
        }

        if (b2 == 4)
        {
            csg2[datai] = 3; //négyzet
        }

        if (b2 == 3)
        {
            csg2[datai] = 4; //csík
        }

        if (b2 == 2)
        {
            csg2[datai] = 5; //csík+1 vagy 2+2
        }

        if (b2 == 1 && b1 == 6)
        {
            csg2[datai] = 6; //2+1+1
        }

        

    }
}

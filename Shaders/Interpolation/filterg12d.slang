#ifndef INTERP
#define INTERP 0
#endif

static float2 fps[4];
static float2 ns[4];

float2 fpfrom8bit(float2 fp)
{
    float2 fp1 = 2.f * fpmax * (fp - 0.5);
 
    return fp1;
}
float nfrom8bit(float n)
{
    float n1 = 4 * (n - 0.5);
    return n1;
}

float2 getn(float2 fp, float2 uv)
{
    float2 fp = texture2[uv].xy;
    float n = texture2[uv].z;

    if (bit == 8)
    {
    
        fp = fpfrom8bit(fp);
        n = nfrom8bit(n);
    }

    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 nn = t - fp;

    if (n < 0)
    {
        nn *= -1;
    }

    return nn;
}

float2 getn2(float2 fp, float n, float2 uv)
{
  
    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 nn = t - fp;

    if (n < 0)
    {
        nn *= -1;
    }

    return nn;
}

float2 getfp(float dm, float2 n, float2 uv)
{
    float2 t = float2(-boundingBox / 2.0) + (uv + 0.5f) * boundingBox / (float2) res;

    float2 fp = t - dm * normalize(n);

    return fp;
}


float sdLine(float2 p, float2 fp, float2 n)
{

    
    return dot(p - fp, n);
    
}

float noInterp(float2 p)
{
    int2 uv = p * (res);

    float2 fp = texture2[uv].xx;
    float2 n = texture2[uv].zw;

    /*if (bit == 8)
    {
        n = nfrom8bit(n);
        fp = fpfrom8bit(fp);
    }*/

    fp = getfp(fp.x, n, uv);

    

    float2 pp = (p - 0.5) * boundingBox;

    return sdLine(pp, fp, normalize(n));
}


float csgDist(float2 pp, int i, int2 uv)
{
    float2 fp = fps[i].xy;
    float2 n = ns[i];

  
   /* if (bit == 8)
    {
    
        fp = fpfrom8bit(fp);
        n = nfrom8bit(n);

    }*/

    fp = getfp(fp.x, n, uv);
    
   
  
    return sdLine(pp, fp, normalize(n));
}

float bilinear(float2 p)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);
    
    float2 fp, n;
    fp = texture2[uv].xy;
    n = texture2[uv].zw;
    fp = getfp(fp.x, n, uv);
    float d1 = sdLine(pos, fp, normalize(n));
    
    fp = texture2[uv + float2(1, 0)].xy;
    n = texture2[uv + float2(1, 0)].zw;
    fp = getfp(fp.x, n, uv + float2(1, 0));
    float d2 = sdLine(pos, fp, normalize(n));;
    
    fp = texture2[uv + float2(0, 1)].xy;
    n = texture2[uv + float2(0, 1)].zw;
 
    fp = getfp(fp.x, n, uv + float2(0, 1));
    float d3 = sdLine(pos, fp, normalize(n));;
    
    fp = texture2[uv + float2(1, 1)].xy;
    n = texture2[uv + float2(1, 1)].zw;
 
    fp = getfp(fp.x, n, uv + float2(1, 1));
    float d4 = sdLine(pos, fp, normalize(n));;

    

    float d11 = lerp(d1, d2, ab.x);
    float d22 = lerp(d3, d4, ab.x);

    
    return lerp(d11, d22, ab.y);
}



float csg(float2 p, bool points)
{

    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (p - 0.5) * boundingBox;
    float2 ab = (fuv - uv);

    fps[0] = texture2[uv].xy;
    ns[0] = texture2[uv].zw;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].zw;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].zw;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].zw;

   
   
    float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(1, 1), uv + float2(0, 1) };

    float result = 0;

    float c[6], cd[4];

    float4 cc = textureCSG[uv];
    

    for (int i = 0; i < 4; i++)
    {
        cd[i] = csgDist(pos, i, uvs[i]);
    }

    int tree, op[3], geom[4];
    
    tree = int(cc.r / 10);
    geom[0] = cc.r % 10;

    op[0] = int(cc.g / 10);
    geom[1] = cc.g % 10;

    op[1] = int(cc.b / 10);
    geom[2] = cc.b % 10;
    op[2] = int(cc.a / 10);
    geom[3] = cc.a % 10;

    
    if (tree == 0)
    {

        float d1, d2;
        if (op[0] == 0)
        {
            d1 = max(cd[geom[0]], cd[geom[1]]);
        }
        else
        {
            d1 = min(cd[geom[0]], cd[geom[1]]);
        }
        if (op[2] == 0)
        {
            d2 = max(cd[geom[2]], cd[geom[3]]);
        }
        else
        {
            d2 = min(cd[geom[2]], cd[geom[3]]);
        }

        if (op[1] == 0)
        {
            return max(d1, d2);
        }
        else
        {
            return min(d1, d2);
        }
    }
    else
    {
        float d;

        if (op[0] == 0)
        {
            d = max(cd[geom[0]], cd[geom[1]]);
        }
        else
        {
            d = min(cd[geom[0]], cd[geom[1]]);
        }
        if (op[1] == 0)
        {
            d = max(d, cd[geom[2]]);
        }
        else
        {
            d = min(d, cd[geom[2]]);
        }
        if (op[2] == 0)
        {
            d = max(d, cd[geom[3]]);
        }
        else
        {
            d = min(d, cd[geom[3]]);
        }
        return d;
    }
    
   
  
    int csum = c[0] + c[1] + c[2] + c[3];

   
    
   //return csg2(uv, pos);

    
    return result;
}



float filter(float2 p)
{
#if INTERP == 0
    return noInterp(p);
#endif
#if INTERP == 1
    return bilinear(p);
#endif
#if INTERP == 2
    return csg(p,true);
#endif
#if INTERP == 3
    return csg(p,false);
#endif

    return 0.0f;
}


float debugplane(float2 pp, float2 p, int i)
{
    float2 fuv = clamp(p * (float(res)) - 0.5, 0, float(res) - 1);
    int2 uv = clamp(fuv, 0, res - 2);
    float2 pos = (pp - 0.5) * boundingBox;
   
    
    //float2 uvs[4] = { uv + float2(0, 0), uv + float2(1, 0), uv + float2(0, 1), uv + float2(1, 1) };

    /*fps[0] = texture2[uv].xy;
    ns[0] = texture2[uv].zw;
   
    fps[1] = texture2[uv + float2(1, 0)].xy;
    ns[1] = texture2[uv + float2(1, 0)].zw;
   
    fps[2] = texture2[uv + float2(1, 1)].xy;
    ns[2] = texture2[uv + float2(1, 1)].zw;
   
    fps[3] = texture2[uv + float2(0, 1)].xy;
    ns[3] = texture2[uv + float2(0, 1)].zw;
    
    float2 fp = fps[i].xy;
    float2 n = ns[i];*/

    return 0;
    //return sdLine(pos, fp, normalize(n)) < 0 ? 1 : 0;

   
}

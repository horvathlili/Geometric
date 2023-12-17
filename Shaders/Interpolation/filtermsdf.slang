
float filter(float2 pp)
{
    float4 te = msdftexture.Sample(mSampler, pp);
    //te = msdftexture[pp * 5000];
    return  (te.x -0.5) ;
}

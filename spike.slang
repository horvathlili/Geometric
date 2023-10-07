/*
Copyright 2013 @Patapom
License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Link: https://www.shadertoy.com/view/lds3WH
*/

/******************************************************************************
 This work is a derivative of work by Patapom used under CC BY-NC-SA 3.0.
 This work is licensed also under CC BY-NC-SA 3.0 by NVIDIA CORPORATION.
 ******************************************************************************/

#ifndef spike_glsl
#define spike_glsl

float spikeball(float3 p)
{
    float3 c[19];
    c[0] = float3(1, 0, 0);
    c[1] = float3(0, 1, 0);
    c[2] = float3(0, 0, 1);
    c[3] = float3(.577, .577, .577);
    c[4] = float3(-.577, .577, .577);
    c[5] = float3(.577, -.577, .577);
    c[6] = float3(.577, .577, -.577);
    c[7] = float3(0, .357, .934);
    c[8] = float3(0, -.357, .934);
    c[9] = float3(.934, 0, .357);
    c[10] = float3(-.934, 0, .357);
    c[11] = float3(.357, .934, 0);
    c[12] = float3(-.357, .934, 0);
    c[13] = float3(0, .851, .526);
    c[14] = float3(0, -.851, .526);
    c[15] = float3(.526, 0, .851);
    c[16] = float3(-.526, 0, .851);
    c[17] = float3(.851, .526, 0);
    c[18] = float3(-.851, .526, 0);

    float MinDistance = 1e4;
    for (int i = 3; i < 19; i++)
    {
        float d = clamp(dot(p, c[i]), -1.0, 1.0);
        float3 proj = d * c[i];
        d = abs(d);
		
        float Distance2Spike = length(p - proj);
        float SpikeThickness = 0.25 * exp(-5.0 * d) + 0.0;
        float Distance = Distance2Spike - SpikeThickness;
		
        MinDistance = min(MinDistance, Distance);
    }
	
    return MinDistance;
}

float spikesdf(float3 p)
{
    return spikeball(p);
}

#endif



float2 Bezier2(float2 B0, float2 B1, float2 B2, float t)
{
    float s = 1.0 - t;
    return s * s * B0 + 2.0 * s * t * B1 + t * t * B2;
}

float2 Bezier2Diff(float2 B0, float2 B1, float2 B2, float t)
{
    return (2.0 * t - 2.0) * B0 + (2.0 - 4.0 * t) * B1 + 2.0 * t * B2;
}

float2 Bezier2Diff2(float2 B0, float2 B1, float2 B2)
{
    return 2.0 * B0 - 4.0 * B1 + 2.0 * B2;
}

float Bezier2Curvature(float2 B0, float2 B1, float2 B2, float t)
{
    float2 v = Bezier2Diff(B0, B1, B2, t);
    float2 n = normalize(float2(-v.y, v.x));
    float y2 = dot(Bezier2Diff2(B0, B1, B2), n);
    return y2 / dot(v, v);
}

// iq's sdfBezier (modified for foot points and added special case)
float Bezier2FootT(float2 A, float2 B, float2 C, float2 pos)
{
    float2 a = B - A;
    float2 b = A - 2.0 * B + C;
    float2 c = a * 2.0;
    float2 d = A - pos;

    float bb = dot(b, b);
    if (bb < 0.0001)
    {
        // the control point is exactly in the middle between the two ends
        float2 D = C - A;
        float t = dot(D, pos - A) / dot(D, D);
        return clamp(t, 0.0, 1.0);
    }
    float kk = 1.0 / bb;
    float kx = kk * dot(a, b);
    float ky = kk * (2.0 * dot(a, a) + dot(d, b)) / 3.0;
    float kz = kk * dot(d, a);

    float rest = 0.0;

    float p = ky - kx * kx;
    float p3 = p * p * p;
    float q = kx * (2.0 * kx * kx - 3.0 * ky) + kz;
    float h = q * q + 4.0 * p3;

    if (h >= 0.0)
    {
        h = sqrt(h);
        float2 x = (float2(h, -h) - q) / 2.0;
        float2 uv = sign(x) * pow(abs(x), float2(1.0 / 3.0));
        float t = uv.x + uv.y - kx;
        rest = clamp(t, 0.0, 1.0);
    }
    else
    {
        float z = sqrt(-p);
        float v = acos(q / (p * z * 2.0)) / 3.0;
        float m = cos(v);
        float n = sin(v) * 1.732050808;
        float3 t = float3(m + m, -n - m, n - m) * z - kx;
        t = clamp(t, 0.0, 1.0);

        // 3 roots
        float2 qos = d + (c + b * t.x) * t.x;
        float dis = dot(qos, qos);
        rest = t.x;
        
        float mdis = dis;

        qos = d + (c + b * t.y) * t.y;
        dis = dot(qos, qos);
        if (dis < mdis)
        {
            mdis = dis;
            rest = t.y;
        }

        qos = d + (c + b * t.z) * t.z;
        dis = dot(qos, qos);
        if (dis < mdis)
        {
            mdis = dis;
            rest = t.z;
        }
    }
    
    return rest;
}

struct Ray
{
    float3 p;
    float3 v;
};

Ray getRay(float3 eye, float3 center, float3 up, float ar, float i, float j)
{
    Ray r;

    float3 w = normalize(eye - center);
    float3 u = normalize(cross(w, up));
    float3 v = normalize(cross(u, w));

    float a = tan(radians(60)) * -i / ar;
    float b = tan(radians(45)) * j / ar;
    
    float3 p = eye + (a * u + b * v - w);

    r.p = eye;
    r.v = normalize(p - eye);
    
    return r;
   
}

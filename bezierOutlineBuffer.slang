RWStructuredBuffer<int> segments;
RWStructuredBuffer<int> cn;
RWStructuredBuffer<float> controlPoints;


void getClosestSegment(in float2 P, in int glyphID, out float closestD, out float2 closest, out int closestID, out float closestT);
bool isInside(float2 P, float2 closest, int closestID, float closestT, out float2 n, out bool corner);
float2 getSegmentDiff(int segmentID, float t);
float getSegmentCurvature(int segmentID, float t);
void getSegment(in int segmentID, out float2 A, out float2 B, out float2 C);

#include "bezier.slang"
/*float2 Bezier2(float2 B0, float2 B1, float2 B2, float t);
float2 Bezier2Diff(float2 B0, float2 B1, float2 B2, float t);
float Bezier2Curvature(float2 B0, float2 B1, float2 B2, float t);
float Bezier2FootT(float2 A, float2 B, float2 C, float2 pos);*/


void getClosestSegment(in float2 P, out float closestD, out float2 closest, out int closestID, out float closestT)
{
    closestD = 100000;
    closest = float2(0, 0);
    closestID = 0;
    closestT = 0;
	
    int baseContourID = 0;
    int contourNum = cn[0];
    for (int contI = 0; contI < contourNum; ++contI)
    {
        int contourID = baseContourID + contI;
        int baseSegmentID = segments[2 * contourID];
        int segmentNum = segments[2 * contourID + 1];
        for (int segI = 0; segI < segmentNum; ++segI)
        {
            int segmentID = baseSegmentID + segI;
            float2 A, B, C;
            getSegment(segmentID, A, B, C);

            float closeT = Bezier2FootT(A, B, C, P);
            float2 close = Bezier2(A, B, C, closeT);
            float d = length(close - P);
            if (d < closestD)
            {
                closestD = d;
                closest = close;
                closestID = segmentID;
                closestT = closeT;
            }
        }
    }
}

bool isInside(float2 P, float2 closest, int closestID, float closestT, out float2 n, out bool corner)
{
    float2 v = getSegmentDiff(closestID, closestT);
    n = float2(-v.y, v.x);
    corner = false;
    bool inside = dot(closest - P, n) >= 0.0;
    if (closestT == 0.0 || closestT == 1.0)
    {
        int id2 = closestT == 0.0 ? closestID - 1 : closestID + 1;
        float2 v2 = getSegmentDiff(id2, 1 - closestT);
        corner = (abs(dot(normalize(n), normalize(v2))) > 0.01);
        float2 n2 = float2(-v2.y, v2.x);
        bool inside2 = dot(closest - P, n2) >= 0.0;
        float cosa = dot(v, n2);
        inside = (closestT == 0.0 ? cosa < 0 : cosa > 0) ?
			inside && inside2 :
			inside || inside2;
    }
    float2 footVector = P - closest;
    float len = length(footVector);
    if (len > 0.001)
        n = footVector / len * (inside ? -1 : 1);
    else
        n = normalize(n);
    return inside;
}

float2 getSegmentDiff(int segmentID, float t)
{
    float2 A, B, C;
    getSegment(segmentID, A, B, C);
    return Bezier2Diff(A, B, C, t);
}

float getSegmentCurvature(int segmentID, float t)
{
    float2 A, B, C;
    getSegment(segmentID, A, B, C);
    return Bezier2Curvature(A, B, C, t);
}

void getSegment(in int segmentID, out float2 A, out float2 B, out float2 C)
{
    A = float2(controlPoints[6 * segmentID + 0], controlPoints[6 * segmentID + 1]);
    B = float2(controlPoints[6 * segmentID + 2], controlPoints[6 * segmentID + 3]);
    C = float2(controlPoints[6 * segmentID + 4], controlPoints[6 * segmentID + 5]);
}

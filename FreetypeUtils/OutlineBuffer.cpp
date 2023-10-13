#include "OutlineBuffer.h"


struct ContourPointer { int ptr; int num; };
struct SegmentPointer { int ptr; int num; };
struct Segment { Falcor::float2 A, B, C; };

static void pushSegmentToBuffer(const Outline::Segment&, std::vector<Segment>&, float bw, float bh);

void OutlineBuffer::initBuffers(std::string text, float bw, float bh)
{
	std::vector<SegmentPointer> segmentPointerBufferVec; // indexes into segmentBuffer
	std::vector<Segment> segmentBufferVec;


    std::string fontFile = "FreetypeUtils/Assets/wmanimals2.ttf";

    FTW_Library lib;
    FTW_Face face;

    face.LoadFace(lib, fontFile.c_str());
    face.SetSize(20);
    face.PreloadAllGlyphs();

    const int lineheight = FT_Face(face)->size->metrics.height >> 6;
    TextLayout textGlyphs = BuildTextLayout(face, text, 1000, lineheight);


    OutlineCache oc;
    oc.AddAll(face); 
 


    float fw = (float)(FT_Face(face)->glyph->metrics.width >> 6);
    float fh = (float)(FT_Face(face)->glyph->metrics.height >> 6);

	for (auto& g : textGlyphs) {
		

		auto& contours = oc.Get(g.glyphIndex).getContours();
		if (contours.size() == 0) continue; // glyph is not in the outline cache, todo error?

        contourNumber = (int)contours.size();
		
		for (auto& contour : contours) {
			segmentPointerBufferVec.emplace_back(SegmentPointer{ (int)segmentBufferVec.size() + 1, (int)contour.segments.size() });
			// push last segment before the outline to make tha shader simpler
			pushSegmentToBuffer(*contour.segments.rbegin(), segmentBufferVec,bw,bh);
			// push segments
			for (auto& segment : contour.segments) {
				pushSegmentToBuffer(segment, segmentBufferVec,bw,bh);
			}
			// push first segment after the outline to make tha shader simpler
			pushSegmentToBuffer(*contour.segments.begin(), segmentBufferVec,bw,bh);
		}
	}

    contours.clear(); controlPoints.clear();
    for (int i = 0; i < segmentPointerBufferVec.size(); ++i) {
        contours.push_back(segmentPointerBufferVec[i].ptr);
        contours.push_back(segmentPointerBufferVec[i].num);
    }

    for (int i = 0; i < segmentBufferVec.size(); ++i) {

        controlPoints.push_back(segmentBufferVec[i].A.x);
        controlPoints.push_back(segmentBufferVec[i].A.y);
        controlPoints.push_back(segmentBufferVec[i].B.x);
        controlPoints.push_back(segmentBufferVec[i].B.y);
        controlPoints.push_back(segmentBufferVec[i].C.x);
        controlPoints.push_back(segmentBufferVec[i].C.y);        
    }
	
}

static void pushSegmentToBuffer(const Outline::Segment& segment, std::vector<Segment>& buffer, float bw, float bh)
{
	if (segment.type == Outline::SegmentType::LINE_SEGMENT) {
		// convert line segment to Bezier2 segment
		buffer.emplace_back(Segment{ Falcor::float2(segment.p0.x-bw,segment.p0.y-bh) / 20.0f, 0.5f* Falcor::float2(segment.p0.x-2*bw+ segment.p1.x,segment.p0.y+segment.p1.y-2*bh)/20.f,Falcor::float2(segment.p1.x-bw,segment.p1.y-bh)/20.f });
	}
	else { // segment.type == Outline::BEZIER_2_SEGMENT
		buffer.emplace_back(Segment{ Falcor::float2(segment.p0.x-bw,segment.p0.y-bh)/20.f,
            Falcor::float2(segment.p1.x-bw,segment.p1.y-bh)/20.f,
            Falcor::float2(segment.p2.x-bw,segment.p2.y-bh)/20.f });
}
}

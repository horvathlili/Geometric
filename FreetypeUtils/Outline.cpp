#include "Outline.h"

// the point is on the curve (segment endpoints)
bool ON_POINT(const char tag) { return FT_CURVE_TAG(tag) == FT_CURVE_TAG_ON; }
// quadratic Bezier inner contorl point
bool BEZIER2_CTRL_POINT(const char tag) { return FT_CURVE_TAG(tag) == FT_CURVE_TAG_CONIC; }
// cubic Bezier inner contorl point
bool BEZIER3_CTRL_POINT(const char tag) { return FT_CURVE_TAG(tag) == FT_CURVE_TAG_CUBIC; }


Outline::Segment Outline::Segment::ConstructLine(vec2 p0, vec2 p1)
{
	return Outline::Segment{ Outline::SegmentType::LINE_SEGMENT, p0, p1, vec2{0,0}, vec2{0,0} };
}
Outline::Segment Outline::Segment::ConstructBezier2(vec2 p0, vec2 p1, vec2 p2)
{
	return Outline::Segment{ Outline::SegmentType::BEZIER_2_SEGMENT, p0, p1, p2, vec2{0,0} };
}
Outline::Segment Outline::Segment::ConstructBezier3(vec2 p0, vec2 p1, vec2 p2, vec2 p3)
{
	return Outline::Segment{ Outline::SegmentType::BEZIER_3_SEGMENT, p0, p1, p2, p3  };
}


Outline::Contour Pts2Contour(std::vector<vec2>& pts, std::vector<char>& tags)
{
	// see https://freetype.org/freetype2/docs/glyphs/glyphs-6.html 
	if (pts.size() != tags.size()) {
		std::cout << "error while processing contour\n";
		return {};
	}
	else if (pts.size() < 2) {
		// std::cout << "error: contour has less than 2 control points\n";
		return {};
	}
	std::vector<Outline::Segment> segments;
	size_t idx = 0;
	vec2 prevOnPt; // starting point of the next segment
	// find the first 'on' point -- prevOnPt
	// and push the last 'on' point to the end of pts (if needed)
	if (ON_POINT(tags[0])) {
		// the first point is an 'on' point
		prevOnPt = pts[0];
		idx++;
		pts.push_back(prevOnPt);
		tags.push_back(1);
	}
	else {
		// the first point is a control point
		size_t lastIdx = pts.size() - 1;
		if (ON_POINT(tags[lastIdx])) {
			// the last point is an 'on' point
			prevOnPt = pts[lastIdx];
		}
		else {
			// the last point is a control point
			prevOnPt = 0.5f * (pts[lastIdx] + pts[0]);
			pts.push_back(prevOnPt);
			tags.push_back(FT_CURVE_TAG_ON);
		}
	}
	// in every loop one segment is created (line, Bezier2, or Bezier3)
	while (idx < pts.size()) {
		if (ON_POINT(tags[idx])) {
			// line segment
			segments.emplace_back(Outline::Segment::ConstructLine(prevOnPt, pts[idx]));
			prevOnPt = pts[idx];
			idx++;
		}
		else if (BEZIER2_CTRL_POINT(tags[idx])) {
			// Bezier2 segment
			segments.emplace_back(Outline::Segment::ConstructBezier2(prevOnPt, pts[idx], vec2{ 0,0 }));
			// idx + 1 < pts.size() bc the last point is an 'on' point (and we still need the end point for this Bezier segment)
			if (ON_POINT(tags[idx + 1])) {
				prevOnPt = pts[idx + 1];
				++++idx;
			}
			else {
				// BEZIER2_CTRL_POINT(tags[idx + 1]) == true
				// if not then it is BEZIER3, which is usually not supported
				// but this should still work
				prevOnPt = 0.5f * (pts[idx] + pts[idx + 1]);
				++idx;
			}
			// set the endpoint
			segments[segments.size() - 1].p2 = prevOnPt;
		}
		else {
			// BEZIER3_CTRL_POINT(tags[idx]) == true
			// Bezier3 segment
			if (idx + 2 >= pts.size() || !BEZIER3_CTRL_POINT(tags[idx + 1]))
			{
				return {}; // we are missing the other ctrl point, this shouldn't happen
			}
			segments.emplace_back(Outline::Segment::ConstructBezier3(prevOnPt, pts[idx], pts[idx + 1], vec2{ 0,0 }));
			if (ON_POINT(tags[idx + 2])) {
				prevOnPt = pts[idx + 2];
				++++++idx;
			}
			else {
				// BEZIER3_CTRL_POINT(tags[idx + 2]) == true
				// if not then it is BEZIER2, which is usually not supported
				// but this should still work
				prevOnPt = 0.5f * (pts[idx + 1] + pts[idx + 2]);
				++++idx;
			}
			// set the endpoint
			segments[segments.size() - 1].p3 = prevOnPt;
		}
	}
	return { segments };
}

Outline::Outline(FT_OutlineGlyph outline)
{
	if (outline == nullptr) {
		std::cout << "outline is nullptr\n";
		return;
	}
	if (outline->root.format != FT_GLYPH_FORMAT_OUTLINE) {
		std::cout << "glyph is not an outline\n";
		return;
	}

	FT_Outline& Ol = outline->outline;
	int Start = 0;						//start index of contour
	int End = 0;						//end index of contour
	short* pContEnd = Ol.contours;		//pointer to contour end
	FT_Vector* pPoint = Ol.points;		//pointer to outline point
	char* pFlag = Ol.tags;				//pointer to flag

	std::vector<vec2> pts;
	std::vector<char> tags;
	contours.reserve(Ol.n_contours);
	for (int c = 0; c < Ol.n_contours; c++)
	{
		End = *pContEnd++;
		pts.clear();
		tags.clear();
		pts.reserve(End - Start + 2); // +2 because Pts2Contour adds an extra point to the end
		tags.reserve(End - Start + 2);
		for (int p = Start; p <= End; p++)
		{
			tags.push_back(*pFlag++);
			pts.push_back(1.0f / float(1 << 6) * vec2 { (float)pPoint->x, (float)pPoint->y });
			pPoint++;
		}
		Start = End + 1;
		contours.emplace_back(Pts2Contour(pts, tags));
	}
}

void OutlineCache::AddCalc(FT_UInt glyphId, FT_OutlineGlyph glyph)
{
	if (cache.find(glyphId) != cache.end()) return;
	cache.emplace(std::pair(glyphId, Outline(glyph)));
}

void OutlineCache::AddAll(const FTW_Face& face)
{
	for (auto& [glyphIndex, outlineGlyph] : face.GetGlyphMap()) {
		AddCalc(glyphIndex, outlineGlyph);
	}
}

static Outline EmptyOutline{};
const Outline& OutlineCache::Get(FT_UInt glyphId) const
{
	auto it = cache.find(glyphId);
	if (it != cache.end()) {
		return it->second;
	}
	else {
		return EmptyOutline;
	}
}

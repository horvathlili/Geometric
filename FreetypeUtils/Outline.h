#pragma once

#include <vector>
#include "FreeTypeWrapper.h"

struct vec2 {
	float x, y;
};
inline vec2 operator+(vec2 a, vec2 b) {
	return vec2{ a.x + b.x, a.y + b.y };
}
inline vec2 operator*(float a, vec2 b) {
	return vec2{ a * b.x, a * b.y };
}

class Outline {
public:
	enum class SegmentType
	{
		LINE_SEGMENT,
		BEZIER_2_SEGMENT,
		BEZIER_3_SEGMENT
	};
	struct Segment {
		Outline::SegmentType type;
		vec2 p0, p1, p2, p3;

		static Segment ConstructLine(vec2 p0, vec2 p1);
		static Segment ConstructBezier2(vec2 p0, vec2 p1, vec2 p2);
		static Segment ConstructBezier3(vec2 p0, vec2 p1, vec2 p2, vec2 p3);
	};
	struct Contour {
		std::vector<Segment> segments;
	};
private:
	std::vector<Contour> contours;
public:
	// creates an empty Outline
	Outline() {};
	// creates an Outline from an outline glyph
	Outline(FT_OutlineGlyph outline);
	// returns the contours of the stored glyph
	const std::vector<Contour>& getContours() const { return contours; }
};

class OutlineCache {
	std::map<FT_UInt, Outline> cache;
public:
	// calculates and adds an Outline of the given glyphID if it is not in the cache yet 
	void AddCalc(FT_UInt glyphId, FT_OutlineGlyph glyph);
	// calculates and adds Outlines for all glyphs of a Face
	void AddAll(const FTW_Face& face);
	// returns an outline from the cache if it is present, empty Outline otherwise
	const Outline& Get(FT_UInt glyphId) const;
	// returns the cache
	const std::map<FT_UInt, Outline>& GetCache() const { return cache; }
	// clears the cache
	void Clear() { cache.clear(); }
};

#include "WriteLayout.h"

enum class WriteMode {
	Text, Binary
};


template<WriteMode M>
class Writer {
	std::ostream& _os;
public:
	Writer(std::ostream& os) : _os(os) {}
	template<typename T>
	void WriteVal(const T& val);
};

template<>
template<typename T>
void Writer<WriteMode::Binary>::WriteVal(const T& val) {
	_os.write((char*)&val, sizeof(val));
}

template<>
template<typename T>
void Writer<WriteMode::Text>::WriteVal(const T& val) {
	_os << "\n" << val;
}

template<>
template<>
void Writer<WriteMode::Text>::WriteVal<>(const vec2& val) {
	_os << " " << val.x << " " << val.y;
}

vec2 add(vec2 a, vec2 b) { return vec2{ a.x + b.x, a.y - b.y }; }

template<WriteMode M>
void WriteLayout(std::ostream& os, const TextLayout& glyphs, const OutlineCache& oc, int pen_x, int pen_y)
{
	Writer<M> out(os);

	out.WriteVal<std::string>("glyphs");
	out.WriteVal<uint32_t>((int)glyphs.size());
	for (auto& g : glyphs) {
		vec2 p = { pen_x + (float)g.pen_x , pen_y + (float)g.pen_y };

		const auto& contours = oc.Get(g.glyphIndex).getContours();
		out.WriteVal<std::string>("contours");
		out.WriteVal<uint32_t>((int)contours.size());
		for (auto& cont : contours) {
			auto& segments = cont.segments;
			out.WriteVal<std::string>("segments");
			out.WriteVal<uint32_t>((int)segments.size());
			for (auto& seg : segments) {
				uint32_t numPoints = 
					seg.type == Outline::SegmentType::LINE_SEGMENT ? 2 :
					(seg.type == Outline::SegmentType::BEZIER_2_SEGMENT ? 3 : 4);
				out.WriteVal<uint32_t>(numPoints);
				out.WriteVal<vec2>(add(p, seg.p0));
				out.WriteVal<vec2>(add(p, seg.p1));
				if (numPoints > 2) {
					out.WriteVal<vec2>(add(p, seg.p2));
				}
				if (numPoints > 3) {
					out.WriteVal<vec2>(add(p, seg.p3));
				}
			}
		}
	}
}

void WriteLayoutAsText(std::ostream& os, const TextLayout& glyphs, const OutlineCache& oc, int pen_x, int pen_y)
{
	WriteLayout<WriteMode::Text>(os, glyphs, oc, pen_x, pen_y);
}
void WriteLayoutBinary(std::ostream& os, const TextLayout& glyphs, const OutlineCache& oc, int pen_x, int pen_y)
{
	WriteLayout<WriteMode::Binary>(os, glyphs, oc, pen_x, pen_y);
}

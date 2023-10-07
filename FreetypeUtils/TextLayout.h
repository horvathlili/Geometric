#pragma once

#include "FreeTypeWrapper.h"
#include <vector>

struct GlyphPos {
	int pen_x, pen_y;
	FT_UInt glyphIndex;
	FT_BitmapGlyph glyph;
	FT_OutlineGlyph outline;
};

using TextLayout = std::vector<GlyphPos>;
// create a layout of glyphs from a string
TextLayout BuildTextLayout(FTW_Face& face, const std::string& text, int maxWidth, int lineHeight);

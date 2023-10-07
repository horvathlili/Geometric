#include "TextLayout.h"

TextLayout BuildTextLayout(FTW_Face& face, const std::string& text, int maxWidth, int lineHeight)
{
	TextLayout chars;
	int pen_x = 0;
	int pen_y = lineHeight;
	face.ResetKern();
	for (int n = 0; n < text.length(); n++)
	{
		// line break
		if (text[n] == '\n') {
			pen_x = 0;
			pen_y += lineHeight;
			face.ResetKern();
			continue;
		}

		FT_Pos kern_x;
		FT_UInt glyph_index;
		FT_BitmapGlyph glyph = face.GetBitmapGlyph(text[n], &kern_x, &glyph_index);
		pen_x += kern_x >> 6;

		// line break if the character doesn't fit
		if (pen_x + glyph->left + int(glyph->bitmap.width) > maxWidth) {
			pen_x = 0;
			pen_y += lineHeight;
		}

		chars.push_back({ pen_x, pen_y, glyph_index, glyph, face.GetOutlineGlyph(text[n]) });

		/* increment pen position */
		pen_x += glyph->root.advance.x >> 16;
	}
	return chars;
}

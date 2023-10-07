#pragma once

#include  <freetype/ftglyph.h>
#include FT_FREETYPE_H


void Check(FT_Error ErrCode, const char* OKMsg, const char* ErrMsg);
int GetOutLine(FT_Glyph glyph, FT_OutlineGlyph* Outg);


// par1: FontName, par2:Glyph-Nr, par3: FontSize as FT_F26Dot6
int FreeTypeTest_main(int argc, char* argv[]);
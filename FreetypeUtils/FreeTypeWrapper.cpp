#include "FreeTypeWrapper.h"


void FTW_Check(FT_Error ErrCode, const char* OKMsg, const char* ErrMsg)
{
	if (ErrCode != 0)
	{
		std::cout << ErrMsg << ": " << ErrCode << "\n";
		std::cout << "program halted\n";
		exit(1);
	}
	else
		std::cout << OKMsg;
}

FTW_Library::FTW_Library() {
	FT_Error error = FT_Init_FreeType(&_library);
	FTW_Check(error, "", "error initializing FT lib");
}

FTW_Library::~FTW_Library() {
	FT_Done_FreeType(_library);
}

bool FTW_Face::LoadFace(const FTW_Library& lib, const char * fileName, FT_Long face_index) {
	if (_hasValidFace) {
		FT_Done_Face(_face);
		_glyphs.clear();
		_bitmaps.clear();
	}
	FT_Error error = FT_New_Face((FT_Library)lib, fileName, face_index, &_face);
	return _hasValidFace = error == 0;
}

bool FTW_Face::SetSize(FT_UInt charSize) {
	if (!_hasValidFace) return false;
	_glyphs.clear();
	_bitmaps.clear();
	return 0 == FT_Set_Pixel_Sizes(_face, 0, charSize);
}

void FTW_Face::_LoadGlyph(FT_UInt glyphIndex)
{
	FT_Error error = FT_Load_Glyph(_face, glyphIndex, FT_LOAD_DEFAULT);
	if (error != 0)
		std::cout << "error loading glyph\n"; // todo handle error
	FT_Glyph newGlyph;
	error = FT_Get_Glyph(_face->glyph, &newGlyph);
	if (error != 0)
		std::cout << "error getting glyph\n"; // todo handle error
	if (newGlyph->format != FT_GLYPH_FORMAT_OUTLINE)
		std::cout << "error: glyph is not an outline\n"; // todo handle error
	_glyphs.emplace(std::pair(glyphIndex, (FT_OutlineGlyph)newGlyph));
	_bitmaps.emplace(std::pair(glyphIndex, _glyphs[glyphIndex].GetAsBitmap()));
}

FT_Glyph FTW_Face::_GetGlyph(FT_ULong ch, bool bitmap, FT_Pos * kern, FT_UInt * glyphIndex)
{
	FT_UInt glyph_index = FT_Get_Char_Index(_face, ch);
	if (glyphIndex) {
		*glyphIndex = glyph_index;
	}
	if (kern) {
		FT_Vector kernV;
		FT_Get_Kerning(_face, _lastGlyph, glyph_index, FT_KERNING_DEFAULT, &kernV);
		*kern = kernV.x;
	}
	_lastGlyph = glyph_index;
	if (_glyphs.find(glyph_index) == _glyphs.end()) {
		_LoadGlyph(glyph_index);
	}
	return bitmap ? _bitmaps[glyph_index] : _glyphs[glyph_index];
}

void FTW_Face::PreloadAllGlyphs()
{
	FT_ULong  charcode;
	FT_UInt   glyph_index;

	charcode = FT_Get_First_Char(_face, &glyph_index);
	while (glyph_index != 0)
	{
		_LoadGlyph(glyph_index);
		charcode = FT_Get_Next_Char(_face, charcode, &glyph_index);
	}
}

FT_OutlineGlyph FTW_Face::GetOutlineGlyph(FT_ULong ch, FT_Pos * kern, FT_UInt * glyphIndex)
{
	return (FT_OutlineGlyph)_GetGlyph(ch, false, kern, glyphIndex);
}

FT_BitmapGlyph FTW_Face::GetBitmapGlyph(FT_ULong ch, FT_Pos * kern, FT_UInt * glyphIndex)
{
	return (FT_BitmapGlyph)_GetGlyph(ch, true, kern, glyphIndex);
}

void FTW_Face::SetPreviousChar(FT_ULong ch)
{
	_lastGlyph = FT_Get_Char_Index(_face, ch);
}

void FTW_Face::ResetKern()
{
	_lastGlyph = 0;
}

FTW_Face::~FTW_Face() {
	if (_hasValidFace)
		FT_Done_Face(_face);
}

FTW_BitmapGlyph FTW_OutlineGlyph::GetAsBitmap() const
{
	FT_Glyph img = (FT_Glyph)_glyph;
	if (img->format == FT_GLYPH_FORMAT_BITMAP) {
		FT_Glyph_Copy((FT_Glyph)_glyph, &img); // it was already a bitmap, this shouldn't occur
	}
	FT_Error error = FT_Glyph_To_Bitmap(&img, FT_RENDER_MODE_NORMAL, nullptr, 0);
	if (error != 0) std::cout << "Error converting glyph to bitmap\n"; //TODO handle error
	return FTW_BitmapGlyph((FT_BitmapGlyph)img);
}

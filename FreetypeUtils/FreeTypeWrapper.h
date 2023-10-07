#pragma once

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_GLYPH_H

#include <iostream>
#include <map>

class FTW_Library {
	FT_Library _library;

public:
	FTW_Library();
	FTW_Library(const FTW_Library&) = delete;
	FTW_Library& operator=(const FTW_Library&) = delete;
	~FTW_Library();

	explicit operator FT_Library() const { return _library; }
};

class FTW_BitmapGlyph {
	FT_BitmapGlyph _glyph;
public:
	FTW_BitmapGlyph() : _glyph(nullptr) {}
	FTW_BitmapGlyph(FT_BitmapGlyph g) : _glyph(g) {}
	FTW_BitmapGlyph(const FTW_BitmapGlyph&) = delete;
	FTW_BitmapGlyph& operator=(const FTW_BitmapGlyph&) = delete;
	FTW_BitmapGlyph(FTW_BitmapGlyph&& o) noexcept : _glyph(o._glyph) { o._glyph = nullptr; }
	FTW_BitmapGlyph& operator=(FTW_BitmapGlyph&& o) noexcept { std::swap(_glyph, o._glyph); }
	operator FT_BitmapGlyph() const { return _glyph; }
	operator FT_Glyph() const { return (FT_Glyph)_glyph; }
	~FTW_BitmapGlyph() { if (_glyph) FT_Done_Glyph((FT_Glyph)_glyph); }
};

class FTW_OutlineGlyph {
	FT_OutlineGlyph _glyph;
public:
	FTW_OutlineGlyph() : _glyph(nullptr) {}
	FTW_OutlineGlyph(FT_OutlineGlyph g) : _glyph(g) {}
	FTW_OutlineGlyph(const FTW_OutlineGlyph&) = delete;
	FTW_OutlineGlyph& operator=(const FTW_OutlineGlyph&) = delete;
	FTW_OutlineGlyph(FTW_OutlineGlyph&& o) noexcept  : _glyph(o._glyph) { o._glyph = nullptr; }
	FTW_OutlineGlyph& operator=(FTW_OutlineGlyph&& o) noexcept  { std::swap(_glyph, o._glyph); }
	operator FT_OutlineGlyph() const { return _glyph; }
	operator FT_Glyph() const { return (FT_Glyph)_glyph; }
	FTW_BitmapGlyph GetAsBitmap() const;
	~FTW_OutlineGlyph() { if (_glyph) FT_Done_Glyph((FT_Glyph)_glyph); }
};

class FTW_Face {
	FT_Face _face = nullptr;
	bool _hasValidFace = false;
	std::map<FT_UInt, FTW_OutlineGlyph> _glyphs;
	std::map<FT_UInt, FTW_BitmapGlyph> _bitmaps;
	FT_UInt _lastGlyph = 0; // for kerning

	void _LoadGlyph(FT_UInt glyphIndex);
	FT_Glyph _GetGlyph(FT_ULong ch, bool bitmap, FT_Pos* kern, FT_UInt* glyphIndex);

public:
	FTW_Face() {}
	FTW_Face(const FTW_Face&) = delete;
	FTW_Face& operator=(const FTW_Face&) = delete;

	bool LoadFace(const FTW_Library& lib, const char* fileName, FT_Long face_index = 0);
	bool SetSize(FT_UInt charSize);
	bool Valid() const { return _hasValidFace; }
	void PreloadAllGlyphs();
	FT_OutlineGlyph GetOutlineGlyph(FT_ULong ch, FT_Pos* kern = nullptr, FT_UInt* glyphIndex = nullptr);
	FT_BitmapGlyph GetBitmapGlyph(FT_ULong ch, FT_Pos* kern = nullptr, FT_UInt* glyphIndex = nullptr);
	void SetPreviousChar(FT_ULong ch);
	void ResetKern();
	const auto& GetGlyphMap() const { return _glyphs; }
	const auto& GetBitmapMap() const { return _bitmaps; }
	~FTW_Face();

	explicit operator FT_Face() const { return _face; }
};
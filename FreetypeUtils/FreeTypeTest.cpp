#include <string>
#include <iostream>
#include <bitset>

#include "FreeTypeTest.h"

//******************* check error code ********************
void Check(FT_Error ErrCode, const char* OKMsg, const char* ErrMsg)
{
	if (ErrCode != 0)
	{
		std::cout << ErrMsg << ": " << ErrCode << "\n";
		std::cout << "program halted\n";
		exit(1);
	}
	else
		std::cout << OKMsg << "\n";
}

//******************** get outline ************************
int GetOutLine(FT_Glyph glyph, FT_OutlineGlyph* Outg)
{
	int Err = 0;

	switch (glyph->format)
	{
	case FT_GLYPH_FORMAT_BITMAP:
		Err = 1;
		break;

	case FT_GLYPH_FORMAT_OUTLINE:
		*Outg = (FT_OutlineGlyph)glyph;
		break;

	default:
		;
	}
	return Err;
}

//*********** print outline  to console ***************
int PrintOutLine(FT_OutlineGlyph Outg)
{
	int Err = 0;
	FT_Outline* Ol = &Outg->outline;
	int Start = 0;                   //start index of contour
	int End = 0;                     //end index of contour
	short* pContEnd = Ol->contours;  //pointer to contour end
	FT_Vector* pPoint = Ol->points;  //pointer to outline point
	char* pFlag = Ol->tags;          //pointer to flag

	for (int c = 0; c < Ol->n_contours; c++)
	{
		std::cout << "\nContour " << c << ":\n";
		End = *pContEnd++;
		for (int p = Start; p <= End; p++)
		{
			auto Ch = std::bitset<8>(*pFlag++);
			std::cout << "Point " << p << ": X=" << pPoint->x << " Y=" << pPoint->y << " Flag=" << Ch << "\n";
			pPoint++;
		}
		Start = End + 1;
	}

	return Err;
}

//*********** get glyph index from command line *************
FT_UInt GetGlyphIndex(int argc, char* argv[], int Nr)
{
	if (argc > Nr)
	{
		return atoi(argv[Nr]);
	}
	else
	{
		return 36;
	}
}

//*********** get font name from command line *************
void GetFontName(int argc, char* argv[], int Nr, std::string& FontName)
{
	if (argc > Nr)
	{
		FontName += argv[Nr];
	}
	else
	{
		FontName += "Calibri.ttf";
	}
}

//*********** get font size from command line *************
int GetFontSize(int argc, char* argv[], int Nr)
{
	short FontSize = 50 * 64;
	if (argc > Nr)
		FontSize += atoi(argv[Nr]);
	return FontSize;
}

//******************** M A I N ************************
// par1: FontName, par2:Glyph-Nr, par3: FontSize as FT_F26Dot6
int FreeTypeTest_main(int argc, char* argv[])
{
	FT_Face face;
	FT_Library    library;
	FT_Error error;

	error = FT_Init_FreeType(&library);
	Check(error, "", "error initializing FT lib");

	std::string FontName;
	FontName = "Assets/";
	GetFontName(argc, argv, 1, FontName);
	error = FT_New_Face(library, FontName.c_str(), 0, &face);
	Check(error, "", "error loading font");

	FT_F26Dot6 font_size = GetFontSize(argc, argv, 3);
	error = FT_Set_Char_Size(face, font_size, font_size, 72, 72);
	Check(error, "", "error setting char size");

	FT_UInt   glyph_index = GetGlyphIndex(argc, argv, 2);
	FT_Int32  load_flags = FT_LOAD_DEFAULT;
	error = FT_Load_Glyph(face, glyph_index, load_flags);
	Check(error, "", "error loading glyph");

	FT_Glyph glyph;
	error = FT_Get_Glyph(face->glyph, &glyph);
	Check(error, "", "error getting glyph");

	FT_OutlineGlyph Outg;
	error = GetOutLine(glyph, &Outg);
	Check(error, "", "error getting outline");

	std::cout << "=======================================================\n";
	std::cout << "Font: " << FontName << "\n";
	std::cout << "Glyph Index: " << glyph_index << "\n";
	std::cout << "=======================================================\n";
	error = PrintOutLine(Outg);
	Check(error, "", "error printing outline");

	return 0;
}
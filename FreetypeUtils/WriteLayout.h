#pragma once

#include "TextLayout.h"
#include "Outline.h"

#include <ostream>

void WriteLayoutAsText(std::ostream& os, const TextLayout& glyphs, const OutlineCache& oc, int pen_x, int pen_y);
void WriteLayoutBinary(std::ostream& os, const TextLayout& glyphs, const OutlineCache& oc, int pen_x, int pen_y);

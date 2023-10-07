#pragma once



#include "Falcor.h"

#include "Outline.h"
#include "TextLayout.h"
#include "FreetypeWrapper.h"

class OutlineBuffer {
public:
    std::vector<float> controlPoints;
    std::vector<int> contours;
    int contourNumber;
	void initBuffers(std::string text, float bw, float bh);
	
};

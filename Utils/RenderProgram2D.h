#pragma once
#include "RenderProgram.h"

class RenderProgram2D : public RenderProgram {

protected:

    enum SDF2d { circle, moon, star, horseshoe };
    uint sdf2d = SDF2d::circle;

    //gui
    Gui::RadioButtonGroup bg_sdf2d;

   
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    void setupGui() override;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) = 0;


public:
    void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) override;
    void renderGui(Gui::Window* w) = 0;
    
    
    RenderProgram2D();
};

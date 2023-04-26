#pragma once
#include "RenderProgram.h"

class RenderProgram2D : public RenderProgram {

private:

    enum SDF2d { circle, moon, star };
    uint sdf2d = SDF2d::circle;

    //gui
    Gui::RadioButtonGroup bg_sdf2d;

   
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) override;
    void setupGui() override;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) override;

    //debug
    float2 debugpos_2d;

public:
    void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) override;
    void renderGui(Gui::Window* w) override;
    void fileGui(Gui::Window* f);
    
    RenderProgram2D();
};

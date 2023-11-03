#pragma once
#include "RenderProgram.h"

#include "..\FreetypeUtils\OutlineBuffer.h"


class RenderProgram2D : public RenderProgram {

protected:

    enum SDF2d { circle, moon, star, horseshoe,font };
    uint sdf2d = SDF2d::circle;


    std::string ft = "x";
    //gui
    Gui::RadioButtonGroup bg_sdf2d;
    float dx, dy;


   
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    void setupGui() override;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) = 0;

    void generateFont(std::string text);

    OutlineBuffer ob;
    std::string fontf = "FreetypeUtils/Assets/wmanimals2.ttf";
    

public:
    void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) override;
    void renderGui(Gui::Window* w) = 0;
    
    
    RenderProgram2D();
};

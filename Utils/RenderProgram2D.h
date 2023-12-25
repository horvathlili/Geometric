#pragma once
#include "RenderProgram.h"

#include "..\FreetypeUtils\OutlineBuffer.h"


class RenderProgram2D : public RenderProgram {

protected:

    enum SDF2d { circle, moon, star, horseshoe,font };
    uint sdf2d = SDF2d::circle;

    int bit = 16;

    float fpmax;

    std::string ft = "x";
    //gui
    Gui::RadioButtonGroup bg_sdf2d;
    float dx, dy;

    ComputeProgramWrapper::SharedPtr testProgram;
    Texture::SharedPtr testTexture;
    int testres = 32;
    bool test = false;
    bool showtest = false;
    std::vector<float> seconderror;
    std::vector<float> firsterror;
    std::vector<float> inferror;
    std::vector<float> pixerror;
    float secondnorm = 0;
    float firstnorm = 0;
    float infnorm = 0;
    float pixnorm = 0;
    bool csgrun = false;

    void testing(RenderContext* pRenderContext);

   
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    void setupGui() override;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) = 0;

    void generateFont(std::string text);
   

    OutlineBuffer ob;
    std::string fontf = "FreetypeUtils/Assets/wmanimals2.ttf";

    Texture::SharedPtr msdf;
    Texture::SharedPtr osdf;
    

public:
    void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) override;
    void renderGui(Gui::Window* w) = 0;
    void testGui(Gui::Window* t);
    
    RenderProgram2D();
};

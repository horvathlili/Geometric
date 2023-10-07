#include "RenderProgram2D.h"

RenderProgram2D::RenderProgram2D() {

    Program::Desc d1;

    d1.addShaderLibrary("Samples/GeometricFields/Shaders/2d.vs.slang").entryPoint(ShaderType::Vertex, "main");
    d1.addShaderLibrary("Samples/GeometricFields/Shaders/2d.ps.slang").entryPoint(ShaderType::Pixel, "main");

    Program = GraphicsProgram::create(d1);
    FALCOR_ASSERT(Program);

    State = GraphicsState::create();
    State->setProgram(Program);
    FALCOR_ASSERT(State);

    Vars = GraphicsVars::create(State->getProgram().get());

    readProgram = ComputeProgramWrapper::create();
    readProgram->createProgram("Samples/GeometricFields/Shaders/Compute/read2d.cs.slang");


    bn = 1;
    dimension = 2;

    setupGui();
}

void RenderProgram2D::Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) {
    State->setFbo(pTargetFbo);

    if (retexture) {
        textures = generateTexture(pRenderContext);
        retexture = false;
        fileerror = false;
        texturedone = true;
    }

    if (read) {
        textures = readFromFile(pRenderContext);
        read = false;
        if (!fileerror)
            texturedone = true;
    }

    if (texturedone) {

        {
            Sampler::Desc desc;
            desc.setFilterMode(Sampler::Filter::Linear, Sampler::Filter::Linear, Sampler::Filter::Linear);
            mpSampler = Sampler::create(desc);
        }

        Vars["texture1"] = textures[0];
        Vars["texture2"] = textures[1];
        Vars["psCb"]["res"] = resolution;
        Vars["psCb"]["debug"] = debugging;
        Vars["psCb"]["dx"] = dx;
        Vars["psCb"]["dy"] = dy;
        Vars["psCb"]["boundingBox"] = boundingBox;
        Vars["mSampler"] = mpSampler;
        Program->addDefine("SDF", std::to_string(sdf2d));
        Program->addDefine("INTERP", std::to_string(interp));
        Program->addDefine("FIELD", std::to_string(field));
        State->setVao(pVao);
        pRenderContext->draw(State.get(), Vars.get(), 4, 0);
    }
}



void RenderProgram2D::setupGui() {


    Gui::RadioButton no;
    no.label = "no interpolation";
    no.buttonID = Interpolation::no;
    no.sameLine = false;
    Gui::RadioButton linear;
    linear.label = "trilinear";
    linear.sameLine = true;
    linear.buttonID = Interpolation::trilinear;
   
    bg_interp.push_back(no);
    bg_interp.push_back(linear);


    Gui::RadioButton circle;
    circle.label = "circle";
    circle.buttonID = SDF2d::circle;
    circle.sameLine = false;
    Gui::RadioButton moon;
    moon.label = "Moon";
    moon.buttonID = SDF2d::moon;
    moon.sameLine = true;
    Gui::RadioButton star;
    star.label = "Star";
    star.buttonID = SDF2d::star;
    star.sameLine = true;
    Gui::RadioButton horseshoe;
    horseshoe.label = "Horseshoe";
    horseshoe.buttonID = SDF2d::horseshoe;
    horseshoe.sameLine = true;
    Gui::RadioButton font;
    font.label = "Font";
    font.buttonID = SDF2d::font;
    font.sameLine = true;
    bg_sdf2d.push_back(circle);
    bg_sdf2d.push_back(moon);
    bg_sdf2d.push_back(star);
    bg_sdf2d.push_back(horseshoe);
    bg_sdf2d.push_back(font);
    RenderProgram::setupGui();

}

void RenderProgram2D::generateFont(std::string text) {
    
    
    ob.initBuffers(text,bw*20.f,bh*20.f);
    
    
    
}




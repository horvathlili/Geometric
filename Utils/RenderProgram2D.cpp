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

    testProgram = ComputeProgramWrapper::create();
    testProgram->createProgram("Samples/GeometricFields/testing2d.cs.slang");

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

    if (test && texturedone) {
        testing(pRenderContext);
        test = false;
    }
    else {
        test = false;
    }

    if (texturedone) {

        {
            Sampler::Desc desc;
            desc.setFilterMode(Sampler::Filter::Linear, Sampler::Filter::Linear, Sampler::Filter::Linear);
            mpSampler = Sampler::create(desc);
        }

      

        Vars["texture1"] = textures[0];
        Vars["texture2"] = textures[1];
        Vars["textureCSG"] = textures[2];
        Vars["msdftexture"] = msdf;
        Vars["psCb"]["res"] = resolution;
        Vars["psCb"]["bit"] = bit;
        Vars["psCb"]["fpmax"] = fpmax;
        Vars["psCb"]["debug"] = debugging;
        Vars["psCb"]["originalsdf"] = originalsdf;
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


void RenderProgram2D::testing(RenderContext* pRenderContext) {
    

    auto& comp = *testProgram;

    {
        Sampler::Desc desc;
        desc.setFilterMode(Sampler::Filter::Linear, Sampler::Filter::Linear, Sampler::Filter::Linear);
        mpSampler = Sampler::create(desc);
    }

    testres = 217;
    comp["csCb"]["testres"] = testres;
    comp["texture1"] = textures[0];
    comp["texture2"] = textures[1];
    comp["textureCSG"] = textures[2];
    comp["psCb"]["boundingBox"] = boundingBox;
    comp["psCb"]["res"] = resolution;
    comp["mSampler"] = mpSampler;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf2d));
    comp.getProgram()->addDefine("FIELD", std::to_string(field));
    comp.getProgram()->addDefine("INTERP", std::to_string(interp));
    comp.allocateStructuredBuffer("seconderrors", testres * testres);
    comp.allocateStructuredBuffer("firsterrors", testres * testres);
    comp.allocateStructuredBuffer("inferrors", testres * testres);
    comp.allocateStructuredBuffer("segments", (int)ob.contours.size(), ob.contours.data(), sizeof(int) * (int)ob.contours.size());
    comp.allocateStructuredBuffer("controlPoints", (int)ob.controlPoints.size(), ob.controlPoints.data(), sizeof(float) * (int)ob.controlPoints.size());
    std::vector<int> v; v.push_back(ob.contourNumber);
    comp.allocateStructuredBuffer("cn", 1, v.data(), sizeof(int));

    comp.runProgram(pRenderContext, testres, testres);

    //reading data from the gpu
    auto dataptr = comp.mapBuffer<const float>("seconderrors");
    seconderror.resize(testres * testres);
    seconderror.assign(dataptr, dataptr + testres * testres);
    comp.unmapBuffer("seconderrors");
    auto dataptrf = comp.mapBuffer<const float>("firsterrors");
    firsterror.resize(testres * testres);
    firsterror.assign(dataptrf, dataptrf + testres * testres);
    comp.unmapBuffer("firsterrors");
    auto dataptri = comp.mapBuffer<const float>("inferrors");
    inferror.resize(testres * testres);
    inferror.assign(dataptri, dataptri + testres * testres);
    comp.unmapBuffer("inferrors");

    secondnorm = 0;
    firstnorm = 0;
    infnorm = 0;

    for (int i = 0; i < testres * testres; i++) {

        secondnorm += seconderror[i];
        firstnorm += firsterror[i];

        if (inferror[i] > infnorm) {
            infnorm = inferror[i];
        }
    }

    secondnorm = sqrt(secondnorm);


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
    
    
    ob.initBuffers(text,fontf,bw*20.f,bh*20.f);
    
    
    
}


void RenderProgram2D::testGui(Gui::Window* t) {

    if (t->button("Run test")) {
        test = true;
    }
    t->slider("Test resolution", testres, 1, 512);
    t->text("second norm: " + std::to_string(secondnorm));
    t->text("first norm: " + std::to_string(firstnorm));
    t->text("inf norm: " + std::to_string(infnorm));


}

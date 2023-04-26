#include "RenderProgram2D.h"

RenderProgram2D::RenderProgram2D() {

    Program::Desc d1;

    d1.addShaderLibrary("Samples/GeometricFields/Shaders/g12d.vs.slang").entryPoint(ShaderType::Vertex, "main");
    d1.addShaderLibrary("Samples/GeometricFields/Shaders/g12d.ps.slang").entryPoint(ShaderType::Pixel, "main");

    Program = GraphicsProgram::create(d1);
    FALCOR_ASSERT(Program);

    State = GraphicsState::create();
    State->setProgram(Program);
    FALCOR_ASSERT(State);

    Vars = GraphicsVars::create(State->getProgram().get());

    ComputeProgram = ComputeProgramWrapper::create();
    ComputeProgram->createProgram("Samples/GeometricFields/Shaders/Compute/g12d.cs.slang");

    readProgram = ComputeProgramWrapper::create();
    readProgram->createProgram("Samples/GeometricFields/Shaders/Compute/read2d.cs.slang");


    bn = 1;

    setupGui();
}

void RenderProgram2D::Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) {
    State->setFbo(pTargetFbo);

    if (retexture) {
        textures = generateTexture(pRenderContext);
        retexture = false;
        texturedone = true;
    }

    if (read) {
        textures = readFromFile(pRenderContext);
        read = false;
        texturedone = true;
    }

    if (texturedone) {
        Vars["texture"] = textures[0];
        Vars["psCb"]["res"] = resolution;
        Vars["psCb"]["debugpos"] = debugpos_2d;
        Program->addDefine("SDF", std::to_string(sdf2d));
        Program->addDefine("INTERP", std::to_string(interp));
        State->setVao(pVao);
        pRenderContext->draw(State.get(), Vars.get(), 4, 0);
    }
}

void RenderProgram2D::renderGui(Gui::Window* w) {
    if (w->button("start")) {
        retexture = true;
        resolution = sliderRes;
    }
    w->radioButtons(bg_texsize, texturesize);
    w->separator();
    w->radioButtons(bg_sdf2d, sdf2d);
    w->slider("resolution", sliderRes, 10, 256);
    w->separator();
    w->radioButtons(bg_interp, interp);
    w->separator();
    if (w->button(debugging ? "debug on" : "debug off")) {
        debugging = !debugging;
    }
    if (debugging)
        w->slider("debug", debugpos_2d, -1.0f, 1.0f);
}


void RenderProgram2D::setupGui() {
    Gui::RadioButton circle;
    circle.label = "circle";
    circle.buttonID = SDF2d::circle;
    Gui::RadioButton moon;
    moon.label = "Moon";
    moon.buttonID = SDF2d::moon;
    Gui::RadioButton star;
    star.label = "Star";
    star.buttonID = SDF2d::star;
    bg_sdf2d.push_back(circle);
    bg_sdf2d.push_back(moon);
    bg_sdf2d.push_back(star);

    RenderProgram::setupGui();

}

std::vector<Texture::SharedPtr> RenderProgram2D::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex = nullptr;

    if (texturesize == 0) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }
    if (texturesize == 1) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }

    auto& comp = *ComputeProgram;

    comp["tex"].setUav(pTex->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp["csCb"]["boundingBox"] = boundingBox;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf2d));
    comp.allocateStructuredBuffer("data1", resolution * resolution);
    comp.allocateStructuredBuffer("posdata", resolution * resolution);

    comp.runProgram(pRenderContext, resolution, resolution);

    auto dataptr = comp.mapBuffer<const float4>("data1");
    data1.resize(resolution * resolution);
    data1.assign(dataptr, dataptr + resolution * resolution);
    comp.unmapBuffer("data1");
    dataptr = comp.mapBuffer<const float4>("posdata");
    posdata.resize(resolution * resolution);
    posdata.assign(dataptr, dataptr + resolution * resolution);
    comp.unmapBuffer("posdata");

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex);

    return textures;
}

std::vector<Texture::SharedPtr> RenderProgram2D::readFromFile(RenderContext* pRenderContext) {
    std::ifstream tfile(filename);

    int r;

    tfile >> r;
    resolution = r;
    sliderRes = r;

    data1.clear(); posdata.clear();

    for (int i = 0; i < r * r * r; i++) {
        float4 data;
        tfile >> data.x >> data.y >> data.z >> data.w;
        data1.push_back(data);
        tfile >> data.x >> data.y>>data.z;
        posdata.push_back(float4(data.xy, 0.f,0.f));
    }

    tfile.close();

    Texture::SharedPtr pTex = nullptr; 
   
    if (texturesize == 0) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }
    if (texturesize == 1) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }

    auto& comp = *readProgram;

    comp["tex"].setUav(pTex->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp.allocateStructuredBuffer("data1", r * r , data1.data(), sizeof(float4) * r * r );
    comp.allocateStructuredBuffer("posdata", r * r , posdata.data(), sizeof(float4) * r * r );

    comp.runProgram(pRenderContext, resolution, resolution);

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex);

    return textures;
}

void RenderProgram2D::fileGui(Gui::Window* f) {

    f->textbox("file name", filename);
    if (f->button("write to file")) {
        writeToFile();
    }
    if (f->button("read from file")) {
        read = true;
    }
}

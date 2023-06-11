#include "RenderProgram2DG1.h"

RenderProgram2DG1::RenderProgram2DG1() {

  

    ComputeProgram = ComputeProgramWrapper::create();
    ComputeProgram->createProgram("Samples/GeometricFields/Shaders/Compute/g12d.cs.slang");

    field = 1;

    bn = 2;

    Gui::RadioButton csg;
    csg.label = "csg";
    csg.buttonID = Interpolation::csg;
    csg.sameLine = true;
    bg_interp.push_back(csg);

}



void RenderProgram2DG1::renderGui(Gui::Window* w) {
    if (w->button("start")) {
        retexture = true;
        resolution = sliderRes;
        boundingBox = sliderboundingBox;
    }
    w->radioButtons(bg_texsize, texturesize);
    w->separator();
    w->radioButtons(bg_sdf2d, sdf2d);
    w->slider("resolution", sliderRes, 10, 256);
    w->slider("boundingBox", sliderboundingBox, 2.0f, 10.0f);
    w->separator();
    w->radioButtons(bg_interp, interp);
    w->separator();
    if (w->button(debugging ? "debug on" : "debug off")) {
        debugging = !debugging;
    }
   
}

std::vector<Texture::SharedPtr> RenderProgram2DG1::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex = nullptr;
    Texture::SharedPtr pTex2 = nullptr;

    if (texturesize == 0) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTex2 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }
    if (texturesize == 1) {
        pTex = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTex2 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }

    auto& comp = *ComputeProgram;

    comp["tex"].setUav(pTex->getUAV(0));
    comp["tex2"].setUav(pTex2->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp["csCb"]["boundingBox"] = boundingBox;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf2d));
    comp.allocateStructuredBuffer("data1", resolution * resolution);
    comp.allocateStructuredBuffer("data2", resolution * resolution);

    comp.allocateStructuredBuffer("posdata", resolution * resolution);

    comp.runProgram(pRenderContext, resolution, resolution);

    auto dataptr = comp.mapBuffer<const float4>("data1");
    data1.resize(resolution * resolution);
    data1.assign(dataptr, dataptr + resolution * resolution);
    comp.unmapBuffer("data1");
    dataptr = comp.mapBuffer<const float4>("data2");
    data2.resize(resolution * resolution);
    data2.assign(dataptr, dataptr + resolution * resolution);
    comp.unmapBuffer("data2");
    dataptr = comp.mapBuffer<const float4>("posdata");
    posdata.resize(resolution * resolution);
    posdata.assign(dataptr, dataptr + resolution * resolution);
    comp.unmapBuffer("posdata");

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex);
    textures.push_back(pTex2);

    return textures;
}

std::vector<Texture::SharedPtr> RenderProgram2DG1::readFromFile(RenderContext* pRenderContext) {
    fileerror = false;

    std::ifstream tfile(filename);

    if (tfile.fail()) {
        fileerror = true;
        msg = "No such file";
        return textures;
    }

    int r;
    float b;
    

    tfile >> r;
    tfile >> b;

    int d, f;
    tfile >> d;
    tfile >> f;

    if (d != dimension || f != field) {
        fileerror = true;
        msg = "Wrong dimension/order";
        tfile.close();
        return textures;
    }

    resolution = r;
    boundingBox = b;
    sliderRes = r;
    sliderboundingBox = b;

    data1.clear(); data2.clear(); posdata.clear();

    for (int i = 0; i < r * r * r; i++) {
        float4 data;
        tfile >> data.x >> data.y >> data.z >> data.w;
        data1.push_back(data);
        tfile >> data.x >> data.y >> data.z >> data.w;
        data2.push_back(data);
        tfile >> data.x >> data.y>>data.z;
        posdata.push_back(float4(data.xy, 0.f,0.f));
    }

    tfile.close();

    Texture::SharedPtr pTex1 = nullptr;
    Texture::SharedPtr pTex2 = nullptr;
   
    if (texturesize == 0) {
        pTex1 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTex2 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }
    if (texturesize == 1) {
        pTex1 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTex2 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }

    auto& comp = *readProgram;

    comp["tex1"].setUav(pTex1->getUAV(0));
    comp["tex2"].setUav(pTex2->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp.allocateStructuredBuffer("data1", r * r , data1.data(), sizeof(float4) * r * r );
    comp.allocateStructuredBuffer("data2", r * r, data2.data(), sizeof(float4) * r * r);
    comp.allocateStructuredBuffer("posdata", r * r , posdata.data(), sizeof(float4) * r * r );

    comp.runProgram(pRenderContext, resolution, resolution);

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex1);
    textures.push_back(pTex2);

    return textures;
}



#include "RenderProgram2DG1.h"

RenderProgram2DG1::RenderProgram2DG1() {

  

    ComputeProgram = ComputeProgramWrapper::create();
    ComputeProgram->createProgram("Samples/GeometricFields/Shaders/Compute/g12d.cs.slang");


    CSGProgram = ComputeProgramWrapper::create();
    CSGProgram->createProgram("Samples/GeometricFields/Shaders/Compute/csgprecalc.cs.slang");


    field = 1;

    bn = 2;

    Gui::RadioButton csg;
    csg.label = "csg";
    csg.buttonID = Interpolation::csg;
    csg.sameLine = true;
    bg_interp.push_back(csg);
    Gui::RadioButton csg3;
    csg3.label = "csg 3";
    csg3.buttonID = Interpolation::csg3;
    csg3.sameLine = true;
    bg_interp.push_back(csg3);

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
    if (sdf2d == SDF2d::font) {
        w->textbox("letter", ft);
        w->slider("offset w", bw, 0.f,1.f);
        w->slider("offset h", bh, 0.f,1.f);
        w->textbox("fontfile", fontf);
    }
    w->slider("resolution", sliderRes, 10, 256);
    w->slider("boundingBox", sliderboundingBox, 2.0f, 10.0f);
    w->separator();
    w->radioButtons(bg_interp, interp);
    w->separator();
    if (w->button(debugging ? "debug on" : "debug off")) {
        debugging = !debugging;

       
    }
    if (debugging) {
        w->slider("x", dx, 0.f, 1.f);
        w->slider("y", dy, 0.f, 1.f);
    }

    if (w->button(originalsdf ? "hide original" : "show original")) {
        originalsdf = !originalsdf;
    }
   
}

std::vector<Texture::SharedPtr> RenderProgram2DG1::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex = nullptr;
    Texture::SharedPtr pTex2 = nullptr;

    Texture::SharedPtr pTexCSG = nullptr;

    ResourceFormat format = ResourceFormat::RGBA16Float;

    if (texturesize == 1) {
        format = ResourceFormat::RGBA32Float;
    }

    pTex = Texture::create2D(resolution, resolution, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    pTex2 = Texture::create2D(resolution, resolution, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    pTexCSG = Texture::create2D(resolution-1, resolution-1, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    generateFont(ft);

    auto& comp = *ComputeProgram;

    comp["tex"].setUav(pTex->getUAV(0));
    comp["tex2"].setUav(pTex2->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp["csCb"]["boundingBox"] = boundingBox;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf2d));
    comp.allocateStructuredBuffer("data1", resolution * resolution);
    comp.allocateStructuredBuffer("data2", resolution * resolution);
    comp.allocateStructuredBuffer("segments", (int)ob.contours.size(), ob.contours.data(), sizeof(int) * (int)ob.contours.size());
    comp.allocateStructuredBuffer("controlPoints", (int)ob.controlPoints.size(), ob.controlPoints.data(), sizeof(float) * (int)ob.controlPoints.size());
    std::vector<int> v; v.push_back(ob.contourNumber);
    comp.allocateStructuredBuffer("cn", 1, v.data(), sizeof(int));

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

    //calculating csg trees

    auto& comp2 = *CSGProgram;

    comp2["texcsg"].setUav(pTexCSG->getUAV(0));
    comp2["texture2"] = textures[1];
    comp2["csCb"]["res"] = resolution;
    comp2["csCb"]["boundingBox"] = boundingBox;

    comp2.runProgram(pRenderContext, resolution-1, resolution-1);

    textures.push_back(pTexCSG);
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

    ResourceFormat format = ResourceFormat::RGBA16Float;

    if (texturesize == 1) {
        format = ResourceFormat::RGBA32Float;
    }

   

   
   
        pTex1 = Texture::create2D(resolution, resolution, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTex2 = Texture::create2D(resolution, resolution, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

   

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



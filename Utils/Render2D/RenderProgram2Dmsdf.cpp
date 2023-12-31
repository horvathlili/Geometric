#include "RenderProgram2Dmsdf.h"

RenderProgram2Dmsdf::RenderProgram2Dmsdf() {

     field = 3;

    bn = 1;


}



void RenderProgram2Dmsdf::renderGui(Gui::Window* w) {
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
        w->slider("offset w", bw, 0.f, 1.f);
        w->slider("offset h", bh, 0.f, 1.f);
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
    if (w->button(originalsdf ? "show original" : "hide original")) {
        originalsdf = !originalsdf;
    }

    // w->image("texture", msdf);
}




std::vector<Texture::SharedPtr> RenderProgram2Dmsdf::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex = nullptr;

    ResourceFormat format = ResourceFormat::RGBA16Float;

    if (texturesize == 1) {
        format = ResourceFormat::RGBA32Float;
    }

    pTex = Texture::create2D(resolution, resolution, format, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

   
    generateFont(ft);
    msdf = Texture::createFromFile("C:\\tdk\\Falcor\\Source\\Samples\\GeometricFields\\MSDF\\bold_R\\render16.tiff", true, true);
    osdf = Texture::createFromFile("C:\\tdk\\Falcor\\Source\\Samples\\GeometricFields\\MSDF\\bold_R\\renderexact.tiff", true, true);

    std::cout << "msdf" << std::endl;

    if (msdf == nullptr) {
        std::cout << "null" << std::endl;
    }

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex);
    textures.push_back(pTex);
    textures.push_back(pTex);


    return textures;
}

std::vector<Texture::SharedPtr> RenderProgram2Dmsdf::readFromFile(RenderContext* pRenderContext) {
    fileerror = false;

    std::ifstream tfile(filename);

    if (tfile.fail()) {
        fileerror = true;
        msg = "No such file";
        return textures;
    }

    int r;
    float b;
    int d, f;

    tfile >> r;
    tfile >> b;
    tfile >> d;
    tfile >> f;

    if (d != dimension || f != field) {
        fileerror = true;
        msg = "Wrong dimension/order";
        return textures;
    }

    resolution = r;
    boundingBox = b;
    sliderRes = r;
    sliderboundingBox = b;

    data1.clear();  posdata.clear();

    for (int i = 0; i < r * r; i++) {
        float4 data;
        tfile >> data.x >> data.y >> data.z >> data.w;
        data1.push_back(data);
        tfile >> data.x >> data.y >> data.z;
        posdata.push_back(float4(data.xy, 0.f, 0.f));
    }

    tfile.close();

    Texture::SharedPtr pTex1 = nullptr;

    if (texturesize == 0) {
        pTex1 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }
    if (texturesize == 1) {
        pTex1 = Texture::create2D(resolution, resolution, ResourceFormat::RGBA32Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    }

    auto& comp = *readProgram;

    comp["tex1"].setUav(pTex1->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp.allocateStructuredBuffer("data1", r * r, data1.data(), sizeof(float4) * r * r);
    comp.allocateStructuredBuffer("posdata", r * r, posdata.data(), sizeof(float4) * r * r);

    comp.runProgram(pRenderContext, resolution, resolution);

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTex1);
    textures.push_back(pTex1);

    return textures;
}

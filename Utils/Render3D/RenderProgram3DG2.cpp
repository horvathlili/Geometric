#include "RenderProgram3DG2.h"
#include <vector>
#include "../../Eigen/Dense"


RenderProgram3DG2::RenderProgram3DG2() {

    ComputeProgram = ComputeProgramWrapper::create();
    ComputeProgram->createProgram("Samples/GeometricFields/Shaders/Compute/g23d.cs.slang");

    bn = 3;
    field = 2;
}

void RenderProgram3DG2::renderGui(Gui::Window* w) {
    //generating field
    if (w->button("start")) {
        retexture = true;
        resolution = sliderRes;
        boundingBox = sliderboundingBox;
    }
    (w->radioButtons(bg_texsize, texturesize));

    w->slider("resolution", sliderRes, 1, 100);

    (w->slider("boundingBox", sliderboundingBox, 2.f, 20.f));
    w->separator();
    w->slider("finegird Size", finegridSize, 0.f, 1.5f);
    w->slider("finegird Res", finegridRes, 1, 10);
    w->separator();
    w->radioButtons(bg_sdf3d, sdf3d);
    w->separator();
    w->radioButtons(bg_interp, interp);
    w->separator();
    w->slider("a", a, 0.f, 90.f);
    w->slider("b", b, 0.f, 90.f);
    w->separator();
    //debugging
    if (w->button(debugging ? "debug on" : "debug off")) {
        debugging = !debugging;
    }
    if (debugging) {
        w->slider("position", debugpos_3d, -1.0f, 1.0f);
    }
   
   
  
   
}

std::vector<float> getPseudoInverse(float finegridsize, int finegridres) {

    float step = finegridsize / (float)finegridres / 2.0f;
    int number = finegridres * 2 + 1;

    Eigen::MatrixXf m(number * number * 3, 7);

    for (int i = -finegridres; i <= finegridres; i++) {
        for (int j = -finegridres; j <= finegridres; j++) {
            float2 p = float2(i, j) * step;

            //z
            m(((i + finegridres) * number + (j + finegridres)) * 3, 0) = 0.5f * p.x * p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 1) = p.x * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 2) = 0.5f * p.y * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 3) = p.x * p.x * p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 4) = p.x * p.x * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 5) = p.x * p.y * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3, 6) = p.y * p.y * p.y;

            //x of the normal (derivative according to x)
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 0) = p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 1) = p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 2) = 0;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 3) = 3.f * p.x * p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 4) = 2.f * p.x * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 5) = p.y * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 6) = 0;

            //y of the normal (derivative according to y)
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 0) = 0;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 1) = p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 2) = p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 3) = 0;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 4) = p.x * p.x;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 5) = 2.f * p.x * p.y;
            m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 6) = 3.f * p.y * p.y;
        }
    }



   


    Eigen::MatrixXf pseudoinverse = (m.transpose() * m).inverse() * m.transpose();

    std::vector<float> linearisedpi;

    for (int i = 0; i < 7; i++) {
        for (int j = 0; j < number * number * 3; j++) {
            linearisedpi.push_back(pseudoinverse(i, j));
        }
    }

    return linearisedpi;
}

std::vector<Texture::SharedPtr> RenderProgram3DG2::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTexfpr = nullptr; //footpoint and smaller cuvature
    Texture::SharedPtr pTexdR = nullptr;  //axis and bigger curvature
    Texture::SharedPtr pTexn = nullptr; 

    ResourceFormat format = ResourceFormat::RGBA16Float;

    if (texturesize == 1) {
        format = ResourceFormat::RGBA32Float;
    }

   
        pTexfpr = Texture::create3D(resolution, resolution, resolution, format, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexdR = Texture::create3D(resolution, resolution, resolution, format, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexn = Texture::create3D(resolution, resolution, resolution, format, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
   

    float finegridsize = boundingBox / (float)resolution * finegridSize;
    number = finegridRes * 2 + 1;

    std::vector<float> x0= getPseudoInverse(finegridsize, finegridRes);

    auto& comp = *ComputeProgram;

    comp["texfpr"].setUav(pTexfpr->getUAV(0));
    comp["texdR"].setUav(pTexdR->getUAV(0));
    comp["texn"].setUav(pTexn->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp["csCb"]["boundingBox"] = boundingBox;
    comp["csCb"]["finegridsize"] = finegridsize;
    comp["csCb"]["finegridres"] = finegridRes;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf3d));
    comp.getProgram()->addDefine("NUMBER", std::to_string(number));
    comp.allocateStructuredBuffer("x0", number * number *7 * 3 , x0.data(), sizeof(float) * number * number *7 * 3 );
    comp.allocateStructuredBuffer("data1", resolution * resolution * resolution);
    comp.allocateStructuredBuffer("data2", resolution * resolution * resolution);
    comp.allocateStructuredBuffer("data3", resolution * resolution * resolution);
    comp.allocateStructuredBuffer("posdata", resolution * resolution * resolution);


    comp.runProgram(pRenderContext, resolution, resolution, resolution);


    //reading data from the gpu
    auto dataptr = comp.mapBuffer<const float4>("data1");
    data1.resize(resolution * resolution * resolution);
    data1.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("data1");
    dataptr = comp.mapBuffer<const float4>("data2");
    data2.resize(resolution * resolution * resolution);
    data2.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("data2");
    dataptr = comp.mapBuffer<const float4>("data3");
    data3.resize(resolution * resolution * resolution);
    data3.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("data3");
    dataptr = comp.mapBuffer<const float4>("posdata");
    posdata.resize(resolution * resolution * resolution);
    posdata.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("posdata");

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTexfpr);
    textures.push_back(pTexdR);
    textures.push_back(pTexn);

    return textures;
}

std::vector<Texture::SharedPtr> RenderProgram3DG2::readFromFile(RenderContext* pRenderContext) {
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

    data1.clear(); data2.clear(); data3.clear();posdata.clear();

    for (int i = 0; i < r * r * r; i++) {
        float4 data;
        tfile >> data.x >> data.y >> data.z >> data.w;
        data1.push_back(data);
        tfile >> data.x >> data.y >> data.z >> data.w;
        data2.push_back(data);
        tfile >> data.x >> data.y >> data.z;
        data3.push_back(float4(data.xyz,0.f));
        tfile >> data.x >> data.y >> data.z;
        posdata.push_back(float4(data.xyz, 0.f));
    }

    tfile.close();

    Texture::SharedPtr pTexfpr = nullptr; //footpoint and smaller cuvature
    Texture::SharedPtr pTexdR = nullptr;  //axis and bigger curvature
    Texture::SharedPtr pTexn = nullptr;  //axis and bigger curvature

    if (texturesize == 0) {
        pTexfpr = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexdR = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexn = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }
    if (texturesize == 1) {
        pTexfpr = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA32Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexdR = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA32Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexn = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
    }

     auto& comp = *readProgram;

    comp.getProgram()->addDefine("FIELD", std::to_string(2));
    comp["texfpr"].setUav(pTexfpr->getUAV(0));
    comp["texdR"].setUav(pTexdR->getUAV(0));
    comp["texn"].setUav(pTexn->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp.allocateStructuredBuffer("data1", r*r*r, data1.data(), sizeof(float4) * r*r*r);
    comp.allocateStructuredBuffer("data2", r * r * r, data2.data(), sizeof(float4) * r * r * r);
    comp.allocateStructuredBuffer("data3", r * r * r, data3.data(), sizeof(float4) * r * r * r);
    comp.allocateStructuredBuffer("posdata", r * r * r, posdata.data(), sizeof(float4) * r * r * r);

    comp.runProgram(pRenderContext, resolution, resolution, resolution);

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTexfpr);
    textures.push_back(pTexdR);
    textures.push_back(pTexn);

    return textures;
}


void RenderProgram3DG2::csgFilter(RenderContext* pRenderContext) {
    
}



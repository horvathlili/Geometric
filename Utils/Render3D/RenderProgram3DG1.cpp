#include "RenderProgram3DG1.h"
#include <vector>
#include "../../Eigen/Dense"


RenderProgram3DG1::RenderProgram3DG1() {

    ComputeProgram = ComputeProgramWrapper::create();
    ComputeProgram->createProgram("Samples/GeometricFields/Shaders/Compute/g13d.cs.slang");

    csgProgram = ComputeProgramWrapper::create();
    csgProgram->createProgram("Samples/GeometricFields/Shaders/Compute/csg3d.cs.slang");


    bn = 2;
    field = 1;
}


void RenderProgram3DG1::renderGui(Gui::Window* w) {
    if (w->button("start")) {
        retexture = true;
        resolution = sliderRes;
        boundingBox = sliderboundingBox;
        std::cout << "3dg1" << std::endl;

    }
    (w->radioButtons(bg_texsize, texturesize));

    w->slider("resolution", sliderRes, 1, 100);
    w->slider("relaxed generating", relg, 0.f, 1.f);
    (w->slider("boundingBox", sliderboundingBox, 2.f, 20.f));
    w->separator();
    w->radioButtons(bg_sdf3d, sdf3d);
    w->slider("Sdf", sdf3d, (uint)1, (uint)7);
    w->separator();
    w->radioButtons(bg_interp, interp);
    w->slider("relaxed spheretrace", rels, 0.f, 1.f);

    if (w->button(debugging ? "debug on" : "debug off")) {
        debugging = !debugging;
    }
    if (debugging) {
        w->slider("position", debugpos_3d, -1.0f, 1.0f);
    }
    if (w->button("csg test")) {
     
        csgrun = true;
     
    }
   
   
}

std::vector<float> getPseudoInverse1(float boundingbox, int res) {

    Eigen::MatrixXf m(27, 4);

    std::vector<float> ret;

    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            for (int k = -1; k <= 1; k++) {

                float3 x = float3(i, j, k) * (float)boundingbox / (float)res * 0.6f;

                m((i + 1) * 9 + (j + 1) * 3 + (k + 1), 0) = x.x;
                m((i + 1) * 9 + (j + 1) * 3 + (k + 1), 1) = x.y;
                m((i + 1) * 9 + (j + 1) * 3 + (k + 1), 2) = x.z;
                m((i + 1) * 9 + (j + 1) * 3 + (k + 1), 3) = 1.0;

            }
        }
    }



    Eigen::MatrixXf result = (m.transpose() * m).inverse() * m.transpose();
    
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 27; j++) {
            ret.push_back(result(i, j));
        }
    }

    return ret;
}


std::vector<Texture::SharedPtr> RenderProgram3DG1::generateTexture(RenderContext* pRenderContext) {
    Texture::SharedPtr pTexfp = nullptr;
    Texture::SharedPtr pTexn = nullptr;

    Texture::SharedPtr pTexn2 = nullptr;

    pTexn2= Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);


    ResourceFormat format = ResourceFormat::RGBA16Float;

    if (texturesize == 1) {
        format = ResourceFormat::RGBA32Float;
    }

   
        pTexfp = Texture::create3D(resolution, resolution, resolution,format, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexn = Texture::create3D(resolution, resolution, resolution, format, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

   

    auto& comp = *ComputeProgram;

    std::vector<float> x0 = getPseudoInverse1(boundingBox, resolution);

    comp["texfp"].setUav(pTexfp->getUAV(0));
    comp["texn"].setUav(pTexn->getUAV(0));
    comp["texn2"].setUav(pTexn2->getUAV(0));
    comp["csCb"]["rel"] = relg;
    comp["csCb"]["res"] = resolution;
    comp["csCb"]["boundingBox"] = boundingBox;
    comp.allocateStructuredBuffer("x0", 108, x0.data(), sizeof(float) * 108);
    comp.getProgram()->addDefine("SDF", std::to_string(sdf3d));
    comp.allocateStructuredBuffer("data1", resolution * resolution * resolution);
    comp.allocateStructuredBuffer("data2", resolution * resolution * resolution);
   comp.allocateStructuredBuffer("posdata", resolution * resolution * resolution);


    comp.runProgram(pRenderContext, resolution, resolution, resolution);


    auto dataptr = comp.mapBuffer<const float4>("data1");
    data1.resize(resolution * resolution * resolution);
    data1.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("data1");
    dataptr = comp.mapBuffer<const float4>("data2");
    data2.resize(resolution * resolution * resolution);
    data2.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("data2");
    dataptr = comp.mapBuffer<const float4>("posdata");
    posdata.resize(resolution * resolution * resolution);
    posdata.assign(dataptr, dataptr + resolution * resolution * resolution);
    comp.unmapBuffer("posdata");

   /* for (int i = 0; i < resolution * resolution * resolution; i++) {
        if (posdata[i].z == 0)
            std::cout << data2[i].x << " " << data2[i].y << " " << data2[i].z << std::endl;
    }*/

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTexfp);
    textures.push_back(pTexn);
    textures.push_back(pTexn2);

    return textures;
}



std::vector<Texture::SharedPtr> RenderProgram3DG1::readFromFile(RenderContext* pRenderContext) {
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

    data1.clear(); data2.clear();  posdata.clear();

    for (int i = 0; i < r * r * r; i++) {
        float4 data;
        tfile >> data.x >> data.y >> data.z >> data.w;
        data1.push_back(data);
        tfile >> data.x >> data.y >> data.z >> data.w;
        data2.push_back(data);
        tfile >> data.x >> data.y >> data.z;
        posdata.push_back(float4(data.xyz, 0.f));
    }

    tfile.close();

    Texture::SharedPtr pTexfpr = nullptr; //footpoint and smaller cuvature
    Texture::SharedPtr pTexdR = nullptr;  //axis and bigger curvature
     if (texturesize == 0) {
        pTexfpr = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexdR = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA16Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
      }
    if (texturesize == 1) {
        pTexfpr = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA32Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
        pTexdR = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA32Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);
       }

    auto& comp = *readProgram;

    std::vector<float> x0 = getPseudoInverse1(boundingBox, resolution);

    comp.getProgram()->addDefine("FIELD", std::to_string(field));
    comp["texfp"].setUav(pTexfpr->getUAV(0));
    comp["texn"].setUav(pTexdR->getUAV(0));
    comp["csCb"]["res"] = resolution;
    comp.allocateStructuredBuffer("x0", 108, x0.data(), sizeof(float) * 108);
    comp.allocateStructuredBuffer("data1", r * r * r, data1.data(), sizeof(float4) * r * r * r);
    comp.allocateStructuredBuffer("data2", r * r * r, data2.data(), sizeof(float4) * r * r * r);
    comp.allocateStructuredBuffer("posdata", r * r * r, posdata.data(), sizeof(float4) * r * r * r);

    comp.runProgram(pRenderContext, resolution, resolution, resolution);

    std::vector<Texture::SharedPtr> textures;
    textures.push_back(pTexfpr);
    textures.push_back(pTexdR);
    textures.push_back(pTexdR);


    return textures;
}

void RenderProgram3DG1::csgFilter(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex = nullptr;


   
    pTex = Texture::create3D(resolution, resolution, resolution, ResourceFormat::RGBA32Float, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    auto& comp = *csgProgram;

    {
        Sampler::Desc desc;
        desc.setFilterMode(Sampler::Filter::Linear, Sampler::Filter::Linear, Sampler::Filter::Linear);
        mpSampler = Sampler::create(desc);
    }
    int rr = resolution - 1;
    comp["csCb"]["res"] = resolution-1;
    comp["texture1"] = textures[0];
    comp["texture2"] = textures[1];
    comp.allocateStructuredBuffer("csg", rr*rr*rr);
    comp.allocateStructuredBuffer("csg2", rr * rr * rr);
   
    comp.runProgram(pRenderContext, resolution-1, resolution-1,resolution-1);

    //reading data from the gpu
    auto dataptr = comp.mapBuffer<const float>("csg");
   
    csg.resize(rr * rr * rr);
    csg.assign(dataptr, dataptr + rr*rr*rr);
    comp.unmapBuffer("csg");

    auto dataptr2 = comp.mapBuffer<const float>("csg2");

    csg2.resize(rr * rr * rr);
    csg2.assign(dataptr2, dataptr2 + rr * rr * rr);
    comp.unmapBuffer("csg2");

    int db[13];
    int db2[13][10];

    for (int i = 0; i <= 12; i++) {
        db[i] = 0;
        for (int j = 0; j < 10; j++) {
            db2[i][j] = 0;
        }
    }

    for (int i = 0; i < rr * rr * rr; i++) {
   
            db[(int)csg[i]]++;
            db2[(int)csg[i]][(int)csg2[i]]++;
    }


    int csum = 0;
    for (int i = 0; i <= 12; i++) {
        std::cout << 12-i<<" metszet: "<<db[i] << std::endl;

        csum += db[i];

        if (i == 2 || i == 10) {
            std::cout << "      egymas mellett: " << db2[i][1] << std::endl;
            std::cout << "      kulon: " << db2[i][2] << std::endl;
        }
        if (i == 3 || i == 9) {
            std::cout << "      egy csucsbol: " << db2[i][1] << std::endl;
            std::cout << "      csikban: " << db2[i][2] << std::endl;
            std::cout << "      2 + 1: " << db2[i][3] << std::endl;
            std::cout << "      kulon: " << db2[i][4] << std::endl;
        }

        if (i == 4 || i == 8) {
            std::cout << "      egy csucsbol + 1 kulon: " << db2[i][1] << std::endl;
            std::cout << "      egy csucsbol +1: " << db2[i][2] << std::endl;
            std::cout << "      negyzet: " << db2[i][3] << std::endl;
            std::cout << "      csik: " << db2[i][4] << std::endl;
            std::cout << "      csik+1 vagy 2+2: " << db2[i][5] << std::endl;
            std::cout << "      2+1+1: " << db2[i][6] << std::endl;
            std::cout << "      kulon: " << db2[i][7] << std::endl;
        }
    }
  
    std::cout << csum<<std::endl;
}





#include "RenderProgram3D.h"


RenderProgram3D::RenderProgram3D() {

    setupGui();

    Program::Desc d1;

    d1.addShaderLibrary("Samples/GeometricFields/Shaders/3d.vs.slang").entryPoint(ShaderType::Vertex, "main");
    d1.addShaderLibrary("Samples/GeometricFields/Shaders/3d.ps.slang").entryPoint(ShaderType::Pixel, "main");

    Program = GraphicsProgram::create(d1);
    FALCOR_ASSERT(Program);

    State = GraphicsState::create();
    State->setProgram(Program);
    FALCOR_ASSERT(State);

    Vars = GraphicsVars::create(State->getProgram().get());

    dimension = 3;

    readProgram = ComputeProgramWrapper::create();
    readProgram->createProgram("Samples/GeometricFields/Shaders/Compute/read.cs.slang");

    testProgram = ComputeProgramWrapper::create();
    testProgram->createProgram("Samples/GeometricFields/Shaders/Compute/testing.cs.slang");
}

void RenderProgram3D::setupGui() {



    Gui::RadioButton no;
    no.label = "no interpolation";
    no.buttonID = Interpolation::no;
    no.sameLine = false;
    Gui::RadioButton linear;
    linear.label = "trilinear";
    linear.buttonID = Interpolation::trilinear;
    linear.sameLine = true;
    Gui::RadioButton csg;
    csg.label = "csg";
    csg.buttonID = Interpolation::csg;
    csg.sameLine = true;
    bg_interp.push_back(no);
    bg_interp.push_back(linear);
    bg_interp.push_back(csg);


    //sdf 3d
    Gui::RadioButton sphere;
    sphere.label = "Sphere";
    sphere.buttonID = SDF3d::sphere;
    sphere.sameLine = false;
    Gui::RadioButton torus;
    torus.label = "Torus";
    torus.buttonID = SDF3d::torus;
    torus.sameLine = true;
    Gui::RadioButton octa;
    octa.label = "Octahedron";
    octa.buttonID = SDF3d::octahedron;
    octa.sameLine = true;
    Gui::RadioButton head;
    head.label = "Head";
    head.buttonID = SDF3d::head;
    head.sameLine = true;
    Gui::RadioButton snail;
    snail.label = "Snail";
    snail.buttonID = SDF3d::snail;
    snail.sameLine = true;
   
    bg_sdf3d.push_back(sphere);
    bg_sdf3d.push_back(torus);
    bg_sdf3d.push_back(octa);
    bg_sdf3d.push_back(head);
    bg_sdf3d.push_back(snail);
 

    RenderProgram::setupGui();

}

void RenderProgram3D::setCamera(Camera::SharedPtr c, CameraController::SharedPtr cControl) {

    camera = c;
    cameraControl = cControl;

}

void RenderProgram3D::setCubeVao(Buffer::SharedPtr vbo, Vao::SharedPtr vao) {
    cubeVao = vao;
    cubeVbo = vbo;
}

void RenderProgram3D::testing(RenderContext* pRenderContext) {
    Texture::SharedPtr pTex= nullptr;
      
    pTex = Texture::create2D(testres,testres, ResourceFormat::RGBA16Float, 1, 1, nullptr, ResourceBindFlags::ShaderResource | ResourceBindFlags::UnorderedAccess);

    std::vector<float2> randoms;

    for (int i = 0; i < testres * testres;i++) {
        randoms.push_back( float2(rand() / (float)RAND_MAX, rand() / (float)RAND_MAX));
    }

    auto& comp = *testProgram;

    {
        Sampler::Desc desc;
        desc.setFilterMode(Sampler::Filter::Linear, Sampler::Filter::Linear, Sampler::Filter::Linear);
        mpSampler = Sampler::create(desc);
    }

//    testres = 217;
    comp["csCb"]["testres"] = testres;
   comp["texture1"] = textures[0];
   comp["texture2"] = textures[1];
   comp["texture3"] = textures[2];
   comp["psCb"]["eye"] = camera->getPosition();
   comp["psCb"]["center"] = camera->getTarget();
    comp["psCb"]["up"] = camera->getUpVector();
    comp["psCb"]["ar"] = camera->getAspectRatio();
    comp["psCb"]["box"] = isbox;
    comp["psCb"]["boundingBox"] = boundingBox;
    comp["psCb"]["viewproj"] = camera->getViewProjMatrix();
    comp["psCb"]["res"] = resolution;
    comp["mSampler"] = mpSampler;
    comp.getProgram()->addDefine("SDF", std::to_string(sdf3d));
    comp.getProgram()->addDefine("FIELD", std::to_string(field));
    comp.getProgram()->addDefine("INTERP", std::to_string(interp));
    comp.allocateStructuredBuffer("seconderrors", testres*testres);
    comp.allocateStructuredBuffer("firsterrors", testres * testres);
    comp.allocateStructuredBuffer("inferrors", testres * testres);
    comp.allocateStructuredBuffer("checkerrors", testres * testres);

    comp.runProgram(pRenderContext, testres,testres);

    //reading data from the gpu
    auto dataptr = comp.mapBuffer<const float>("seconderrors");
    seconderror.resize(testres*testres);
    seconderror.assign(dataptr, dataptr + testres*testres);
    comp.unmapBuffer("seconderrors");
    auto dataptrf = comp.mapBuffer<const float>("firsterrors");
    firsterror.resize(testres * testres);
    firsterror.assign(dataptrf, dataptrf + testres * testres);
    comp.unmapBuffer("firsterrors");
    auto dataptri = comp.mapBuffer<const float>("inferrors");
    inferror.resize(testres * testres);
    inferror.assign(dataptri, dataptri + testres * testres);
    comp.unmapBuffer("inferrors");
    auto dataptrc = comp.mapBuffer<const float>("checkerrors");
   checkerror.resize(testres * testres);
    checkerror.assign(dataptrc, dataptrc + testres * testres);
    comp.unmapBuffer("checkerrors");

    secondnorm = 0;
    firstnorm = 0;
    infnorm = 0;

    for (int i = 0; i < testres*testres; i++) {
       
        secondnorm += seconderror[i];
        firstnorm += firsterror[i];

        if (inferror[i] > infnorm) {
            infnorm = inferror[i];
        }

    }

    secondnorm = sqrt(secondnorm);

   
}

void RenderProgram3D::Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) {
    State->setFbo(pTargetFbo);
    isbox = isOutOfBox(camera->getPosition());

    if (retexture) {
        fileerror = false;
        textures = generateTexture(pRenderContext);
        retexture = false;
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

    if (csgrun) {
        std::cout << "3dg1" << std::endl;
        csgFilter(pRenderContext);
        csgrun = false;
    }

    if (texturedone) {

        float4x4 m = glm::scale(float4x4(1.0), float3(boundingBox - 0.5f * boundingBox / (float)resolution));
        Vars["vsCb"]["model"] = m;
        Vars["vsCb"]["viewproj"] = camera->getViewProjMatrix();
        Vars["vsCb"]["box"] = isbox;

        Vars["texture1"] = textures[0];
        Vars["texture2"] = textures[1];
        Vars["texture3"] = textures[2];
        Vars["testtexture"] = testTexture;
        Vars["psCb"]["eye"] = camera->getPosition();
        Vars["psCb"]["center"] = camera->getTarget();
        Vars["psCb"]["up"] = camera->getUpVector();
        Vars["psCb"]["ar"] = camera->getAspectRatio();
        Vars["psCb"]["box"] = isbox;
        Vars["psCb"]["boundingBox"] = boundingBox;
        Vars["psCb"]["viewproj"] = camera->getViewProjMatrix();
        Vars["psCb"]["res"] = resolution;
        Vars["psCb"]["debugpos"] = debugpos_3d;
        Vars["psCb"]["debugging"] = debugging;
        Vars["psCb"]["restest"] = testres;
        Vars["mSampler"] = mpSampler;
        Program->addDefine("SDF", std::to_string(sdf3d));
        Program->addDefine("INTERP", std::to_string(interp));
        Program->addDefine("FIELD", std::to_string(field));

        if (field == 2) {
            Vars["psCb"]["a"] = a;
            Vars["psCb"]["b"] = b;
        }

        if (isbox) {
            State->setVao(cubeVao);
            pRenderContext->draw(State.get(), Vars.get(), 36, 0);
        }
        else {
            State->setVao(pVao);
            pRenderContext->draw(State.get(), Vars.get(), 4, 0);
        }
    }
}



void RenderProgram3D::testGui(Gui::Window* t) {
  
    if (t->button("Run test")) {
        test = true;
    }
    t->slider("Test resolution", testres, 1, 512);
    t->text("second norm: " + std::to_string(secondnorm));
    t->text("first norm: " + std::to_string(firstnorm));
    t->text("inf norm: " + std::to_string(infnorm));


}

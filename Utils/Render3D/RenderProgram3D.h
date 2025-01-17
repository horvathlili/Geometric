#pragma once
#include "../RenderProgram.h"


class RenderProgram3D : public RenderProgram {

protected:

    enum SDF3d { sphere, torus, octahedron, head, snail,boat };
    uint sdf3d = SDF3d::sphere;

    //gui
    Gui::RadioButtonGroup bg_sdf3d;
   
   //box
    Buffer::SharedPtr cubeVbo;
    Vao::SharedPtr cubeVao;
    bool isbox = false;

    //camera
    Camera::SharedPtr camera;

    //debug
    float3 debugpos_3d;

    

    ComputeProgramWrapper::SharedPtr testProgram;
    Texture::SharedPtr testTexture;
    int testres = 32;
    bool test = false;
    bool showtest = false;
    std::vector<float> seconderror;
    std::vector<float> firsterror;
    std::vector<float> inferror;
    std::vector<float> checkerror;
    float secondnorm = 0;
    float firstnorm = 0;
    float infnorm = 0;
    bool csgrun = false;

    //methods
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    void setupGui() override;
    virtual std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext)= 0;
    void testing(RenderContext* pRenderContext);

    float a = 90;
    float b = 90;

    float relg = 1;
    float rels = 1;

    virtual void csgFilter(RenderContext* pRenderContext) = 0;


public:
    RenderProgram3D();

    void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo);

    void setCamera(Camera::SharedPtr camera, CameraController::SharedPtr cameraControl);
    CameraController::SharedPtr cameraControl;

    void setCubeVao(Buffer::SharedPtr vbo, Vao::SharedPtr vao);
    

 
 

    void testGui(Gui::Window* t);
    virtual void renderGui(Gui::Window* w) = 0;
};

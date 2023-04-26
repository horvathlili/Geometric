#pragma once
#include "../RenderProgram.h"


class RenderProgram3D : public RenderProgram {

protected:

    enum SDF3d { sphere, torus, octahedron, head };
    uint sdf3d = SDF3d::sphere;

    int field = 0;

    //gui
    Gui::RadioButtonGroup bg_sdf3d;
   
   std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    void setupGui() override;

    //box
    Buffer::SharedPtr cubeVbo;
    Vao::SharedPtr cubeVao;

    //camera
    Camera::SharedPtr camera;

    //debug
    float3 debugpos_3d;

   

    ComputeProgramWrapper::SharedPtr testProgram;
    Texture::SharedPtr testTexture;
    int testres = 32;
    bool test = false;
    bool showtest = false;
    std::vector<float> error;
    float avgerror = 0;
    float maxerror = 0;

    virtual std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) = 0;


public:
   void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo);

    void setCamera(Camera::SharedPtr camera, CameraController::SharedPtr cameraControl);
    CameraController::SharedPtr cameraControl;

    void setCubeVao(Buffer::SharedPtr vbo, Vao::SharedPtr vao);
    bool isbox = false;

    RenderProgram3D();

  
    Texture::SharedPtr testing(RenderContext* pRenderContext);

    void testGui(Gui::Window* t);
    void fileGui(Gui::Window* f);
    virtual void renderGui(Gui::Window* w) = 0;
};

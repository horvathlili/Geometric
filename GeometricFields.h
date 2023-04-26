#pragma once
#include "Falcor.h"
#include "Utils/ComputeProgramWrapper.h"
#include "Utils/RenderProgram2D.h"
#include "Utils/Render3D/RenderProgram3DG1.h"
#include "Utils/Render3D/RenderProgram3DG2.h"

using namespace Falcor;

class GeometricFields : public IRenderer
{
public:
    void onLoad(RenderContext* pRenderContext) override;
    void onFrameRender(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) override;
    void onShutdown() override;
    void onResizeSwapChain(uint32_t width, uint32_t height) override;
    bool onKeyEvent(const KeyboardEvent& keyEvent) override;
    bool onMouseEvent(const MouseEvent& mouseEvent) override;
    void onHotReload(HotReloadFlags reloaded) override;
    void onGuiRender(Gui* pGui) override;

private:


    //mező típusa
    enum Field { g12d, g22d, g13d, g23d };
    uint field = Field::g12d;

    //sdf
    enum SDF3d { sphere, torus, octahedron, head };
    enum SDF2d { circle, moon, star };
    uint sdf2d = SDF2d::circle;
    uint sdf3d = SDF3d::sphere;

    //interpolation mode
    enum Interpolation{no,trilinear,csg};
    uint interp = Interpolation::no;


    //program objects
    RenderProgram2D program2D;
    RenderProgram3DG1 program3DG1;
    RenderProgram3DG2 program3DG2;
   

    //data for drawing
    struct Vertex
    {
        float3 pos;
        float3 col;
    };
    void initData(); //initializing a square VAO
    Buffer::SharedPtr pVbo;
    Vao::SharedPtr pVao;  
    void initBox();  //initializing a box VAO
    bool isbox = false;
    Buffer::SharedPtr cubeVbo;
    Vao::SharedPtr cubeVao;
    void initCamera();
    Camera::SharedPtr camera;
    CameraController::SharedPtr cameraControl;
    //is camera out of the [-1,1]X[-1,1]X[-1,1] box
    bool isOutOfBox(float3 pos);


    //Gui
    void setUpGui();
    Gui::RadioButtonGroup bg_field;

    DebugConsole console;



  
};



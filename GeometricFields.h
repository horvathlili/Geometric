#pragma once
#include "Falcor.h"
#include "Utils/ComputeProgramWrapper.h"
#include "Utils/Render2D/RenderProgram2DG0.h"
#include "Utils/Render2D/RenderProgram2DG1.h"
#include "Utils/Render3D/RenderProgram3DG1.h"
#include "Utils/Render3D/RenderProgram3DG2.h"
#include "Utils/Render3D/RenderProgram3DG0.h"
#include "Utils/Render2D/RenderProgram2Dmsdf.h"

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
    enum Field { g02d, g12d, msdf2d, g03d, g13d, g23d };
    uint field = Field::g12d;


    //program objects
    RenderProgram2DG0 program2DG0;
    RenderProgram2DG1 program2DG1;
    RenderProgram2Dmsdf program2Dmsdf;
    RenderProgram3DG1 program3DG1;
    RenderProgram3DG2 program3DG2;
    RenderProgram3DG0 program3DG0;
   

    //data for drawing
    struct Vertex
    {
        float3 pos;
        float3 col;
    };
    void initPlane(); //initializing a square VAO
    Buffer::SharedPtr pVbo;
    Vao::SharedPtr pVao;  
    void initBox();  //initializing a box VAO
    bool isbox = false;
    Buffer::SharedPtr cubeVbo;
    Vao::SharedPtr cubeVao;
    void initCamera();
    Camera::SharedPtr camera;
    CameraController::SharedPtr cameraControl;

    //Gui
    void setUpGui();
    Gui::RadioButtonGroup bg_field;

    DebugConsole console;

   

  
};



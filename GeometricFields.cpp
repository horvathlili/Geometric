#include "GeometricFields.h"

#if FALCOR_D3D12_AVAILABLE
FALCOR_EXPORT_D3D12_AGILITY_SDK
#endif

uint32_t mSampleGuiWidth = 250;
uint32_t mSampleGuiHeight = 200;
uint32_t mSampleGuiPositionX = 20;
uint32_t mSampleGuiPositionY = 40;

void GeometricFields::setUpGui() { 
   
    Gui::RadioButton g23d;
    g23d.label = "G2 (3D)";
    g23d.buttonID = Field::g23d;
    g23d.sameLine = false;
    Gui::RadioButton g12d;
    g12d.label = "G1 (2D)";
    g12d.buttonID =Field::g12d;
    g12d.sameLine = true;
    Gui::RadioButton g13d;
    g13d.label = "G1 (3D)";
    g13d.buttonID = Field::g13d;
    g13d.sameLine = true;
    Gui::RadioButton g03d;
    g03d.label = "G0 (3D)";
    g03d.buttonID = Field::g03d;
    g03d.sameLine = true;
    Gui::RadioButton g02d;
    g02d.label = "G0 (2D)";
    g02d.buttonID = Field::g02d;
    g02d.sameLine = true;
    Gui::RadioButton msdf2d;
    msdf2d.label = "msdf (2D)";
    msdf2d.buttonID = Field::msdf2d;
    msdf2d.sameLine = true;
    bg_field.push_back(g23d);
    bg_field.push_back(g12d);
    bg_field.push_back(g13d);
    bg_field.push_back(g03d);
    bg_field.push_back(g02d);
    bg_field.push_back(msdf2d);
 
}

void GeometricFields::initPlane() {

    const Vertex vertices[] =
    {
        {float3(-1, -1, 0), float3(1, 0, 0)},
        {float3(1, -1, 0), float3(0, 1,0)},
        {float3(-1, 1, 0), float3(0, 0,1)},
        {float3(1, 1, 0), float3(0,0, 0)},
    };

    const uint32_t vbSize = (uint32_t)(sizeof(Vertex) * arraysize(vertices));

    pVbo = Buffer::create(vbSize, Buffer::BindFlags::Vertex, Buffer::CpuAccess::Write, (void*)vertices);
    FALCOR_ASSERT(pVbo);

    // Create VAO
    VertexLayout::SharedPtr pLayout = VertexLayout::create();
    VertexBufferLayout::SharedPtr pBufLayout = VertexBufferLayout::create();
    pBufLayout->addElement("POSITION", 0, ResourceFormat::RGB32Float, 1, 0);
    pBufLayout->addElement("COLOR", 12, ResourceFormat::RGB32Float, 1, 1);
    pLayout->addBufferLayout(0, pBufLayout);

    Vao::BufferVec buffers{ pVbo };
    pVao = Vao::create(Vao::Topology::TriangleStrip, pLayout, buffers);
    FALCOR_ASSERT(pVao);

    program2DG0.setVao(pVbo, pVao);
    program2Dmsdf.setVao(pVbo, pVao);
    program2DG1.setVao(pVbo, pVao);
    program3DG1.setVao(pVbo, pVao);
    program3DG2.setVao(pVbo, pVao);
    program3DG0.setVao(pVbo, pVao);
}

void GeometricFields::initBox() {
    std::vector<Vertex>vertices;

    //front									 
    vertices.push_back({ float3(-0.5, -0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, -0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, +0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, +0.5), float3(1,1,1) });
    //back
    vertices.push_back({ float3(+0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, +0.5, -0.5), float3(1,1,1) });
    //right									 
    vertices.push_back({ float3(+0.5, -0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, -0.5), float3(1,1,1) });
    //left									 
    vertices.push_back({ float3(-0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, -0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, +0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, +0.5, +0.5), float3(1,1,1) });
    //top									 
    vertices.push_back({ float3(-0.5, +0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, +0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, +0.5, -0.5), float3(1,1,1) });
    //bottom								 
    vertices.push_back({ float3(-0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, -0.5, -0.5), float3(1,1,1) });
    vertices.push_back({ float3(-0.5, -0.5, +0.5), float3(1,1,1) });
    vertices.push_back({ float3(+0.5, -0.5, +0.5), float3(1,1,1) });

    Vertex indices[36];
    int index = 0;
  
    for (int i = 0; i < 6 * 4; i += 4)
    {
        indices[index + 0] = vertices[i + 0];
        indices[index + 1] = vertices[i + 1];
        indices[index + 2] = vertices[i + 2];
        indices[index + 3] = vertices[i + 1];
        indices[index + 4] = vertices[i + 3];
        indices[index + 5] = vertices[i + 2];
        index += 6;
    }

    const uint32_t vbSize = (uint32_t)(sizeof(Vertex) * arraysize(indices));

    cubeVbo = Buffer::create(vbSize, Buffer::BindFlags::Vertex, Buffer::CpuAccess::Write, (void*)indices);
    FALCOR_ASSERT(cubeVbo);

    // Create VAO
    VertexLayout::SharedPtr pLayout = VertexLayout::create();
    VertexBufferLayout::SharedPtr pBufLayout = VertexBufferLayout::create();
    pBufLayout->addElement("POSITION", 0, ResourceFormat::RGB32Float, 1, 0);
    pBufLayout->addElement("COLOR", 12, ResourceFormat::RGB32Float, 1, 1);
    pLayout->addBufferLayout(0, pBufLayout);

    Vao::BufferVec buffers{ cubeVbo };
    cubeVao = Vao::create(Vao::Topology::TriangleList, pLayout, buffers);
    FALCOR_ASSERT(cubeVao);

    program3DG1.setCubeVao(cubeVbo, cubeVao);
    program3DG2.setCubeVao(cubeVbo, cubeVao);
    program3DG0.setCubeVao(cubeVbo, cubeVao);
}
void GeometricFields::initCamera() {

    camera = Camera::create();
    camera->setPosition(float3(0.75, 0.75, -0.75));
    camera->setTarget(float3(0, 0, 0));
    camera->setUpVector(float3(0, 1, 0));
    camera->setAspectRatio(1280.0f / 720.0f);
    camera->setNearPlane(0.01f);
    camera->setFarPlane(1000.0f);
    camera->beginFrame();

    cameraControl = FirstPersonCameraController::create(camera);
    cameraControl->setCameraSpeed(1.0f);

    program3DG1.setCamera(camera, cameraControl);
    program3DG2.setCamera(camera, cameraControl);
    program3DG0.setCamera(camera, cameraControl);
}

void GeometricFields::onGuiRender(Gui* pGui)
{
    Gui::Window w(pGui, "Field", { 500, 360 }, { 10, 10 });
   
    w.radioButtons(bg_field, field);

    if (field == Field::g02d) {
        program2DG0.renderGui(&w);
    }
    if (field == Field::g12d) {
        program2DG1.renderGui(&w);
    }
    if (field == Field::msdf2d) {
        program2Dmsdf.renderGui(&w);
    }
    if (field == Field::g13d) {
        program3DG1.renderGui(&w);    
    } 
     if (field == Field::g23d) {
      program3DG2.renderGui(&w);
     
    }
     if (field == Field::g03d) {
         program3DG0.renderGui(&w);

     }

  Gui::Window t(pGui, "Test", { 350, 150 }, { 700, 10 });
  if (field == Field::g02d) {
      program2DG0.testGui(&w);
  }
  if (field == Field::g12d) {
      program2DG1.testGui(&w);
  }
 
  if (field == Field::g13d) {
      program3DG1.testGui(&w);
  }
  if (field == Field::g23d) {
      program3DG2.testGui(&w);
  }
  if (field == Field::g03d) {
      program3DG0.testGui(&w);
  }
  if (field == Field::msdf2d) {
      program2Dmsdf.testGui(&w);
  }

  Gui::Window f(pGui, "File", { 350, 150 }, { 700, 170 });
  if (field == Field::g02d) {
      program2DG0.fileGui(&w);
  }
  if (field == Field::g12d) {
      program2DG1.fileGui(&w);
  }
  if (field == Field::g13d) {
      program3DG1.fileGui(&w);
  }
  if (field == Field::g23d) {
      program3DG2.fileGui(&w);
  }
  if (field == Field::g03d) {
      program3DG0.fileGui(&w);
  }

}


void GeometricFields::onLoad(RenderContext* pRenderContext)
{
    setUpGui();

    //init Vao-s and camera
    initPlane(); initBox();
   
    initCamera();
   
   

    //WriteLayoutAsText(std::cout, textGlyphs, oc, 0, 0);

    

}



void GeometricFields::onFrameRender(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo)
{
    const float4 clearColor(1.f, 1.f, 1.f, 1);
    pRenderContext->clearFbo(pTargetFbo.get(), clearColor, 1.0f, 0, FboAttachmentType::All);
  

    program3DG1.cameraControl->update();
    //program3DG2.cameraControl->update();
    
    
    if (field == Field::g02d) {
        program2DG0.Render(pRenderContext, pTargetFbo);
    }
    if (field == Field::g12d) {
        program2DG1.Render(pRenderContext, pTargetFbo);
    }
    if (field == Field::msdf2d) {
        program2Dmsdf.Render(pRenderContext, pTargetFbo);
    }
    if (field == Field::g13d) {
        program3DG1.Render(pRenderContext, pTargetFbo);
    }
    if (field == Field::g23d) {
        program3DG2.Render(pRenderContext, pTargetFbo);
    }
    if (field == Field::g03d) {
        program3DG0.Render(pRenderContext, pTargetFbo);
    }
}






void GeometricFields::onShutdown()
{
}

bool GeometricFields::onKeyEvent(const KeyboardEvent& keyEvent)
{
    return cameraControl->onKeyEvent(keyEvent);
}

bool GeometricFields::onMouseEvent(const MouseEvent& mouseEvent)
{
    return cameraControl->onMouseEvent(mouseEvent);
}

void GeometricFields::onHotReload(HotReloadFlags reloaded)
{
}

void GeometricFields::onResizeSwapChain(uint32_t width, uint32_t height)
{
    camera->setAspectRatio((float)width / (float)height);
}

int WINAPI WinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPSTR lpCmdLine, _In_ int nShowCmd)
{
    GeometricFields::UniquePtr pRenderer = std::make_unique<GeometricFields>();
    SampleConfig config;
    config.windowDesc.title = "Falcor Project Template";
    config.windowDesc.resizableWindow = true;
    config.windowDesc.width = 1280;
    config.windowDesc.height = 720;
    Sample::run(config, pRenderer);
    return 0;
}

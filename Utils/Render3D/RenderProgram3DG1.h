#pragma once
#include "RenderProgram3D.h"

class RenderProgram3DG1 : public RenderProgram3D {

private:

    ComputeProgramWrapper::SharedPtr csgProgram;
    Texture::SharedPtr csgTexture;

    std::vector<float> csg;
    std::vector<float> csg2;
  
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) override;
    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) override;

    void csgFilter(RenderContext* pRenderContext) override;

public:
     void renderGui(Gui::Window* w) override;
     
    
    RenderProgram3DG1();
};

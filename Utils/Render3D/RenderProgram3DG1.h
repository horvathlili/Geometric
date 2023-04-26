#pragma once
#include "RenderProgram3D.h"

class RenderProgram3DG1 : public RenderProgram3D {

private:
  
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) override;
    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) override;

public:
     void renderGui(Gui::Window* w) override;
     
    
    RenderProgram3DG1();
};

#pragma once
#include "RenderProgram3D.h"


class RenderProgram3DG2 : public RenderProgram3D {

private:
  
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) override;

    float finegridSize = 0.1f;
    int finegridRes = 3;

    int number = finegridRes * 2 + 1;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) override;

    void csgFilter(RenderContext* pRenderContext) override;
  
public:
    void renderGui(Gui::Window* w) override;

    
    RenderProgram3DG2();
};

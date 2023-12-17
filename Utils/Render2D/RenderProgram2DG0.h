#pragma once
#include "../RenderProgram2D.h"

class RenderProgram2DG0 : public RenderProgram2D {

private:
   

   
    std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) override;

    std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) override;

   

public:
   
    void renderGui(Gui::Window* w) override;
   
    RenderProgram2DG0();
};

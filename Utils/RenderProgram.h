#pragma once
#include "ComputeProgramWrapper.h"


class RenderProgram {

protected:

    enum Interpolation { no, trilinear, csg, csg3 };
    uint interp = Interpolation::no;


    //plane
    struct Vertex
    {
        float3 pos;
        float3 col;
    };
    Buffer::SharedPtr pVbo;
    Vao::SharedPtr pVao;

    //gui 
    Gui::RadioButtonGroup bg_texsize;
    Gui::RadioButtonGroup bg_interp;

    //program
    GraphicsProgram::SharedPtr Program;
    GraphicsVars::SharedPtr Vars;
    GraphicsState::SharedPtr State;
    ComputeProgramWrapper::SharedPtr ComputeProgram;

    //generate texture
    bool retexture = false;
    //is any texture generated
    bool texturedone = false;

    //basic details of the distance field
    int resolution = 32;
    int sliderRes = 32;
    float boundingBox = 2.f;
    float sliderboundingBox = 2.f;
    uint texturesize = 0;

    //textures of the field
    std::vector<Texture::SharedPtr> textures;
    Sampler::SharedPtr mpSampler;

    //debug
    bool debugging = false;

    bool isOutOfBox(float3 pos);

    //reading data from the gpu
    std::vector<float4> data1;
    std::vector<float4> data2;
    std::vector<float4> data3;
    std::vector<float4> posdata;

    //number of the used buffers
    int bn = 0;
    //dimension of the field
    int dimension = 0;
    //order of the field
    int field = 0;

    //filename for writing
    std::string filename = "file.txt";

    //reading from file
    bool read = false;
    ComputeProgramWrapper::SharedPtr readProgram;
    bool fileerror = false;
    std::string msg = "";
   

    //methods
    virtual std::vector<Texture::SharedPtr> generateTexture(RenderContext* pRenderContext) = 0;
    virtual void setupGui() = 0;
    virtual std::vector<Texture::SharedPtr> readFromFile(RenderContext* pRenderContext) = 0;
    void writeToFile();

public:
    virtual void Render(RenderContext* pRenderContext, const Fbo::SharedPtr& pTargetFbo) = 0;
    virtual void renderGui(Gui::Window* w) = 0;
    void fileGui(Gui::Window* f);

    void setVao(Buffer::SharedPtr vbo, Vao::SharedPtr vao); 
};

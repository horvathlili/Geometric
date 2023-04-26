#include "RenderProgram.h"

void RenderProgram::setVao(Buffer::SharedPtr vbo, Vao::SharedPtr vao) {
    pVbo = vbo;
    pVao = vao;
}

void RenderProgram::setupGui() {

    Gui::RadioButton tex16;
    tex16.label = "16 bit";
    tex16.buttonID = 0;
    Gui::RadioButton tex32;
    tex32.label = "32 bit";
    tex32.buttonID = 1;
    bg_texsize.push_back(tex16);
    bg_texsize.push_back(tex32);

    Gui::RadioButton no;
    no.label = "no interpolation";
    no.buttonID = Interpolation::no;
    Gui::RadioButton linear;
    linear.label = "trilinear";
    linear.buttonID = Interpolation::trilinear;
    Gui::RadioButton csg;
    csg.label = "csg";
    csg.buttonID = Interpolation::csg;
    bg_interp.push_back(no);
    bg_interp.push_back(linear);
    bg_interp.push_back(csg);
}

bool RenderProgram::isOutOfBox(float3 pos)
{
    float b = boundingBox - 0.5f * boundingBox / (float)resolution;
    bool r = (pos.x > -b / 2.0 && pos.x < b / 2.0 &&
        pos.y > -b / 2.0 && pos.y < b / 2.0 &&
        pos.z > -b / 2.0 && pos.z < b / 2.0);

    return !r;
}

void RenderProgram::writeToFile() {
    std::ofstream tfile = std::ofstream(filename);
    tfile << resolution << std::endl;

    int end = resolution * resolution;
    if (bn > 1)
        end *= resolution;

    for (int i = 0; i < end; i++) {
        tfile << data1[i].x << " " << data1[i].y << " " << data1[i].z << " " << data1[i].w << std::endl;
        if (bn > 1)
            tfile << data2[i].x << " " << data2[i].y << " " << data2[i].z << " " << data2[i].w << std::endl;
        if (bn > 2)
            tfile << data3[i].x << " " << data3[i].y << " " << data3[i].z << std::endl;
        tfile << posdata[i].x << " " << posdata[i].y << " " << posdata[i].z << std::endl;
    }

    tfile.close();
}



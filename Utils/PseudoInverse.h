#pragma once
#include "Falcor.h"
#include <vector>
#include "../Eigen/Dense"

using namespace Falcor;

std::vector<float> getPseudoInverse(float finegridsize, int finegridres) {

    float step = finegridsize / (float)finegridres / 2.0f;
    int number = finegridres * 2 + 1;

    Eigen::MatrixXf m(number*number*3, 7);

    for (int i = -finegridres; i <= finegridres; i++) {
        for (int j = -finegridres; j <= finegridres; j++) {
                float2 p = float2(i, j) * step;

                std::cout << p.x << " " << p.y  << std::endl;

                //z
                m(((i + finegridres) * number + (j + finegridres)) * 3, 0) = 0.5f*p.x*p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 1) = p.x * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 2) = 0.5f * p.y * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 3) = p.x * p.x * p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 4) = p.x * p.x * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 5) = p.x * p.y * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3, 6) = p.y * p.y * p.y;

                //x of the normal (derivative according to x)
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 0) = p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 1) = p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 2) = 0;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 3) = 3.f * p.x * p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 4) = 2.f * p.x * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 5) = p.y * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 1, 6) = 0;

                //y of the normal (derivative according to y)
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 0) = 0;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 1) = p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 2) = p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 3) = 0;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 4) = p.x * p.x;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 5) = 2.f * p.x * p.y;
                m(((i + finegridres) * number + (j + finegridres)) * 3 + 2, 6) = 3.f * p.y * p.y;
        }
    }

   

   

   
    Eigen::MatrixXf pseudoinverse = (m.transpose() * m).inverse() * m.transpose();
    
    std::vector<float> linearisedpi;

    for (int i = 0; i < 7; i++) {
        for (int j = 0; j < number*number*3; j++) {
            linearisedpi.push_back(pseudoinverse(i, j));
        }
    }

    return linearisedpi;
}
